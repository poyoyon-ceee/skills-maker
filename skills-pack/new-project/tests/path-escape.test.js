import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { ProjectWriter, PathEscapeError } from '../scripts/lib/writer.js';
import { makeTempDir, rmTempDir } from './helpers.js';

test('writeFile rejects parent-directory traversal', () => {
    const dir = makeTempDir();
    const escapedName = `np-escaped-${process.pid}-${Date.now()}.md`;
    const escapedPath = path.join(dir, '..', escapedName);
    try {
        const writer = new ProjectWriter(dir);
        assert.throws(
            () => writer.writeFile(`../${escapedName}`, 'nope\n'),
            (err) => err instanceof PathEscapeError
        );
        assert.equal(fs.existsSync(escapedPath), false);
    } finally {
        fs.rmSync(escapedPath, { force: true });
        rmTempDir(dir);
    }
});

test('writeFile rejects an absolute path outside dest', () => {
    const dir = makeTempDir();
    const outside = path.join(path.parse(dir).root, 'skills-maker-escape-probe.md');
    try {
        const writer = new ProjectWriter(dir);
        assert.throws(
            () => writer.writeFile(outside, 'nope\n'),
            (err) => err instanceof PathEscapeError
        );
        assert.equal(fs.existsSync(outside), false);
    } finally {
        rmTempDir(dir);
        fs.rmSync(outside, { force: true });
    }
});
