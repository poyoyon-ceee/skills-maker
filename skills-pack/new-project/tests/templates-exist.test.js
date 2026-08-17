import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'path';
import { fileURLToPath } from 'url';
import { SourceParser } from '../scripts/lib/parser.js';
import { buildFilePlan, templateNameFor } from '../scripts/lib/plan.js';

const scripts = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'scripts');
const parser = new SourceParser(path.join(scripts, 'FILE_TEMPLATE_SOURCE.md'));
const protocol = new SourceParser(path.join(scripts, 'MASTER_PROTOCOL_SOURCE.md'));

function assertTemplatesExist(options) {
    const plan = buildFilePlan(options);
    for (const raw of plan) {
        const name = templateNameFor(raw, options.distribution);
        const section = parser.getSection(name) ||
            (raw === '.project_rules/MASTER_PROTOCOL.md'
                ? protocol.getSection('MASTER_PROTOCOL.md 本文')
                : null);
        assert.ok(section, `missing template for ${raw} (${name})`);
    }
}

test('docs-only Hidem-off templates exist', () => {
    assertTemplatesExist({ distribution: 'docs-only', hidemProfile: false, aiMaintained: false });
});

test('Web Hidem-on templates exist including README and docs index', () => {
    assertTemplatesExist({
        distribution: 'Web',
        hidemProfile: true,
        aiMaintained: true,
        modules: ['EventBus'],
    });
    assert.ok(parser.getSection('README.md'));
    assert.ok(parser.getSection('docs/index.md'));
    assert.ok(parser.getSection('AGENTS.md'));
});
