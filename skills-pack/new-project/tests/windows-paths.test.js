import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';
import { ProjectWriter, CollisionError, PathEscapeError } from '../scripts/lib/writer.js';
import { makeTempDir, rmTempDir } from './helpers.js';

test('writeFile treats a case-only difference as a collision', () => {
    const dir = makeTempDir();
    try {
        fs.writeFileSync(path.join(dir, 'readme.md'), 'mine\n', 'utf-8');
        const writer = new ProjectWriter(dir);
        assert.throws(
            () => writer.writeFile('README.md', 'scaffold\n'),
            (err) => err instanceof CollisionError
        );
        assert.equal(fs.readFileSync(path.join(dir, 'readme.md'), 'utf-8'), 'mine\n');
    } finally {
        rmTempDir(dir);
    }
});

test('writeFile rejects a junction that escapes dest', { skip: process.platform !== 'win32' }, () => {
    const dest = makeTempDir('np-jdest-');
    const outside = makeTempDir('np-jout-');
    const link = path.join(dest, 'escape');
    try {
        const made = spawnSync('cmd', ['/c', 'mklink', '/J', link, outside], { encoding: 'utf-8' });
        if (made.status !== 0) {
            assert.ok(false, `mklink failed: ${made.stderr || made.stdout}`);
        }
        const writer = new ProjectWriter(dest);
        assert.throws(
            () => writer.writeFile(path.join('escape', 'pwned.md'), 'nope\n'),
            (err) => err instanceof PathEscapeError
        );
        assert.equal(fs.existsSync(path.join(outside, 'pwned.md')), false);
    } finally {
        spawnSync('cmd', ['/c', 'rmdir', link], { encoding: 'utf-8' });
        rmTempDir(dest);
        rmTempDir(outside);
    }
});
