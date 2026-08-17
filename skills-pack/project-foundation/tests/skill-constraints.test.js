import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const skillDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const skill = fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf-8');

test('project-foundation description is trigger-only and does not summarize workflow', () => {
    const match = skill.match(/^description:\s*>-\s*\n((?:  .*\n)+)/m) || skill.match(/^description:\s*(.+)$/m);
    assert.ok(match, 'missing description');
    const desc = match[1];
    assert.equal(/then follow new-project/i.test(desc), false);
    assert.equal(/二段階/.test(desc), false);
});

test('classifier script prints new, existing, or ambiguous', () => {
    const src = fs.readFileSync(path.join(skillDir, 'scripts', 'classify-project.js'), 'utf-8');
    assert.ok(src.includes("'new'"));
    assert.ok(src.includes("'existing'"));
    assert.ok(src.includes("'ambiguous'"));
});
