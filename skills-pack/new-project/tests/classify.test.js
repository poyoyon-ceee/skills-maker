import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { classifyProject } from '../../project-foundation/scripts/classify-project.js';
import { makeTempDir, rmTempDir } from './helpers.js';

test('empty directory is classified as new', () => {
    const dir = makeTempDir();
    try {
        assert.equal(classifyProject(dir), 'new');
    } finally {
        rmTempDir(dir);
    }
});

test('README, code, or manifest means existing', () => {
    const dir = makeTempDir();
    try {
        fs.writeFileSync(path.join(dir, 'README.md'), '# x\n');
        fs.writeFileSync(path.join(dir, 'package.json'), '{}');
        fs.mkdirSync(path.join(dir, 'src'));
        fs.writeFileSync(path.join(dir, 'src', 'index.js'), 'export {}\n');
        assert.equal(classifyProject(dir), 'existing');
    } finally {
        rmTempDir(dir);
    }
});

test('only unrelated files is ambiguous', () => {
    const dir = makeTempDir();
    try {
        fs.writeFileSync(path.join(dir, 'notes.txt'), 'hello\n');
        assert.equal(classifyProject(dir), 'ambiguous');
    } finally {
        rmTempDir(dir);
    }
});

test('git init with no commits and no project files is new', () => {
    const dir = makeTempDir();
    try {
        execFileSync('git', ['init'], { cwd: dir, stdio: 'ignore' });
        assert.equal(classifyProject(dir), 'new');
    } finally {
        rmTempDir(dir);
    }
});
