#!/usr/bin/env node
// Tests the drift check by breaking things on purpose.
//
// A checker that reports "no drift" is indistinguishable from a checker that
// has quietly stopped looking, which is the same silent-failure problem it was
// written to solve one level up. So every finding kind gets a case here that
// proves it still fires, and the clean case proves it stays quiet.
//
// Two suites:
//
//   synthetic  a small Swift file and contract written just for the test, so
//              the walker's paths — enums, dictionaries, optionals, nesting —
//              can all be exercised, including the ones no real endpoint
//              happens to reach today.
//   real       a payload generated from the real Swift sources and the real
//              contract. Proves the two still agree, and that a removed field
//              in a real document is still caught.
//
// No network: payloads are synthesised from the schema and read with --offline.

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, cpSync } from 'node:fs';
import { join, dirname, resolve as resolvePath } from 'node:path';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { extractSchemas, resolve } from './parity-schema.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolvePath(HERE, '..', '..');
const CHECKER = join(HERE, 'check-parity-drift.mjs');

let failures = 0;
let passes = 0;

function check(name, condition, detail) {
    if (condition) {
        passes += 1;
        console.log(`  ok    ${name}`);
    } else {
        failures += 1;
        console.log(`  FAIL  ${name}`);
        if (detail) console.log(`        ${detail}`);
    }
}

// Runs the checker over a fixture directory and returns its JSON report.
function run(fixtureDir, { sourceDir, contract, failOn = 'break' }) {
    const reportPath = join(fixtureDir, '_report.json');
    let status = 0;
    try {
        execFileSync(process.execPath, [
            CHECKER,
            '--offline', fixtureDir,
            '--json', reportPath,
            '--fail-on', failOn,
            '--source-dir', sourceDir,
            '--contract', contract
        ], { stdio: 'pipe' });
    } catch (error) {
        status = error.status ?? 1;
    }
    return { status, report: JSON.parse(readFileSync(reportPath, 'utf8')) };
}

const kinds = (report) => report.findings.map((f) => f.kind);
const find = (report, kind, path) =>
    report.findings.find((f) => f.kind === kind && (path === undefined || f.schemaPath === path));

// ---------------------------------------------------------------------------
// Generating a payload that satisfies a derived schema
// ---------------------------------------------------------------------------

// Fills every required field with a value of the right type, so the clean case
// is known-good by construction rather than by having been fetched on a day the
// site happened to agree.
function synthesise(type, types, scope, depth = 0) {
    if (depth > 12) return null;
    if (type.kind === 'optional') return synthesise(type.of, types, scope, depth + 1);
    if (type.kind === 'array') return [synthesise(type.of, types, scope, depth + 1)];
    if (type.kind === 'dictionary') return { key: synthesise(type.value, types, scope, depth + 1) };

    const resolved = resolve(type, types, scope);
    if (!resolved) return null;

    switch (resolved.kind) {
        case 'primitive':
            if (resolved.json === 'string') return 'x';
            if (resolved.json === 'integer') return 1;
            if (resolved.json === 'number') return 1.5;
            if (resolved.json === 'boolean') return true;
            return null;
        case 'stringEnum':
            return resolved.values[0];
        case 'object': {
            const entry = types.get(resolved.name);
            if (!entry) return {};
            const object = {};
            for (const field of entry.fields) {
                if (field.type.kind === 'optional') continue; // absent is legal
                object[field.key] = synthesise(field.type, types, resolved.name, depth + 1);
            }
            return object;
        }
        default:
            return null;
    }
}

