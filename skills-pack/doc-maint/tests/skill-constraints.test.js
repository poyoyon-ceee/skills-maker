import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const skillDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const skill = fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf-8');
const checklist = fs.readFileSync(path.join(skillDir, 'references', 'audit-checklist.md'), 'utf-8');

test('doc-maint does not force a branch named dev', () => {
    assert.equal(/Work on `dev`/.test(skill), false);
    assert.equal(/Confirm work is on `dev`/.test(checklist), false);
    assert.equal(/Never perform this work on `main`/.test(skill), false);
});

test('user-facing audit categories are the five labels', () => {
    for (const label of ['維持', '統合', '修正', '移動', '要確認']) {
        assert.ok(skill.includes(label), `missing ${label}`);
    }
});

test('audit is read-only until the user approves apply', () => {
    assert.ok(skill.includes('読み取り専用') || /read-only/i.test(skill));
    assert.ok(skill.includes('承認'));
});
