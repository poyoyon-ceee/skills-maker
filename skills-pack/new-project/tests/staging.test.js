import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { StagingSession, StagingError } from '../scripts/lib/staging.js';
import { CollisionError } from '../scripts/lib/writer.js';
import { makeTempDir, rmTempDir } from './helpers.js';

test('placeholder leftover fails validation before dest is touched', () => {
    const dest = makeTempDir();
    const session = new StagingSession(dest);
    try {
        session.writeFile('README.md', '# {{APP_NAME}}\n');
        assert.throws(() => session.validate(), (err) => err instanceof StagingError);
        assert.equal(fs.existsSync(path.join(dest, 'README.md')), false);
    } finally {
        session.cleanup();
        rmTempDir(dest);
    }
});

test('commit stops with zero dest writes when any planned path collides', () => {
    const dest = makeTempDir();
    const session = new StagingSession(dest);
    try {
        fs.writeFileSync(path.join(dest, 'README.md'), 'mine\n', 'utf-8');
        session.writeFile('README.md', '# App\n');
        session.writeFile('AGENTS.md', '# Agents\n');
        assert.throws(() => session.commit(), (err) => err instanceof CollisionError);
        assert.equal(fs.readFileSync(path.join(dest, 'README.md'), 'utf-8'), 'mine\n');
        assert.equal(fs.existsSync(path.join(dest, 'AGENTS.md')), false);
    } finally {
        session.cleanup();
        rmTempDir(dest);
    }
});

test('rollback removes only unchanged journal files and reports edited leftovers', () => {
    const dest = makeTempDir();
    const session = new StagingSession(dest);
    try {
        session.writeFile('README.md', '# App\n');
        session.writeFile('notes.md', 'keep me\n');
        session.commit();
        fs.writeFileSync(path.join(dest, 'notes.md'), 'third party\n', 'utf-8');
        const leftover = session.rollback();
        assert.equal(fs.existsSync(path.join(dest, 'README.md')), false);
        assert.equal(fs.readFileSync(path.join(dest, 'notes.md'), 'utf-8'), 'third party\n');
        assert.ok(leftover.some((p) => p.endsWith('notes.md')));
    } finally {
        session.cleanup();
        rmTempDir(dest);
    }
});
