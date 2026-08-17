import fs from 'fs';
import path from 'path';

export class CollisionError extends Error {
    constructor(filePath) {
        super(`Refusing to overwrite existing file: ${filePath}`);
        this.name = 'CollisionError';
        this.path = filePath;
    }
}

export class PathEscapeError extends Error {
    constructor(filePath) {
        super(`Refusing to write outside destination: ${filePath}`);
        this.name = 'PathEscapeError';
        this.path = filePath;
    }
}

function destPrefix(absDir) {
    return absDir.endsWith(path.sep) ? absDir : absDir + path.sep;
}

/**
 * Resolve relativePath inside destDir. Rejects absolute paths, `..` escape,
 * and symlink/junction escape through an existing path component.
 */
export function resolveInsideDest(destDir, relativePath) {
    if (relativePath == null || String(relativePath).trim() === '') {
        throw new PathEscapeError(String(relativePath));
    }
    const rel = String(relativePath);
    if (path.isAbsolute(rel) || rel.includes('\0')) {
        throw new PathEscapeError(rel);
    }

    const destAbs = path.resolve(destDir);
    const resolved = path.resolve(destAbs, rel);
    const prefix = destPrefix(destAbs);
    if (resolved !== destAbs && !resolved.startsWith(prefix)) {
        throw new PathEscapeError(rel);
    }

    let destReal = destAbs;
    if (fs.existsSync(destAbs)) {
        destReal = fs.realpathSync(destAbs);
    }
    const destRealPrefix = destPrefix(destReal);

    let probe = resolved;
    while (probe && probe !== path.parse(probe).root) {
        if (probe === destAbs || probe === destReal) break;
        if (fs.existsSync(probe)) {
            const real = fs.realpathSync(probe);
            if (real !== destReal && !real.startsWith(destRealPrefix) && real !== destAbs && !real.startsWith(prefix)) {
                throw new PathEscapeError(rel);
            }
        }
        const parent = path.dirname(probe);
        if (parent === probe) break;
        probe = parent;
    }

    return resolved;
}

export function findExistingCollision(destDir, relativePath) {
    const resolved = resolveInsideDest(destDir, relativePath);
    const parent = path.dirname(resolved);
    const base = path.basename(resolved);
    if (!fs.existsSync(parent)) return null;
    const entries = fs.readdirSync(parent);
    const hit = entries.find((name) => name.toLowerCase() === base.toLowerCase());
    return hit ? path.join(parent, hit) : null;
}

export function findCollisions(destDir, relativePaths) {
    const hits = [];
    for (const rel of relativePaths) {
        const collision = findExistingCollision(destDir, rel);
        if (collision) hits.push({ planned: rel, existing: collision });
    }
    return hits;
}
