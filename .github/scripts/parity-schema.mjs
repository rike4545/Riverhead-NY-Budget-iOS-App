// Derives the JSON shape each native parity view actually requires, by reading
// the Swift source rather than restating it in a hand-maintained schema file.
//
// Why read the Swift instead of writing a schema by hand: a hand-written schema
// is a second copy of the contract, and the second copy is the one that goes
// stale. Deriving it means a route added tomorrow is covered the day it lands,
// and a field someone makes optional stops being reported as required in the
// same commit that makes it optional.
//
// The parser understands the narrow dialect these documents are written in:
// `Decodable` structs of one-line stored properties, string-backed `Decodable`
// enums, and the one hand-written `init(from:)` in OfficialsParityView. It is
// deliberately strict — anything it does not understand is reported as an
// `unparsed` entry rather than quietly dropped, because a document that falls
// out of the schema silently is exactly the hole this is meant to close.

import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

// Swift types that map straight onto a JSON scalar.
const PRIMITIVES = {
    String: 'string',
    Int: 'integer',
    Int32: 'integer',
    Int64: 'integer',
    Double: 'number',
    Float: 'number',
    Bool: 'boolean'
};

// ---------------------------------------------------------------------------
// Lexing
// ---------------------------------------------------------------------------

// Replaces comment and string-literal *contents* with filler of the same
// length, so brace counting and line matching cannot be thrown off by a `{`
// inside a comment or a `//` inside a URL literal. Offsets are preserved, so a
// position in the mask is a position in the source.
export function mask(source) {
    const out = Array.from(source);
    const n = source.length;
    let i = 0;

    const blank = (from, to, keepNewlines = true) => {
        for (let k = from; k < to && k < n; k += 1) {
            if (!(keepNewlines && out[k] === '\n')) out[k] = ' ';
        }
    };

    while (i < n) {
        const two = source.slice(i, i + 2);

        if (two === '//') {
            let end = source.indexOf('\n', i);
            if (end === -1) end = n;
            blank(i, end);
            i = end;
            continue;
        }

        if (two === '/*') {
            let depth = 1;
            let k = i + 2;
            while (k < n && depth > 0) {
                if (source.slice(k, k + 2) === '/*') { depth += 1; k += 2; continue; }
                if (source.slice(k, k + 2) === '*/') { depth -= 1; k += 2; continue; }
                k += 1;
            }
            blank(i, k);
            i = k;
            continue;
        }

        if (source.slice(i, i + 3) === '"""') {
            const end = source.indexOf('"""', i + 3);
            const stop = end === -1 ? n : end + 3;
            blank(i + 3, stop - 3);
            i = stop;
            continue;
        }

        if (source[i] === '"') {
            let k = i + 1;
            while (k < n) {
                if (source[k] === '\\') {
                    // `\(` opens an interpolation, which may itself contain
                    // quotes and parentheses. Skip to its matching paren.
                    if (source[k + 1] === '(') {
                        let depth = 1;
                        let j = k + 2;
                        while (j < n && depth > 0) {
                            if (source[j] === '(') depth += 1;
                            else if (source[j] === ')') depth -= 1;
                            j += 1;
                        }
                        k = j;
                        continue;
                    }
                    k += 2;
                    continue;
                }
                if (source[k] === '"') { k += 1; break; }
                if (source[k] === '\n') break; // unterminated; let it go
                k += 1;
            }
            blank(i + 1, k - 1);
            i = k;
            continue;
        }

        i += 1;
    }

    return out.join('');
}

// ---------------------------------------------------------------------------
// Type grammar
// ---------------------------------------------------------------------------

function splitDictionary(inner) {
    let depth = 0;
    for (let i = 0; i < inner.length; i += 1) {
        const c = inner[i];
        if (c === '[' || c === '(' || c === '<') depth += 1;
        else if (c === ']' || c === ')' || c === '>') depth -= 1;
        else if (c === ':' && depth === 0) return i;
    }
    return -1;
}

export function parseType(text) {
    let s = text.trim();
    while (s.startsWith('(') && s.endsWith(')')) s = s.slice(1, -1).trim();

    if (s.endsWith('?')) return { kind: 'optional', of: parseType(s.slice(0, -1)) };

    if (s.startsWith('[') && s.endsWith(']')) {
        const inner = s.slice(1, -1);
        const colon = splitDictionary(inner);
        if (colon >= 0) {
            return {
                kind: 'dictionary',
                key: parseType(inner.slice(0, colon)),
                value: parseType(inner.slice(colon + 1))
            };
        }
        return { kind: 'array', of: parseType(inner) };
    }

    // `Self.Foo` and `Document.Foo` resolve the same way as a bare name.
    return { kind: 'named', name: s.replace(/^Self\./, '') };
}

// ---------------------------------------------------------------------------
// Declaration walking
// ---------------------------------------------------------------------------

