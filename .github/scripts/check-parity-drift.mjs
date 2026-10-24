#!/usr/bin/env node
// Checks the web app's live published data against what the native parity views
// actually require, and reports where the two have drifted apart.
//
// The failure this exists to catch is silent. Every parity view fetches its
// JSON, decodes it, and falls back to a web view when the decode throws. So a
// renamed or retyped field does not crash and does not log: the native screen
// simply stops appearing, and the app keeps working well enough that nobody
// notices. That already happened once, on /tax-bill/.
//
// What counts as what:
//
//   break   the decoder would throw on the live payload. The native view is
//           gone and the user is silently back on the web page.
//   drift   the view still renders but no longer agrees with the web app: a
//           status code it has no colour for, published content it ignores,
//           page wording it mirrored that has since been edited.
//   note    worth knowing, nothing to do.
//
// Beyond the payloads it also compares the app's route table against the web
// app's own navigation, because a route the app never lists is not a parity
// gap a payload check can see.
//
// A fetch that fails is a `transport` finding and never fails the run. The web
// app is on GitHub Pages and this check runs on every pull request; a flaky
// network must not turn into a red check on someone's unrelated change. Only a
// payload that arrived and disagrees can fail.

import { readFileSync, writeFileSync, existsSync, appendFileSync } from 'node:fs';
import { join, dirname, resolve as resolvePath } from 'node:path';
import { fileURLToPath } from 'node:url';
import { extractSchemas, resolve } from './parity-schema.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolvePath(HERE, '..', '..');
const DEFAULT_SOURCE_DIR = join(REPO, 'Riverhead NY Budget App');
const DEFAULT_CONTRACT = join(REPO, '.github', 'parity-contract.json');

const SEVERITY = { break: 3, drift: 2, note: 1, transport: 0 };

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

function parseArgs(argv) {
    const options = {
        failOn: 'break',
        json: null,
        markdown: null,
        offline: null,
        timeout: 25000,
        sourceDir: DEFAULT_SOURCE_DIR,
        contract: DEFAULT_CONTRACT
    };
    for (let i = 0; i < argv.length; i += 1) {
        const arg = argv[i];
        const next = () => argv[(i += 1)];
        switch (arg) {
            case '--fail-on': options.failOn = next(); break;
            case '--json': options.json = next(); break;
            case '--markdown': options.markdown = next(); break;
            case '--offline': options.offline = next(); break;
            case '--timeout': options.timeout = Number(next()); break;
            case '--source-dir': options.sourceDir = next(); break;
            case '--contract': options.contract = next(); break;
            case '--help':
                console.log(`usage: check-parity-drift.mjs [options]

  --fail-on <break|drift|never>  exit non-zero at this severity (default: break)
  --json <path>                  write the machine-readable report here
  --markdown <path>              write a markdown summary here
  --offline <dir>                read payloads from a directory of saved files
                                 instead of fetching (file name = endpoint id)
  --timeout <ms>                 per-request timeout (default: 25000)
  --source-dir <dir>             Swift sources to read the schema from
  --contract <path>              contract file to check against`);
                process.exit(0);
                break;
            default:
                console.error(`unknown option: ${arg}`);
                process.exit(2);
        }
    }
    return options;
}

// ---------------------------------------------------------------------------
// Fetching
// ---------------------------------------------------------------------------

async function fetchJSON(url, timeout) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeout);
    try {
        const response = await fetch(url, {
            signal: controller.signal,
            headers: { accept: 'application/json', 'user-agent': 'riverhead-parity-drift-check' },
            cache: 'no-store'
        });
        if (!response.ok) return { error: `HTTP ${response.status} ${response.statusText}` };
        const text = await response.text();
        try {
            return { value: JSON.parse(text), bytes: text.length };
        } catch (cause) {
            // A payload that arrived but will not parse is a real break: the
            // Swift decoder would throw on it too.
            return { malformed: `the response is not valid JSON: ${cause.message}` };
        }
    } catch (cause) {
        return { error: cause.name === 'AbortError' ? `timed out after ${timeout}ms` : cause.message };
    } finally {
        clearTimeout(timer);
    }
}

