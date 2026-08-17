import crypto from 'crypto';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { CollisionError, ProjectWriter } from './writer.js';
import { findCollisions, resolveInsideDest } from './paths.js';

export class StagingError extends Error {
    constructor(problems) {
        super(Array.isArray(problems) ? problems.join('\n') : String(problems));
        this.name = 'StagingError';
        this.problems = Array.isArray(problems) ? problems : [String(problems)];
    }
}

function sha256(buf) {
    return crypto.createHash('sha256').update(buf).digest('hex');
}

export class StagingSession {
    constructor(destDir) {
        this.destDir = path.resolve(destDir);
        this.tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'np-stage-'));
        this.writer = new ProjectWriter(this.tempDir);
        this.files = [];
        this.journal = [];
    }

    writeFile(relPath, content) {
        resolveInsideDest(this.destDir, relPath);
        this.writer.writeFile(relPath, content);
        this.files.push({ relPath, content });
    }

    validate() {
        const problems = [];
        const names = this.files.map((f) => f.relPath.replace(/\\/g, '/'));

        for (const { relPath, content } of this.files) {
            if (/\{\{[A-Z0-9_]+\}\}/.test(content)) {
                problems.push(`placeholder leftover in ${relPath}`);
            }
            if (relPath.endsWith('.json')) {
                try {
                    JSON.parse(content);
                } catch (err) {
                    problems.push(`invalid JSON ${relPath}: ${err.message}`);
                }
            }
            if (relPath.endsWith('.md')) {
                const links = content.matchAll(/\[[^\]]*\]\(([^)]+)\)/g);
                for (const match of links) {
                    const href = match[1].split('#')[0].split('?')[0].trim();
                    if (!href || /^(https?:|mailto:|\/\/)/i.test(href)) continue;
                    const target = path.posix.normalize(
                        path.posix.join(path.posix.dirname(relPath.replace(/\\/g, '/')), href)
                    );
                    const inStage = names.includes(target) || names.includes(target.replace(/^\.\//, ''));
                    const onDisk = fs.existsSync(path.join(this.tempDir, target));
                    if (!inStage && !onDisk) {
                        problems.push(`broken link in ${relPath}: ${href}`);
                    }
                }
            }
        }

        if (!names.includes('README.md')) problems.push('missing README.md');
        const otherDocs = names.filter((n) => n.startsWith('docs/') && n !== 'docs/index.md');
        if (otherDocs.length > 0 && !names.includes('docs/index.md')) {
            problems.push('missing docs/index.md');
        }

        if (problems.length) throw new StagingError(problems);
    }

    commit() {
        this.validate();
        const rels = this.files.map((f) => f.relPath);
        const collisions = findCollisions(this.destDir, rels);
        if (collisions.length) {
            throw new CollisionError(collisions.map((c) => c.planned).join(', '));
        }

        try {
            for (const { relPath, content } of this.files) {
                const fullPath = resolveInsideDest(this.destDir, relPath);
                const missingDirs = [];
                let dir = path.dirname(fullPath);
                while (
                    dir &&
                    (dir === this.destDir || dir.startsWith(this.destDir + path.sep)) &&
                    !fs.existsSync(dir)
                ) {
                    missingDirs.push(dir);
                    const parent = path.dirname(dir);
                    if (parent === dir) break;
                    dir = parent;
                }
                const destWriter = new ProjectWriter(this.destDir);
                destWriter.writeFile(relPath, content);
                for (const created of missingDirs.reverse()) {
                    this.journal.push({ type: 'dir', fullPath: created });
                }
                const buf = fs.readFileSync(fullPath);
                const st = fs.statSync(fullPath);
                this.journal.push({
                    type: 'file',
                    fullPath,
                    hash: sha256(buf),
                    size: st.size,
                    mtimeMs: st.mtimeMs,
                });
            }
        } catch (err) {
            err.leftover = this.rollback();
            throw err;
        }
    }

    rollback() {
        const leftover = [];
        for (const entry of this.journal.slice().reverse()) {
            if (entry.type === 'file') {
                if (!fs.existsSync(entry.fullPath)) continue;
                const buf = fs.readFileSync(entry.fullPath);
                const st = fs.statSync(entry.fullPath);
                if (sha256(buf) === entry.hash && st.size === entry.size) {
                    fs.unlinkSync(entry.fullPath);
                } else {
                    leftover.push(entry.fullPath);
                }
            } else if (entry.type === 'dir') {
                try {
                    if (fs.existsSync(entry.fullPath) && fs.readdirSync(entry.fullPath).length === 0) {
                        fs.rmdirSync(entry.fullPath);
                    }
                } catch {
                    leftover.push(entry.fullPath);
                }
            }
        }
        this.journal = [];
        return leftover;
    }

    cleanup() {
        fs.rmSync(this.tempDir, { recursive: true, force: true });
    }
}