// A nav page whose links are generated from the route table the check will
// compare them against, so the clean case is clean by construction. For the
// synthetic contract that is the three fixture routes; for the real one it is
// whatever BudgetLiveParityView currently lists, which also proves the
// extraction round-trips against real source.
function navFixture(contract, sourceDir) {
    const nav = contract.navigation;
    const base = nav.basePath ?? '';
    const swift = readFileSync(join(sourceDir, nav.swift), 'utf8');
    const routes = [...new Set([...swift.matchAll(/path:\s*"([^"]+)"/g)].map((m) => m[1]))];
    const links = [...(nav.ignore ?? []), ...routes]
        .map((r) => `<a href="${base}${r}">${r}</a>`)
        .join('');
    return `<!doctype html><nav>${links}</nav>`;
}

function buildFixture(contract, types, sourceDir) {
    const dir = mkdtempSync(join(tmpdir(), 'parity-fixture-'));
    for (const endpoint of contract.endpoints) {
        const payload = synthesise({ kind: 'named', name: endpoint.document }, types, null);
        writeFileSync(join(dir, `${endpoint.id}.json`), JSON.stringify(payload, null, 1));
    }
    // Closed sets must hold on the synthetic payload too, or every run reports
    // drift that has nothing to do with the case under test.
    for (const set of contract.closedSets) {
        const file = join(dir, `${set.endpoint}.json`);
        const payload = JSON.parse(readFileSync(file, 'utf8'));
        applyClosedSet(payload, set);
        writeFileSync(file, JSON.stringify(payload, null, 1));
    }
    for (const mirror of contract.markupMirrors) {
        writeFileSync(
            join(dir, `${mirror.id}.html`),
            `<!doctype html><main>${mirror.phrases.map((p) => `<p>${p}</p>`).join('')}</main>`
        );
    }
    if (contract.navigation) writeFileSync(join(dir, 'navigation.html'), navFixture(contract, sourceDir));
    return dir;
}

// Writes every handled value of a closed set into the synthetic payload, not
// just the first. Using one value would leave the others looking retired and
// fire `closed-set-unused` on an otherwise clean fixture — and a test that has
// to ignore a finding to pass can no longer tell you that finding is quiet when
// it should be.
function applyClosedSet(payload, set) {
    const segments = set.jsonPath.split('.');
    const leaf = segments.pop();
    const wanted = set.handled.length;

    let nodes = [payload];
    for (const segment of segments) {
        const isArray = segment.endsWith('[]');
        const key = isArray ? segment.slice(0, -2) : segment;
        nodes = nodes.flatMap((node) => {
            const value = node?.[key];
            if (value === undefined || value === null) return [];
            if (!isArray) return [value];
            if (!Array.isArray(value) || value.length === 0) return [];
            // Grow the array so there is room for one of each handled value.
            while (value.length < wanted) value.push(structuredClone(value[0]));
            return value;
        });
    }

    const leafIsArray = leaf.endsWith('[]');
    const key = leafIsArray ? leaf.slice(0, -2) : leaf;
    let next = 0;
    for (const node of nodes) {
        if (!node || typeof node !== 'object') continue;
        if (set.mode === 'requiredMapKeys') {
            const template = Object.values(node[key] ?? {})[0] ?? {};
            node[key] = Object.fromEntries(set.handled.map((k) => [k, structuredClone(template)]));
        } else if (leafIsArray && Array.isArray(node[key])) {
            while (node[key].length < wanted) node[key].push(node[key][0]);
            node[key] = node[key].map(() => set.handled[next++ % wanted]);
        } else {
            node[key] = set.handled[next++ % wanted];
        }
    }
}

// Mutates a copy of a fixture and returns the new directory.
function mutate(source, mutator) {
    const dir = mkdtempSync(join(tmpdir(), 'parity-case-'));
    cpSync(source, dir, { recursive: true });
    mutator(dir, {
        read: (name) => JSON.parse(readFileSync(join(dir, name), 'utf8')),
        write: (name, value) => writeFileSync(join(dir, name), JSON.stringify(value)),
        readText: (name) => readFileSync(join(dir, name), 'utf8'),
        writeText: (name, text) => writeFileSync(join(dir, name), text)
    });
    return dir;
}

// ---------------------------------------------------------------------------
// Suite 1: synthetic Swift + contract, so every path gets exercised
// ---------------------------------------------------------------------------

const SYNTHETIC_SWIFT = `import Foundation

enum WidgetKind: String, Decodable, Sendable {
    case small
    case extraLarge = "extra-large"
}

enum FixtureCatalog {
    static let routes = [
        Route(title: "Alpha", path: "/alpha/"),
        Route(title: "Beta", path: "/beta/"),
        Route(title: "Gamma", path: "/gamma/")
    ]
}

struct FixtureDocument: Decodable, Sendable {
    let title: String
    let count: Int
    let ratio: Double
    let enabled: Bool
    let kind: WidgetKind
    let caption: String?
    let labels: [String: String]
    let rows: [Row]
    let nested: Inner

    struct Row: Decodable, Sendable {
        let year: Int
        let status: String
        let note: String?
    }

    struct Inner: Decodable, Sendable { let left: String; let right: Int }
}
`;

const SYNTHETIC_CONTRACT = {
    about: ['Fixture for test-parity-drift.mjs. Not used by the real check.'],
    dataRoot: 'https://example.invalid/data',
    siteRoot: 'https://example.invalid',
    endpoints: [{ id: 'fixture', path: 'fixture.json', document: 'FixtureDocument', route: '/fixture/', swift: 'Fixture.swift' }],
    closedSets: [
        {
            id: 'row-status',
            endpoint: 'fixture',
            jsonPath: 'rows[].status',
            handled: ['ok', 'warn'],
            swift: 'FixtureStatus.style(_:)',
            consequence: 'Falls through to the default branch.'
        },
        {
            id: 'label-keys',
            endpoint: 'fixture',
            jsonPath: 'labels',
            mode: 'requiredMapKeys',
            handled: ['alpha', 'beta'],
            swift: 'FixtureLabel',
            consequence: 'A missing key reads as empty.'
        }
    ],
    markupMirrors: [
        { id: 'fixture-prose', route: '/fixture/', swift: 'Fixture.swift', phrases: ['the mirrored sentence'], note: 'Mirrored from markup.' }
    ],
    navigation: {
        page: '/fixture/',
        basePath: '/base',
        swift: 'Fixture.swift',
        minimumRoutes: 2,
        ignore: ['/'],
        note: 'Fixture nav.'
    },
    unchecked: []
};


function syntheticSuite() {
    console.log('synthetic schema');
    const dir = mkdtempSync(join(tmpdir(), 'parity-synthetic-'));
    const sourceDir = join(dir, 'src');
    mkdirSync(sourceDir);
    writeFileSync(join(sourceDir, 'Fixture.swift'), SYNTHETIC_SWIFT);
    const contractPath = join(dir, 'contract.json');
    writeFileSync(contractPath, JSON.stringify(SYNTHETIC_CONTRACT, null, 2));

    const { types } = extractSchemas(sourceDir);
    const options = { sourceDir, contract: contractPath };

    // The parser is the foundation; assert it before asserting on findings.
    const doc = types.get('FixtureDocument');
    check('parser reads all nine stored properties', doc?.fields.length === 9,
        `read ${doc?.fields.length}: ${doc?.fields.map((f) => f.key).join(', ')}`);
    check('parser marks `caption` optional',
        doc?.fields.find((f) => f.key === 'caption')?.type.kind === 'optional');
    check('parser reads a one-line struct body',
        types.get('FixtureDocument.Inner')?.fields.length === 2,
        `read ${types.get('FixtureDocument.Inner')?.fields.length}`);
    check('parser reads a renamed enum case',
        resolve({ kind: 'named', name: 'WidgetKind' }, types, null)?.values.join(',') === 'small,extra-large');

    const clean = buildFixture(SYNTHETIC_CONTRACT, types, sourceDir);

    {
        const { status, report } = run(clean, options);
        check('clean payload: no findings and exit 0',
            status === 0 && report.findings.length === 0,
            `exit ${status}, findings: ${JSON.stringify(kinds(report))}`);
    }

    const cases = [
        ['required key absent', (d, io) => { const p = io.read('fixture.json'); delete p.title; io.write('fixture.json', p); },
            'missing-required', 'title', 'break'],
        ['required key null', (d, io) => { const p = io.read('fixture.json'); p.title = null; io.write('fixture.json', p); },
            'missing-required', 'title', 'break'],
        ['Int field carries a string', (d, io) => { const p = io.read('fixture.json'); p.count = '4'; io.write('fixture.json', p); },
            'type-mismatch', 'count', 'break'],
        ['Int field carries a fraction', (d, io) => { const p = io.read('fixture.json'); p.count = 1.5; io.write('fixture.json', p); },
            'type-mismatch', 'count', 'break'],
        ['Bool field carries a string', (d, io) => { const p = io.read('fixture.json'); p.enabled = 'yes'; io.write('fixture.json', p); },
            'type-mismatch', 'enabled', 'break'],
        ['array field carries an object', (d, io) => { const p = io.read('fixture.json'); p.rows = { a: 1 }; io.write('fixture.json', p); },
            'type-mismatch', 'rows', 'break'],
        ['nested required key absent', (d, io) => { const p = io.read('fixture.json'); delete p.rows[0].year; io.write('fixture.json', p); },
            'missing-required', 'rows[].year', 'break'],
        ['enum carries an unknown case', (d, io) => { const p = io.read('fixture.json'); p.kind = 'gigantic'; io.write('fixture.json', p); },
            'enum-unknown', 'kind', 'break'],
        ['payload is not JSON', (d, io) => io.writeText('fixture.json', '<!doctype html>404'),
            'malformed-payload', '', 'break'],
        ['new published key', (d, io) => { const p = io.read('fixture.json'); p.subtitle = 'new'; io.write('fixture.json', p); },
            'unknown-key', 'subtitle', 'drift'],
        ['new published key inside an element', (d, io) => { const p = io.read('fixture.json'); p.rows[0].pct = 2; io.write('fixture.json', p); },
            'unknown-key', 'rows[].pct', 'drift'],
        ['closed set gains a value', (d, io) => { const p = io.read('fixture.json'); p.rows[0].status = 'exploded'; io.write('fixture.json', p); },
            'closed-set-unhandled', 'rows[].status', 'drift'],
        ['required map key disappears', (d, io) => { const p = io.read('fixture.json'); delete p.labels.beta; io.write('fixture.json', p); },
            'required-map-key-missing', 'labels', 'drift'],
        ['mirrored wording is reworded', (d, io) => io.writeText('fixture-prose.html', '<!doctype html><p>something else entirely</p>'),
            'mirror-missing', '', 'drift'],
        ['closed set value retires', (d, io) => {
            const p = io.read('fixture.json');
            p.rows = p.rows.map((row) => ({ ...row, status: 'ok' }));
            io.write('fixture.json', p);
        }, 'closed-set-unused', 'rows[].status', 'note'],
        ['optional key absent', (d, io) => { const p = io.read('fixture.json'); delete p.caption; io.write('fixture.json', p); },
            null, null, null],
        ['optional key null', (d, io) => { const p = io.read('fixture.json'); p.caption = null; io.write('fixture.json', p); },
            null, null, null],
        ['optional key inside an element absent', (d, io) => { const p = io.read('fixture.json'); delete p.rows[0].note; io.write('fixture.json', p); },
            null, null, null],

        // The route table against the web app's own navigation. This is the
        // gap class that needed a manual audit to find.
        ['nav offers a route the app lacks', (d, io) =>
            io.writeText('navigation.html', io.readText('navigation.html').replace('</nav>', '<a href="/base/delta/">Delta</a></nav>')),
            'nav-route-missing', '', 'drift'],
        ['app offers a route the nav retired', (d, io) =>
            io.writeText('navigation.html', io.readText('navigation.html').replace('<a href="/base/gamma/">/gamma/</a>', '')),
            'nav-route-retired', '', 'drift'],
        // The homepage link is in `ignore`; if that stopped working it would
        // fail every run.
        ['ignored nav route stays ignored', (d, io) => { /* fixture as generated */ },
            null, null, null]
    ];

    for (const [name, mutator, kind, path, severity] of cases) {
        const dir_ = mutate(clean, mutator);
        const { status, report } = run(dir_, options);
        if (kind === null) {
            check(`${name}: still silent`, report.findings.length === 0 && status === 0,
                `exit ${status}, findings: ${JSON.stringify(kinds(report))}`);
        } else {
            const finding = find(report, kind, path);
            check(`${name}: reports ${kind}`, Boolean(finding),
                `got ${JSON.stringify(report.findings.map((f) => `${f.kind}@${f.schemaPath}`))}`);
            if (finding) {
                check(`${name}: severity ${severity}`, finding.severity === severity, `got ${finding.severity}`);
                const shouldFail = severity === 'break';
                check(`${name}: exit ${shouldFail ? 1 : 0} with --fail-on break`,
                    status === (shouldFail ? 1 : 0), `got ${status}`);
            }
        }
        rmSync(dir_, { recursive: true, force: true });
    }

    // A fetch that never arrives must never fail the run: this check runs on
    // every pull request and the data is on GitHub Pages.
    {
        const dir_ = mutate(clean, (d, io) => rmSync(join(d, 'fixture.json')));
        const { status, report } = run(dir_, options);
        check('unreachable payload: transport finding, exit 0',
            status === 0 && find(report, 'transport'),
            `exit ${status}, findings: ${JSON.stringify(kinds(report))}`);
        rmSync(dir_, { recursive: true, force: true });
    }

    // If extraction breaks, the check must say so and compare nothing. The
    // failure mode this guards against is a near-empty nav reporting every
    // route in the app as one the web has dropped.
    {
        const dir_ = mutate(clean, (d, io) => io.writeText('navigation.html', '<!doctype html><nav>no links here</nav>'));
        const { status, report } = run(dir_, options);
        const retired = report.findings.filter((f) => f.kind === 'nav-route-retired');
        check('unreadable nav: reports transport, not a flood of retired routes',
            status === 0 && find(report, 'transport') && retired.length === 0,
            `exit ${status}, retired=${retired.length}, kinds=${JSON.stringify(kinds(report))}`);
        rmSync(dir_, { recursive: true, force: true });
    }

    // --fail-on drift has to actually be stricter, or the daily job is a no-op.
    {
        const dir_ = mutate(clean, (d, io) => { const p = io.read('fixture.json'); p.subtitle = 'new'; io.write('fixture.json', p); });
        const strict = run(dir_, { ...options, failOn: 'drift' });
        const lenient = run(dir_, { ...options, failOn: 'break' });
        check('--fail-on drift fails on drift alone', strict.status === 1, `got ${strict.status}`);
        check('--fail-on break ignores drift', lenient.status === 0, `got ${lenient.status}`);
        rmSync(dir_, { recursive: true, force: true });
    }

    rmSync(clean, { recursive: true, force: true });
    rmSync(dir, { recursive: true, force: true });
}

// ---------------------------------------------------------------------------
// Suite 2: the real sources and the real contract
// ---------------------------------------------------------------------------

function realSuite() {
    console.log('\nreal sources and contract');
    const contractPath = join(REPO, '.github', 'parity-contract.json');
    const sourceDir = join(REPO, 'Riverhead NY Budget App');
    const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
    const { types } = extractSchemas(sourceDir);
    const options = { sourceDir, contract: contractPath };

    for (const endpoint of contract.endpoints) {
        check(`${endpoint.id}: \`${endpoint.document}\` is declared and Decodable`,
            Boolean(types.get(endpoint.document)?.decodable));
    }
    for (const set of contract.closedSets) {
        check(`closed set ${set.id} names a real endpoint`,
            contract.endpoints.some((e) => e.id === set.endpoint));
    }

    const clean = buildFixture(contract, types, sourceDir);
    {
        const { status, report } = run(clean, options);
        check('a payload generated from the real schema is clean',
            status === 0 && report.findings.length === 0,
            `exit ${status}, findings: ${JSON.stringify(report.findings.map((f) => `${f.kind}@${f.endpoint}:${f.schemaPath}`)).slice(0, 600)}`);
    }

    // Break one real document the way the web app would: drop a field.
    {
        const dir_ = mutate(clean, (d, io) => {
            const payload = io.read('tax-cap.json');
            delete payload.capStatus;
            io.write('tax-cap.json', payload);
        });
        const { status, report } = run(dir_, options);
        check('dropping tax-cap.capStatus is a break',
            status === 1 && find(report, 'missing-required', 'capStatus'),
            `exit ${status}, findings: ${JSON.stringify(kinds(report))}`);
        rmSync(dir_, { recursive: true, force: true });
    }

    rmSync(clean, { recursive: true, force: true });
}

syntheticSuite();
realSuite();

console.log(`\n${passes} passed, ${failures} failed`);
process.exit(failures ? 1 : 0);