async function fetchText(url, timeout) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeout);
    try {
        const response = await fetch(url, { signal: controller.signal, cache: 'no-store' });
        if (!response.ok) return { error: `HTTP ${response.status} ${response.statusText}` };
        return { value: await response.text() };
    } catch (cause) {
        return { error: cause.name === 'AbortError' ? `timed out after ${timeout}ms` : cause.message };
    } finally {
        clearTimeout(timer);
    }
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

function jsonKindOf(value) {
    if (value === null) return 'null';
    if (Array.isArray(value)) return 'array';
    if (typeof value === 'number') return Number.isInteger(value) ? 'integer' : 'number';
    return typeof value; // string | boolean | object
}

class Walker {
    constructor(types, endpoint, report) {
        this.types = types;
        this.endpoint = endpoint;
        this.report = report;
        this.seen = new Set(); // dedupe by schema path, not by element index
    }

    add(kind, severity, schemaPath, examplePath, detail, extra = {}) {
        const key = `${kind}|${schemaPath}|${detail}`;
        const existing = this.seen.has(key);
        if (existing) {
            const finding = this.report.find((f) => f.key === key);
            if (finding) finding.occurrences += 1;
            return;
        }
        this.seen.add(key);
        this.report.push({
            key,
            kind,
            severity,
            endpoint: this.endpoint.id,
            route: this.endpoint.route,
            swift: this.endpoint.swift,
            schemaPath,
            examplePath,
            detail,
            occurrences: 1,
            ...extra
        });
    }

    // `type` is a parsed Swift type; `scope` is the qualified name it was
    // written inside, for resolving unqualified nested names.
    walk(value, type, scope, schemaPath, examplePath, optional = false) {
        if (type.kind === 'optional') {
            this.walk(value, type.of, scope, schemaPath, examplePath, true);
            return;
        }

        if (value === null || value === undefined) {
            if (!optional) {
                this.add(
                    'missing-required',
                    'break',
                    schemaPath,
                    examplePath,
                    `required by the Swift decoder but ${value === null ? 'null' : 'absent'} in the live payload`
                );
            }
            return;
        }

        const resolved = resolve(type, this.types, scope);
        if (!resolved) {
            this.add(
                'unresolved-type',
                'drift',
                schemaPath,
                examplePath,
                `the checker could not resolve the Swift type \`${type.name}\`, so this field is unverified`
            );
            return;
        }

        const actual = jsonKindOf(value);

        switch (resolved.kind) {
            case 'primitive': {
                const want = resolved.json;
                if (want === 'number' && (actual === 'integer' || actual === 'number')) return;
                if (want === 'integer' && actual === 'integer') return;
                if (want === 'integer' && actual === 'number') {
                    // JSONDecoder will not put 1.5 in an Int. An integral
                    // double is accepted by some Foundation versions and not
                    // others, so it is reported as drift rather than a break.
                    this.add(
                        'type-mismatch',
                        'break',
                        schemaPath,
                        examplePath,
                        `the Swift field is \`Int\` but the live value is fractional (${value})`
                    );
                    return;
                }
                if (want === actual) return;
                this.add(
                    'type-mismatch',
                    'break',
                    schemaPath,
                    examplePath,
                    `the Swift field is \`${resolved.swift}\` but the live value is ${actual}${actual === 'string' ? ` (${JSON.stringify(value).slice(0, 40)})` : ''}`
                );
                return;
            }

            case 'stringEnum': {
                if (actual !== 'string') {
                    this.add('type-mismatch', 'break', schemaPath, examplePath,
                        `the Swift field is the enum \`${resolved.name}\` but the live value is ${actual}`);
                    return;
                }
                if (!resolved.values.includes(value)) {
                    this.add('enum-unknown', 'break', schemaPath, examplePath,
                        `"${value}" is not a case of \`${resolved.name}\` (${resolved.values.join(', ')}), so the decoder throws`);
                }
                return;
            }

            case 'object': {
                if (actual !== 'object') {
                    this.add('type-mismatch', 'break', schemaPath, examplePath,
                        `the Swift field decodes \`${resolved.name}\` but the live value is ${actual}`);
                    return;
                }
                const entry = this.types.get(resolved.name);
                if (!entry || entry.fields.length === 0) {
                    this.add('unresolved-type', 'drift', schemaPath, examplePath,
                        `\`${resolved.name}\` has no readable stored properties, so its keys are unverified`);
                    return;
                }
                const declared = new Set();
                for (const field of entry.fields) {
                    declared.add(field.key);
                    this.walk(
                        value[field.key],
                        field.type,
                        resolved.name,
                        schemaPath ? `${schemaPath}.${field.key}` : field.key,
                        examplePath ? `${examplePath}.${field.key}` : field.key,
                        false
                    );
                }
                for (const key of Object.keys(value)) {
                    if (declared.has(key)) continue;
                    this.add('unknown-key', 'drift',
                        schemaPath ? `${schemaPath}.${key}` : key,
                        examplePath ? `${examplePath}.${key}` : key,
                        `the web app publishes this but \`${resolved.name}\` has no property for it, so the view ignores it`,
                        { swiftType: resolved.name, declaredIn: entry.file, declaredAt: entry.line });
                }
                return;
            }

            case 'opaque':
                this.add('unresolved-type', 'drift', schemaPath, examplePath,
                    `\`${resolved.name}\` is not a struct or string-backed enum, so this field is unverified`);
                return;

            default:
                break;
        }

        if (type.kind === 'array') {
            if (actual !== 'array') {
                this.add('type-mismatch', 'break', schemaPath, examplePath,
                    `the Swift field is an array but the live value is ${actual}`);
                return;
            }
            value.forEach((element, index) => {
                this.walk(element, type.of, scope, `${schemaPath}[]`, `${examplePath}[${index}]`, false);
            });
            return;
        }

        if (type.kind === 'dictionary') {
            if (actual !== 'object') {
                this.add('type-mismatch', 'break', schemaPath, examplePath,
                    `the Swift field is a dictionary but the live value is ${actual}`);
                return;
            }
            for (const [key, element] of Object.entries(value)) {
                this.walk(element, type.value, scope, `${schemaPath}[*]`, `${examplePath}.${key}`, false);
            }
        }
    }
}

