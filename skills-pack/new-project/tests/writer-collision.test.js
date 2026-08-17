import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { ProjectWriter, CollisionError } from '../scripts/lib/writer.js';
import { makeTempDir, rmTempDir } from './helpers.js';

test('writeFile refuses to overwrite an existing file and leaves it unchanged', () => {
    const dir = makeTempDir();
    try {
        const existing = path.join(dir, 'README.md');
        fs.writeFileSync(existing, 'user-owned\n', 'utf-8');
        const writer = new ProjectWriter(dir);
        assert.throws(
            () => writer.writeFile('README.md', 'scaffold\n'),
            (err) => err instanceof CollisionError
        );
        assert.equal(fs.readFileSync(existing, 'utf-8'), 'user-owned\n');
    } finally {
        rmTempDir(dir);
    }
});

test('writeFile creates a new file when the path is free', () => {
    const dir = makeTempDir();
    try {
        const writer = new ProjectWriter(dir);
        writer.writeFile('README.md', '# App\n');
        assert.equal(fs.readFileSync(path.join(dir, 'README.md'), 'utf-8'), '# App\n');
    } finally {
        rmTempDir(dir);
    }
});
