import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

test('portable SKILL.md does not hardcode vendor skill paths', () => {
    const text = fs.readFileSync(path.join(root, 'SKILL.md'), 'utf-8');
    assert.equal(text.includes('.claude/skills/new-project'), false);
    assert.equal(text.includes('.cursor/skills/new-project'), false);
    assert.equal(text.includes('.codex/skills/new-project'), false);
});

test('scaffold.js does not claim a simulated npm install completed', () => {
    const text = fs.readFileSync(path.join(root, 'scripts', 'scaffold.js'), 'utf-8');
    assert.equal(text.includes('シミュレーション'), false);
    assert.equal(text.includes('インストール完了'), false);
});

test('reference.md treats skills-pack as the canonical source', () => {
    const text = fs.readFileSync(path.join(root, 'reference.md'), 'utf-8');
    assert.match(text, /skills-pack/);
    assert.equal(/正本: `original-source-maker`/.test(text), false);
});