// `capStatus[].status` / `races[].candidates[].party` / `shards`
function collectPath(root, path) {
    const segments = path.split('.');
    let current = [root];
    for (const segment of segments) {
        const isArray = segment.endsWith('[]');
        const key = isArray ? segment.slice(0, -2) : segment;
        const next = [];
        for (const node of current) {
            if (node === null || typeof node !== 'object') continue;
            const value = key === '' ? node : node[key];
            if (value === undefined || value === null) continue;
            if (isArray) {
                if (Array.isArray(value)) next.push(...value);
            } else {
                next.push(value);
            }
        }
        current = next;
    }
    return current;
}

// ---------------------------------------------------------------------------
// Reporting
// ---------------------------------------------------------------------------

const ANNOTATION = { break: 'error', drift: 'warning', note: 'notice', transport: 'notice' };

function annotate(finding) {
    if (!process.env.GITHUB_ACTIONS) return;
    const level = ANNOTATION[finding.severity] ?? 'notice';
    const file = finding.declaredIn
        ? `Riverhead NY Budget App/${finding.declaredIn}`
        : finding.swift
            ? `Riverhead NY Budget App/${finding.swift}`
            : null;
    const parts = ['title=Parity drift'];
    if (file) parts.push(`file=${file}`);
    if (finding.declaredAt) parts.push(`line=${finding.declaredAt}`);
    const where = finding.schemaPath ? ` ${finding.schemaPath}:` : '';
    console.log(`::${level} ${parts.join(',')}::${finding.endpoint}${where} ${finding.detail}`.replace(/\n/g, ' '));
}

