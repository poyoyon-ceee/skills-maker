import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { SourceParser } from '../scripts/lib/parser.js';
import { ProjectWriter } from '../scripts/lib/writer.js';
import { buildFilePlan, templateNameFor } from '../scripts/lib/plan.js';
import { StagingSession } from '../scripts/lib/staging.js';
import { prepareVariables } from '../scripts/lib/vars.js';
import { makeTempDir, rmTempDir } from './helpers.js';

const scripts = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'scripts');

test('docs-only Hidem-off commit writes README.md and nothing else', () => {
    const dest = makeTempDir();
    const session = new StagingSession(dest);
    try {
        const parser = new SourceParser(path.join(scripts, 'FILE_TEMPLATE_SOURCE.md'));
        const options = { distribution: 'docs-only', hidemProfile: false, aiMaintained: false };
        const plan = buildFilePlan(options);
        const vars = {
            APP_NAME: 'Demo',
            APP_DESCRIPTION: 'A demo',
            STATUS_LINE: 'Greenfield scaffold. Implementation has not started.',
            FEATURES_LINE: 'Scaffold only.',
            SETUP_INSTRUCTIONS: 'No runtime install. Read README.md.',
            CONNECTIVITY_RULES_ONE_LINE: 'None.',
            PROJECT_EXTRA_CONSTRAINTS: 'None.',
            DOCS_HUB_LINE: '',
            AGENTS_LINE: '',
            HIDEM_LINKS: '',
        };
        for (const raw of plan) {
            const section = parser.getSection(templateNameFor(raw, options.distribution));
            session.writeFile(raw, ProjectWriter.replacePlaceholders(section.content, vars));
        }
        session.commit();
        assert.equal(fs.readFileSync(path.join(dest, 'README.md'), 'utf-8').includes('# Demo'), true);
        assert.equal(fs.existsSync(path.join(dest, 'PROJECT.md')), false);
        assert.equal(fs.existsSync(path.join(dest, 'docs', 'index.md')), false);
        assert.equal(/\{{2}[A-Z0-9_]+\}{2}/.test(fs.readFileSync(path.join(dest, 'README.md'), 'utf-8')), false);
    } finally {
        session.cleanup();
        rmTempDir(dest);
    }
});

test('Web Hidem-off commit includes README and docs/index, not PROJECT.md', () => {
    const dest = makeTempDir();
    const session = new StagingSession(dest);
    try {
        const parser = new SourceParser(path.join(scripts, 'FILE_TEMPLATE_SOURCE.md'));
        const project = {
            name: 'Demo',
            description: 'A demo',
            author: 'Hide',
            distribution: 'Web',
            connectivity: 'Offline',
            modules: [],
            gitPattern: 'A',
            aiMaintained: false,
            hidemProfile: false,
        };
        const rawPlan = buildFilePlan(project);
        let vars = prepareVariables(project, []);
        const planned = rawPlan.map((p) => ProjectWriter.replacePlaceholders(p, vars));
        vars = prepareVariables(project, planned);
        for (let i = 0; i < rawPlan.length; i++) {
            const section = parser.getSection(templateNameFor(rawPlan[i], project.distribution));
            session.writeFile(planned[i], ProjectWriter.replacePlaceholders(section.content, vars));
        }
        session.commit();
        assert.equal(fs.existsSync(path.join(dest, 'README.md')), true);
        assert.equal(fs.existsSync(path.join(dest, 'docs', 'index.md')), true);
        assert.equal(fs.existsSync(path.join(dest, 'PROJECT.md')), false);
        JSON.parse(fs.readFileSync(path.join(dest, 'package.json'), 'utf-8'));
    } finally {
        session.cleanup();
        rmTempDir(dest);
    }
});