const DECL = /^\s*(?:(?:public|internal|private|fileprivate|package|open)\s+)?(?:(?:final|indirect)\s+)?(struct|enum|class|actor|extension)\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*([^{]*))?\{/;
const STORED = /^(?:(?:public|internal|private|fileprivate|package)\s+)?(?:(?:private|internal)\(set\)\s+)?(let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.+)$/;
const DECODE = /\bcontainer\.(decode|decodeIfPresent)\(\s*([^,]+?)\.self\s*,\s*forKey:\s*\.([A-Za-z_][A-Za-z0-9_]*)\s*\)/g;

function conformances(clause) {
    if (!clause) return [];
    return clause.split(',').map((s) => s.trim()).filter(Boolean);
}

function isDecodable(list) {
    return list.some((c) => c === 'Decodable' || c === 'Codable');
}

// Reads one statement as a stored property, if that is what it is. Shared by
// the line walker and by self-contained one-line declarations, which Swift
// writes with semicolons: `struct Source: Decodable { let title: String; let
// url: String }`. Those were silently contributing no fields until the two
// paths were made the same path.
function readStored(entry, statement, lineNumber, file, problems) {
    if (entry.kind === 'enum') return;
    const stored = STORED.exec(statement.trim());
    if (!stored) return;

    const [, , name, typeText] = stored;
    const isStatic = /^(?:(?:public|internal|private|fileprivate|package)\s+)?(?:static|class)\s/.test(statement.trim());
    const computed = typeText.includes('{');
    const assigned = /(?:^|[^=!<>])=(?!=)/.test(typeText);
    const closure = typeText.includes('->');

    // Static, computed and defaulted properties take no part in decoding.
    if (isStatic || computed || assigned || closure) return;

    if (/,\s*$/.test(typeText) || typeText.includes('//')) {
        problems.push({
            file,
            line: lineNumber,
            detail: `could not read the type of \`${name}\` (declaration spans lines?)`
        });
        return;
    }

    entry.fields.push({ property: name, type: parseType(typeText), line: lineNumber, source: 'declaration' });
}

// Walks one file and returns every type declared in it, keyed by its fully
// qualified name (`OfficialsParityDocument.Official`).
function walkFile(path, source) {
    const masked = mask(source);
    const lines = masked.split('\n');
    const rawLines = source.split('\n');

    const types = new Map();
    const problems = [];
    const stack = []; // { name, kind, conformances, depth, entry }
    let depth = 0;

    for (let ln = 0; ln < lines.length; ln += 1) {
        const line = lines[ln];
        const trimmed = line.trim();
        const match = DECL.exec(line);

        if (match) {
            const [, kind, name, clause] = match;
            const list = conformances(clause);
            const path_ = [...stack.map((s) => s.name), name];
            const qualified = kind === 'extension' ? name : path_.join('.');

            let entry = types.get(qualified);
            if (!entry || kind === 'extension') {
                entry = types.get(qualified) || {
                    name: qualified,
                    simpleName: name,
                    kind,
                    file: path,
                    line: ln + 1,
                    conformances: list,
                    decodable: isDecodable(list),
                    rawType: list.find((c) => PRIMITIVES[c]) || null,
                    fields: [],
                    cases: [],
                    hasCustomInit: false,
                    codingKeys: new Map()
                };
                types.set(qualified, entry);
            } else {
                entry.conformances = [...new Set([...entry.conformances, ...list])];
                entry.decodable = entry.decodable || isDecodable(list);
            }

            // Count braces on the declaration line itself so a one-line
            // declaration (`struct S: Decodable { let a: String }`) closes here
            // instead of swallowing the rest of the file.
            const opens = (line.match(/\{/g) || []).length;
            const closes = (line.match(/\}/g) || []).length;
            if (opens > closes) {
                stack.push({ name, kind, depth, entry });
                depth += opens - closes;
            } else {
                // The whole declaration is on this line, so its body closes
                // here. Read it now; the scope walker will never see it.
                const body = line.slice(line.indexOf('{') + 1, line.lastIndexOf('}'));
                for (const statement of body.split(';')) {
                    readStored(entry, statement, ln + 1, path, problems);
                }
            }
            continue;
        }

        const scope = stack[stack.length - 1];

        if (scope) {
            if (/\binit\s*\(\s*from\s+\w+\s*:\s*Decoder\s*\)/.test(line)) {
                scope.entry.hasCustomInit = true;
            }

            if (scope.entry.kind === 'enum') {
                // `case a, b = "x"` — one line may carry several.
                const caseLine = /^case\s+(.+)$/.exec(trimmed);
                if (caseLine && !/[({]/.test(caseLine[1])) {
                    for (const part of caseLine[1].split(',')) {
                        const bits = /^([A-Za-z_][A-Za-z0-9_]*)\s*(?:=\s*(.+))?$/.exec(part.trim());
                        if (!bits) continue;
                        let raw = bits[1];
                        if (bits[2]) {
                            // Read the literal from the unmasked line.
                            const literal = /"([^"]*)"/.exec(rawLines[ln].slice(rawLines[ln].indexOf(bits[1])));
                            raw = literal ? literal[1] : null;
                        }
                        scope.entry.cases.push({ name: bits[1], raw });
                    }
                }
            }

            // CodingKeys remap JSON keys onto property names.
            if (scope.kind === 'enum' && scope.name === 'CodingKeys') {
                const owner = stack[stack.length - 2];
                const caseLine = /^case\s+(.+)$/.exec(trimmed);
                if (owner && caseLine) {
                    for (const part of caseLine[1].split(',')) {
                        const bits = /^([A-Za-z_][A-Za-z0-9_]*)\s*(?:=\s*(.+))?$/.exec(part.trim());
                        if (!bits) continue;
                        let key = bits[1];
                        if (bits[2]) {
                            const literal = /"([^"]*)"/.exec(rawLines[ln]);
                            if (literal) key = literal[1];
                        }
                        owner.entry.codingKeys.set(bits[1], key);
                    }
                }
            }

            readStored(scope.entry, trimmed, ln + 1, path, problems);
        }

        const opens = (line.match(/\{/g) || []).length;
        const closes = (line.match(/\}/g) || []).length;
        depth += opens - closes;
        while (stack.length && depth <= stack[stack.length - 1].depth) stack.pop();
    }

    // A hand-written `init(from:)` is the authority on what the decoder needs:
    // a property declared non-optional can still be decoded with
    // `decodeIfPresent ?? default`, which makes its JSON key optional. Reading
    // the declaration alone would report that key as required and send someone
    // chasing a break that cannot happen.
    for (const entry of types.values()) {
        if (!entry.hasCustomInit) continue;
        const body = source.slice(indexOfLine(source, entry.line));
        const decoded = new Map();
        for (const m of body.matchAll(DECODE)) {
            const [, call, typeText, key] = m;
            if (decoded.has(key)) continue;
            const inner = parseType(typeText);
            decoded.set(key, {
                property: key,
                type: call === 'decodeIfPresent' ? { kind: 'optional', of: inner } : inner,
                line: entry.line,
                source: 'init(from:)'
            });
        }
        if (decoded.size === 0) {
            problems.push({
                file: path,
                line: entry.line,
                detail: `\`${entry.name}\` writes its own init(from:) but no container.decode calls were found; its keys are unchecked`
            });
        } else {
            entry.fields = [...decoded.values()];
        }
    }

    return { types, problems };
}