function renderMarkdown(report, endpoints, checked) {
    const pick = (s) => report.filter((f) => f.severity === s);
    const breaks = pick('break');
    const drifts = pick('drift');
    const notes = pick('note');
    const transport = pick('transport');

    const lines = ['## Web parity drift', ''];
    if (!breaks.length && !drifts.length) {
        lines.push(`No drift. ${checked} of ${endpoints.length} endpoints fetched and checked against the Swift decoders.`);
    } else {
        lines.push(
            `${breaks.length} break${breaks.length === 1 ? '' : 's'}, ` +
            `${drifts.length} drift${drifts.length === 1 ? '' : 's'}, ` +
            `over ${checked} of ${endpoints.length} endpoints.`
        );
    }
    lines.push('');

    const section = (title, findings, blurb) => {
        if (!findings.length) return;
        lines.push(`### ${title}`, '', blurb, '');
        lines.push('| route | where | what |', '| --- | --- | --- |');
        for (const f of findings) {
            const count = f.occurrences > 1 ? ` _(×${f.occurrences})_` : '';
            lines.push(`| \`${f.route ?? f.endpoint}\` | \`${f.schemaPath || '—'}\` | ${f.detail}${count} |`);
        }
        lines.push('');
    };

    section('Breaks', breaks,
        'The Swift decoder throws on the live payload, so the native screen is gone and the user silently gets the web page instead.');
    section('Drift', drifts,
        'The view still renders, but it no longer agrees with the web app.');
    section('Notes', notes, 'Nothing to do.');

    if (transport.length) {
        lines.push('### Not reached', '',
            'These were not fetched, so nothing is claimed about them. A fetch failure never fails this check.', '');
        for (const f of transport) lines.push(`- \`${f.endpoint}\` — ${f.detail}`);
        lines.push('');
    }

    return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
    const options = parseArgs(process.argv.slice(2));
    const contract = JSON.parse(readFileSync(options.contract, 'utf8'));
    const { types, problems } = extractSchemas(options.sourceDir);
    const report = [];

    const push = (kind, severity, endpoint, detail, extra = {}) => {
        report.push({
            key: `${kind}|${endpoint?.id ?? ''}|${detail}`,
            kind,
            severity,
            endpoint: endpoint?.id ?? '—',
            route: endpoint?.route ?? null,
            swift: endpoint?.swift ?? null,
            schemaPath: '',
            examplePath: '',
            detail,
            occurrences: 1,
            ...extra
        });
    };

    // Any document type the contract names but the source does not declare
    // means the contract has fallen behind a rename. Say so rather than
    // skipping the endpoint.
    let checked = 0;
    const payloads = new Map();

    for (const endpoint of contract.endpoints) {
        const entry = types.get(endpoint.document);
        if (!entry) {
            push('unmapped-document', 'drift', endpoint,
                `the contract points at \`${endpoint.document}\`, which is not declared in the Swift source any more`);
            continue;
        }
        if (!entry.decodable) {
            push('unmapped-document', 'drift', endpoint,
                `\`${endpoint.document}\` is not Decodable, so the contract is pointing at the wrong type`);
            continue;
        }

        const url = `${contract.dataRoot}/${endpoint.path}`;
        let payload;
        if (options.offline) {
            const file = join(options.offline, `${endpoint.id}.json`);
            if (!existsSync(file)) {
                push('transport', 'transport', endpoint, `no saved payload at ${file}`);
                continue;
            }
            const saved = readFileSync(file, 'utf8');
            try {
                payload = { value: JSON.parse(saved) };
            } catch (cause) {
                // Same verdict as the live path: a payload that will not parse
                // is a break, because the Swift decoder throws on it too. This
                // is the shape a GitHub Pages 404 arrives in — an HTML error
                // page served with a 200.
                payload = { malformed: `the saved payload is not valid JSON: ${cause.message}` };
            }
        } else {
            payload = await fetchJSON(url, options.timeout);
        }

        if (payload.malformed) {
            push('malformed-payload', 'break', endpoint, payload.malformed);
            continue;
        }
        if (payload.error) {
            push('transport', 'transport', endpoint, `${url} — ${payload.error}`);
            continue;
        }

        checked += 1;
        payloads.set(endpoint.id, payload.value);
        const walker = new Walker(types, endpoint, report);
        walker.walk(payload.value, { kind: 'named', name: endpoint.document }, null, '', '', false);
    }

    // Closed sets: string fields the Swift switches over with a `default`, so
    // the decode succeeds and the screen quietly loses meaning.
    for (const set of contract.closedSets) {
        const endpoint = contract.endpoints.find((e) => e.id === set.endpoint);
        const payload = payloads.get(set.endpoint);
        if (!payload) continue; // the transport finding already covers it

        const handled = new Set(set.handled);
        if (set.mode === 'requiredMapKeys') {
            const nodes = collectPath(payload, set.jsonPath);
            const present = new Set(nodes.flatMap((n) => (n && typeof n === 'object' ? Object.keys(n) : [])));
            const missing = set.handled.filter((k) => !present.has(k));
            if (missing.length) {
                push('required-map-key-missing', 'drift', endpoint,
                    `\`${set.jsonPath}\` no longer carries ${missing.map((m) => `\`${m}\``).join(', ')}. ${set.consequence}`,
                    { schemaPath: set.jsonPath });
            }
            continue;
        }

        const values = collectPath(payload, set.jsonPath).filter((v) => typeof v === 'string');
        const unhandled = [...new Set(values.filter((v) => !handled.has(v)))];
        if (unhandled.length) {
            push('closed-set-unhandled', 'drift', endpoint,
                `\`${set.jsonPath}\` now carries ${unhandled.map((v) => `"${v}"`).join(', ')}, which ${set.swift} does not handle. ${set.consequence}`,
                { schemaPath: set.jsonPath });
        }
        const unused = set.handled.filter((v) => !values.includes(v));
        if (unused.length && values.length) {
            push('closed-set-unused', 'note', endpoint,
                `${set.swift} handles ${unused.map((v) => `"${v}"`).join(', ')}, which no longer appears in the data`,
                { schemaPath: set.jsonPath });
        }
    }

    // Markup mirrors: prose copied out of a page because it is in no JSON file.
    for (const mirror of contract.markupMirrors) {
        const url = `${contract.siteRoot}${mirror.route}`;
        let html;
        if (options.offline) {
            const file = join(options.offline, `${mirror.id}.html`);
            if (!existsSync(file)) {
                push('transport', 'transport', { id: mirror.id, route: mirror.route, swift: mirror.swift },
                    `no saved page at ${file}`);
                continue;
            }
            html = readFileSync(file, 'utf8');
        } else {
            const fetched = await fetchText(url, options.timeout);
            if (fetched.error) {
                push('transport', 'transport', { id: mirror.id, route: mirror.route, swift: mirror.swift },
                    `${url} — ${fetched.error}`);
                continue;
            }
            html = fetched.value;
        }

        // Compare on collapsed whitespace: the page is minified HTML and the
        // Swift wraps its copy across source lines.
        const flat = html.replace(/\s+/g, ' ');
        const gone = mirror.phrases.filter((p) => !flat.includes(p.replace(/\s+/g, ' ')));
        if (gone.length) {
            push('mirror-missing', 'drift',
                { id: mirror.id, route: mirror.route, swift: mirror.swift },
                `${mirror.swift} mirrors wording that is no longer on the page: ${gone.map((g) => `"${g}"`).join('; ')}. ${mirror.note}`);
        }
    }

    // Navigation: does the app's route table still offer what the web app's nav
    // offers? This is the gap that needed a manual audit to find — the table had
    // fallen six routes behind SiteNav with nothing watching.
    if (contract.navigation) {
        const nav = contract.navigation;
        const url = `${contract.siteRoot}${nav.page}`;
        let html;

        if (options.offline) {
            const file = join(options.offline, 'navigation.html');
            if (!existsSync(file)) {
                push('transport', 'transport', { id: 'navigation', route: nav.page, swift: nav.swift },
                    `no saved page at ${file}`);
                html = null;
            } else {
                html = readFileSync(file, 'utf8');
            }
        } else {
            const fetched = await fetchText(url, options.timeout);
            if (fetched.error) {
                push('transport', 'transport', { id: 'navigation', route: nav.page, swift: nav.swift },
                    `${url} — ${fetched.error}`);
                html = null;
            } else {
                html = fetched.value;
            }
        }

        if (html) {
            const base = nav.basePath ?? '';
            const pattern = new RegExp(`href="${base.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(/[a-z0-9-]*/(?:#[a-z-]+)?)"`, 'g');
            const ignore = new Set(nav.ignore ?? []);
            const webRoutes = new Set();
            for (const m of html.matchAll(pattern)) {
                if (!ignore.has(m[1])) webRoutes.add(m[1]);
            }

            const swiftPath = join(options.sourceDir, nav.swift);
            const appRoutes = new Set();
            if (existsSync(swiftPath)) {
                const swift = readFileSync(swiftPath, 'utf8');
                for (const m of swift.matchAll(/path:\s*"([^"]+)"/g)) appRoutes.add(m[1]);
            }

            const floor = nav.minimumRoutes ?? 0;
            if (webRoutes.size < floor) {
                // Extraction broke rather than the nav shrinking. Say so and
                // claim nothing: the alternative is reporting every route in the
                // app as one the web has dropped.
                push('transport', 'transport', { id: 'navigation', route: nav.page, swift: nav.swift },
                    `read only ${webRoutes.size} nav links from ${url}, below the floor of ${floor} — ` +
                    `the markup has probably changed, so no comparison was made`);
            } else if (appRoutes.size === 0) {
                push('transport', 'transport', { id: 'navigation', route: nav.page, swift: nav.swift },
                    `no route table found in ${nav.swift}, so no comparison was made`);
            } else {
                for (const route of [...webRoutes].sort()) {
                    if (appRoutes.has(route)) continue;
                    push('nav-route-missing', 'drift', { id: 'navigation', route, swift: nav.swift },
                        `the web app's navigation offers \`${route}\` and the app's route table does not, ` +
                        `so the page is unreachable from the app — not even as a web fallback`);
                }
                for (const route of [...appRoutes].sort()) {
                    if (webRoutes.has(route)) continue;
                    push('nav-route-retired', 'drift', { id: 'navigation', route, swift: nav.swift },
                        `the app's route table offers \`${route}\` and the web app's navigation no longer does`);
                }
            }
        }
    }

    // Parser problems, but only for types an endpoint actually reaches.
    const reachable = new Set();
    const collectReachable = (name, scope) => {
        const resolved = resolve({ kind: 'named', name }, types, scope);
        if (!resolved || resolved.kind !== 'object' || reachable.has(resolved.name)) return;
        reachable.add(resolved.name);
        const entry = types.get(resolved.name);
        if (!entry) return;
        for (const field of entry.fields) {
            let type = field.type;
            while (type.kind === 'optional' || type.kind === 'array') type = type.of;
            if (type.kind === 'dictionary') type = type.value;
            if (type.kind === 'named') collectReachable(type.name, resolved.name);
        }
    };
    for (const endpoint of contract.endpoints) collectReachable(endpoint.document, null);
    for (const problem of problems) {
        const named = [...reachable].some((name) => problem.detail.includes(`\`${name}\``));
        if (!named) continue;
        push('parser', 'drift', null, `${problem.file}:${problem.line} — ${problem.detail}`);
    }

    // ---- output ----
    const order = (f) => -SEVERITY[f.severity];
    report.sort((a, b) => order(a) - order(b) || a.endpoint.localeCompare(b.endpoint) || a.schemaPath.localeCompare(b.schemaPath));

    const counts = { break: 0, drift: 0, note: 0, transport: 0 };
    for (const finding of report) counts[finding.severity] += 1;

    const label = { break: 'BREAK', drift: 'DRIFT', note: 'note ', transport: 'skip ' };
    console.log(`checked ${checked} of ${contract.endpoints.length} endpoints against ${types.size} declared Swift types\n`);
    if (!report.length) {
        console.log('no findings — the live data and the native views agree');
    }
    for (const finding of report) {
        const count = finding.occurrences > 1 ? ` (x${finding.occurrences})` : '';
        console.log(`${label[finding.severity]}  ${finding.endpoint}  ${finding.schemaPath || ''}`.trimEnd());
        console.log(`        ${finding.detail}${count}`);
        if (finding.examplePath && finding.examplePath !== finding.schemaPath) {
            console.log(`        first seen at ${finding.examplePath}`);
        }
        annotate(finding);
    }
    console.log(
        `\n${counts.break} break, ${counts.drift} drift, ${counts.note} note, ${counts.transport} not reached`
    );

    const payload = {
        generatedAt: new Date().toISOString(),
        dataRoot: contract.dataRoot,
        endpointsInContract: contract.endpoints.length,
        endpointsChecked: checked,
        swiftTypesRead: types.size,
        counts,
        findings: report.map(({ key, ...rest }) => rest)
    };
    if (options.json) writeFileSync(options.json, `${JSON.stringify(payload, null, 2)}\n`);

    const summary = renderMarkdown(report, contract.endpoints, checked);
    if (options.markdown) writeFileSync(options.markdown, `${summary}\n`);
    if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, `${summary}\n`);

    if (options.failOn === 'never') return 0;
    const threshold = SEVERITY[options.failOn] ?? SEVERITY.break;
    return report.some((f) => SEVERITY[f.severity] >= threshold && f.severity !== 'transport') ? 1 : 0;
}

main().then((code) => process.exit(code)).catch((error) => {
    console.error(error);
    process.exit(2);
});