function indexOfLine(source, line) {
    let index = 0;
    for (let i = 1; i < line; i += 1) {
        const next = source.indexOf('\n', index);
        if (next === -1) return index;
        index = next + 1;
    }
    return index;
}

// ---------------------------------------------------------------------------
// Public surface
// ---------------------------------------------------------------------------

export function extractSchemas(sourceDir) {
    const types = new Map();
    const problems = [];
    const files = readdirSync(sourceDir).filter((f) => f.endsWith('.swift')).sort();

    for (const file of files) {
        const path = join(sourceDir, file);
        const result = walkFile(file, readFileSync(path, 'utf8'));
        for (const [name, entry] of result.types) {
            if (types.has(name)) {
                const existing = types.get(name);
                existing.fields.push(...entry.fields);
                existing.cases.push(...entry.cases);
                existing.decodable = existing.decodable || entry.decodable;
            } else {
                types.set(name, entry);
            }
        }
        problems.push(...result.problems);
    }

    // Apply CodingKeys remapping to the JSON key of each field.
    for (const entry of types.values()) {
        for (const field of entry.fields) {
            field.key = entry.codingKeys.get(field.property) ?? field.property;
        }
    }

    return { types, problems };
}

// Resolves a parsed type against the collected declarations, so a validator can
// walk a document without knowing Swift. Returns null for a name it cannot
// place, which the caller is expected to report rather than ignore.
export function resolve(type, types, scopeName) {
    if (type.kind !== 'named') return type;

    if (PRIMITIVES[type.name]) return { kind: 'primitive', json: PRIMITIVES[type.name], swift: type.name };

    // Nested types are written unqualified inside their parent, so walk the
    // scope path outwards before falling back to a top-level name.
    const parts = scopeName ? scopeName.split('.') : [];
    for (let i = parts.length; i >= 0; i -= 1) {
        const candidate = [...parts.slice(0, i), type.name].join('.');
        if (types.has(candidate)) {
            const entry = types.get(candidate);
            if (entry.kind === 'enum' && entry.rawType === 'String' && entry.cases.length) {
                return {
                    kind: 'stringEnum',
                    name: entry.name,
                    values: entry.cases.map((c) => c.raw ?? c.name)
                };
            }
            if (entry.kind === 'struct' || entry.kind === 'class') {
                return { kind: 'object', name: entry.name };
            }
            return { kind: 'opaque', name: entry.name };
        }
    }

    return null;
}

export { PRIMITIVES };
