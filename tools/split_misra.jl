#!/usr/bin/env julia
# Split 'MISRA C 2012 Guideline.txt' into one AI-readable Markdown file per guideline,
# grouped into mandatory/ required/ advisory/ folders.
#
# Usage: julia tools/split_misra.jl "MISRA C 2012 Guideline.txt" misra_rules
#
# Uses only the Julia standard library (no packages to install).

const SRC = ARGS[1]
const OUT = ARGS[2]

# normalise CRLF / CR line endings (the source file uses CRLF)
const raw = split(replace(read(SRC, String), "\r\n" => "\n", "\r" => "\n"), "\n")

# Replace every match of `rx` in `s` with `f(m)` (a RegexMatch -> String function).
function subfn(f, rx::Regex, s::AbstractString)
    io = IOBuffer()
    last = 1
    for m in eachmatch(rx, s)
        print(io, SubString(s, last, prevind(s, m.offset)))
        print(io, f(m))
        last = m.offset + ncodeunits(m.match)
    end
    print(io, SubString(s, last))
    return String(take!(io))
end

# Insertion-ordered counter (Python's collections.Counter, as far as we need it).
mutable struct Counter
    counts::Dict{String,Int}
    order::Vector{String}
end
Counter() = Counter(Dict{String,Int}(), String[])
Base.getindex(c::Counter, k) = get(c.counts, k, 0)
function inc!(c::Counter, k)
    haskey(c.counts, k) || push!(c.order, k)
    c.counts[k] = c[k] + 1
end
total(c::Counter) = sum(values(c.counts); init=0)
most_common(c::Counter) = sort([(k, c.counts[k]) for k in c.order]; by=x -> -x[2])  # stable

# ---------------------------------------------------------------- text cleanup
const LIG_KEEP = Set(["off", "staff", "stuff", "cliff", "buff"])
const LIG_RE = r"\b([A-Za-z]*?)(ffi|ffl|fi|fl|ff)[ \t]+([a-z]+)"

function fix_ligatures(s)
    rep(m) = lowercase(m[1] * m[2]) in LIG_KEEP ? m.match : m[1] * m[2] * m[3]
    prev = nothing
    while prev != s
        prev, s = s, subfn(rep, LIG_RE, s)
    end
    return String(s)
end

const vocab = Counter()
for l in raw, m in eachmatch(r"[A-Za-z]+", fix_ligatures(l))
    inc!(vocab, lowercase(m.match))
end
const SHORT_WORDS = Set(["a", "i", "an", "as", "at", "be", "by", "do", "if", "in", "is", "it",
                         "no", "of", "on", "or", "so", "to", "up", "we", "c"])
const join_log = Counter()

function is_word(w)
    w = lowercase(w)
    length(w) <= 2 && return w in SHORT_WORDS
    return vocab[w] >= 2
end

const PIECE_RE = r"( {1,2})"
const WORD_RE = r"^(.*?[^A-Za-z0-9_.']|)([A-Za-z]+)$"   # trailing word of a piece
const HEAD_RE = r"^([A-Za-z]+)(?![A-Za-z0-9_(\[])(.*)$"  # leading word of a piece

function should_join(a, b)
    jc = vocab[lowercase(a * b)]
    jc < 2 && return false
    if is_word(a) && is_word(b)
        # both halves look like words, but may just be repeated fragments
        # ("guidelin e", "ru les"): join only if the whole word clearly dominates
        if (lowercase(a) in SHORT_WORDS || lowercase(b) in SHORT_WORDS ||
            jc < 3 * max(vocab[lowercase(a)], vocab[lowercase(b)]))
            return false
        end
    end
    # "return s", "of f", "e type": a real word next to a lone letter is only
    # joined when the joined form is the more common word in the document.
    for (w, other) in ((a, b), (b, a))
        if is_word(w) && length(other) == 1 && jc <= vocab[lowercase(w)]
            return false
        end
    end
    return true
end

const C_KEYWORDS = Set(["return", "sizeof", "case", "goto", "int", "char", "long", "short",
                        "float", "double", "void", "struct", "union", "enum", "const", "static"])

# 'comment s' -> 'comments' (plural 's' detached at a word end).
is_plural_split(a, b, rest) =
    b == "s" && rest in ("", ",", ".", ":") && length(a) >= 4 &&
    !(lowercase(a) in C_KEYWORDS) && vocab[lowercase(a * b)] >= 2

# Python-style re.split with a capturing group: [piece, sep, piece, sep, ...]
function split_keep(rx::Regex, s::AbstractString)
    parts = String[]
    last = 1
    for m in eachmatch(rx, s)
        push!(parts, SubString(s, last, prevind(s, m.offset)), m.match)
        last = m.offset + ncodeunits(m.match)
    end
    push!(parts, SubString(s, last))
    return parts
end

# Re-join words broken by PDF extraction, e.g. 's hould' -> 'should'.
function fix_splits(s)
    parts = split_keep(PIECE_RE, s)
    i = 1
    while i + 2 <= length(parts)
        ma, mb = match(WORD_RE, parts[i]), match(HEAD_RE, parts[i+2])
        if ma !== nothing && mb !== nothing &&
           (should_join(ma[2], mb[1]) || is_plural_split(ma[2], mb[1], mb[2]))
            inc!(join_log, "$(ma[2]) $(mb[1]) -> $(ma[2] * mb[1])")
            splice!(parts, i:i+2, [parts[i] * parts[i+2]])
            continue  # re-check the merged piece against the next one
        end
        i += 2
    end
    return join(parts)
end

function clean(s)
    s = fix_splits(fix_ligatures(s))
    s = replace(s, ' ' => ' ')
    return replace(s, r"[ \t]+$" => "")
end

function clean_inline(s)
    s = strip(replace(clean(s), r"\s+" => " "))
    return replace(s, r"([a-z])- ([a-z])" => s"\1-\2")
end

collapse(s) = strip(replace(s, r"\s+" => " "))

# ---------------------------------------------------------------- locate guidelines
const HDR_RE = r"^\s*(Rule|Dir)\s+(\d+)\.(\d+)\s*\t+\s*(.+)$"
const CAT_RE = r"^\s*Category\s+(.*)$"
const SECTION_RE = r"^\s*(8\.\d+|7\.\d+|9)\s+[A-Z]"  # chapter sections bound a rule
const APPX_A = findfirst(l -> startswith(l, "Appendix A Summary"), raw)

const cat_lines = [i for i in 1:APPX_A-1 if occursin(CAT_RE, raw[i])]
const headers = Dict(i => match(HDR_RE, raw[i]) for i in 1:APPX_A-1 if occursin(HDR_RE, raw[i]))

mutable struct Entry
    start::Int
    kind::Union{Nothing,String}
    major::Int
    minor::Int
    title::String
    stray_line::Int  # 0 = none
end

entries = Entry[]
used_headers = Set{Int}()
for c in cat_lines
    hit = findfirst(j -> haskey(headers, j), c-1:-1:max(c - 5, 1))
    if hit !== nothing
        j = (c-1:-1:max(c - 5, 1))[hit]
        m = headers[j]
        push!(used_headers, j)
        push!(entries, Entry(j, m[1], parse(Int, m[2]), parse(Int, m[3]), m[4], 0))
    else
        push!(entries, Entry(c, nothing, 0, 0, "", 0))  # orphan, resolved below
    end
end

# Orphan Category lines (header displaced by PDF extraction, e.g. Rule 17.3):
# match them to a guideline header line that has no Category of its own.
stray = sort([i for i in keys(headers) if !(i in used_headers) && i > cat_lines[1]])
for e in entries
    e.kind === nothing || continue
    c = e.start
    s = stray[findfirst(x -> c < x < c + 40, stray)]
    m = headers[s]
    start = startswith(lstrip(raw[c-1]), r"C90|C99|\[") ? c - 1 : c
    e.start, e.kind, e.major, e.minor, e.title, e.stray_line =
        start, m[1], parse(Int, m[2]), parse(Int, m[3]), m[4], s
end
sort!(entries; by=e -> e.start)

const section_starts = [i for i in 1:APPX_A-1 if occursin(SECTION_RE, raw[i])]

function section_title_for(line)
    best = findlast(s -> s <= line, section_starts)
    return best === nothing ? "" : clean_inline(raw[section_starts[best]])
end

# ---------------------------------------------------------------- parse each guideline
const SUBHEAD = Dict(
    "amplification" => "Amplification",
    "rationale" => "Rationale",
    "exception" => "Exception",
    "exceptions" => "Exception",
    "example" => "Example",
    "examples" => "Example",
    "see also" => "See also",
)
const IDREF_RE = r"\b(Rule|Dir)\s*(\d+)\s*\.\s*(\d+)"
const APPLIES_RE = r"Applies\s+to\s+(.*)$"

struct Guideline
    id::String
    type::String
    number::Tuple{Int,Int}
    title::String
    category::Union{Nothing,String}
    analysis::Union{Nothing,String}
    applies_to::Union{Nothing,String}
    chapter_section::String
    source_references::Vector{String}
    see_also::Vector{String}
    sections::Vector{Pair{String,Vector{String}}}  # in document order
end

# Split "X Applies to Y" into ("X", "Y"); "Applies to" may be absent.
function split_applies(rest)
    ma = match(APPLIES_RE, rest)
    ma === nothing && return rest, nothing
    return SubString(rest, 1, prevind(rest, ma.offset)), collapse(ma[1])
end

guidelines = Guideline[]
for (k, e) in enumerate(entries)
    stop = k < length(entries) ? entries[k+1].start : APPX_A  # exclusive
    nxt = findfirst(s -> e.start < s < stop, section_starts)
    nxt === nothing || (stop = section_starts[nxt])
    body = [raw[idx] for idx in e.start:stop-1
            if idx != e.stray_line && !(idx == e.start && occursin(HDR_RE, raw[idx]))]

    category = analysis = applies_to = nothing
    refs = String[]
    sections = Dict{String,Vector{String}}()
    order = String[]
    cur = nothing
    for l in body
        t = strip(clean(l))
        isempty(t) && continue
        if cur === nothing
            m = match(CAT_RE, t)
            if m !== nothing
                rest, a = split_applies(m[1])
                a === nothing || (applies_to = a)
                category = uppercasefirst(lowercase(replace(rest, r"\s+" => "")))
                continue
            end
            m = match(r"^Analysis\s+(.*)$", t)
            if m !== nothing
                rest, a = split_applies(m[1])
                a === nothing || (applies_to = a)
                analysis = collapse(rest)
                continue
            end
            m = match(r"^Applies\s+to\s+(.*)$", t)
            if m !== nothing
                applies_to = collapse(m[1])
                continue
            end
            if category === nothing || occursin(r"^(\[|C90|C99)", t)
                push!(refs, replace(t, r"\s+" => " "))
                continue
            end
        end
        key = get(SUBHEAD, rstrip(lowercase(t), ':'), nothing)
        if key !== nothing
            cur = key
            if !haskey(sections, key)
                sections[key] = String[]
                push!(order, key)
            end
            continue
        end
        # "...text. See also" on one line
        m = match(r"^(.*\S)\s+See also$", t)
        if m !== nothing
            sec = something(cur, "Rationale")
            push!(get!(sections, sec, String[]), m[1])
            sec in order || push!(order, sec)
            cur = "See also"
            get!(sections, cur, String[])
            push!(order, cur)
            continue
        end
        if cur === nothing
            cur = "Rationale"
            sections[cur] = String[]
            push!(order, cur)
        end
        push!(sections[cur], rstrip(clean(l)))
    end

    see_also = String[]
    if haskey(sections, "See also")
        txt = join(pop!(sections, "See also"), " ")
        deleteat!(order, findfirst(==("See also"), order))
        for r in eachmatch(IDREF_RE, txt)
            ref = "$(r[1]) $(r[2]).$(r[3])"
            ref in see_also || push!(see_also, ref)
        end
    end
    push!(guidelines, Guideline(
        "$(e.kind) $(e.major).$(e.minor)",
        e.kind == "Dir" ? "directive" : "rule",
        (e.major, e.minor),
        clean_inline(e.title),
        category, analysis, applies_to,
        section_title_for(e.start),
        refs, see_also,
        [s => sections[s] for s in order],
    ))
end

# ---------------------------------------------------------------- sanity checks
const VALID = ["Mandatory", "Required", "Advisory"]
bad = [g.id for g in guidelines if !(g.category in VALID)]
isempty(bad) || error("unknown category: $bad")
allunique(g.id for g in guidelines) || error("duplicate ids")

# ---------------------------------------------------------------- write output
const CAT_SEMANTICS = Dict(
    "Mandatory" => "Code shall comply with this guideline. Deviation is NOT permitted.",
    "Required" => "Code shall comply with this guideline unless a formal, recorded deviation exists.",
    "Advisory" => "Recommended practice. Follow where reasonably practical; non-compliance should be justified.",
)

pad2(n) = lpad(string(n), 2, '0')
fname(g) = "$(g.type == "directive" ? "dir" : "rule")_$(pad2(g.number[1]))_$(pad2(g.number[2])).md"

# Minimal JSON encoder matching Python's json.dumps(..., ensure_ascii=False).
function json_str(s::AbstractString)
    io = IOBuffer()
    print(io, '"')
    for c in s
        if c == '"'
            print(io, "\\\"")
        elseif c == '\\'
            print(io, "\\\\")
        elseif c == '\n'
            print(io, "\\n")
        elseif c == '\r'
            print(io, "\\r")
        elseif c == '\t'
            print(io, "\\t")
        elseif c == '\b'
            print(io, "\\b")
        elseif c == '\f'
            print(io, "\\f")
        elseif c < ' '
            print(io, "\\u", lpad(string(UInt32(c), base=16), 4, '0'))
        else
            print(io, c)
        end
    end
    print(io, '"')
    return String(take!(io))
end
json(::Nothing; kw...) = "null"
json(s::AbstractString; kw...) = json_str(s)
json(n::Integer; kw...) = string(n)
function json(v::AbstractVector; indent=nothing, level=0)
    isempty(v) && return "[]"
    indent === nothing && return "[" * join((json(x) for x in v), ", ") * "]"
    pad, inner = " "^(indent * level), " "^(indent * (level + 1))
    items = (inner * json(x; indent, level=level + 1) for x in v)
    return "[\n" * join(items, ",\n") * "\n" * pad * "]"
end
function json(d::AbstractVector{<:Pair}; indent=nothing, level=0)  # ordered object
    isempty(d) && return "{}"
    if indent === nothing
        return "{" * join(("$(json_str(k)): $(json(v))" for (k, v) in d), ", ") * "}"
    end
    pad, inner = " "^(indent * level), " "^(indent * (level + 1))
    items = (inner * json_str(k) * ": " * json(v; indent, level=level + 1) for (k, v) in d)
    return "{\n" * join(items, ",\n") * "\n" * pad * "}"
end

function render_section(name, lines)
    text = strip(join(lines, "\n"), '\n')
    name == "Example" && return "## Example\n\n```c\n$text\n```\n"
    # normalise bullets for prose sections
    text = replace(text, r"^\s*[•●]\s*"m => "- ")
    text = replace(text, r"^\*\t"m => "- ")
    return "## $name\n\n$text\n"
end

for c in VALID
    mkpath(joinpath(OUT, lowercase(c)))
end

index = Vector{Pair{String,Any}}[]
for g in guidelines
    rel = "$(lowercase(g.category))/$(fname(g))"
    fm = [
        "---",
        "id: $(json(g.id))",
        "type: $(g.type)",
        "category: $(g.category)",
        "title: $(json(g.title))",
        g.analysis === nothing || isempty(g.analysis) ? "analysis: null" : "analysis: $(json(g.analysis))",
        "applies_to: $(json(g.applies_to))",
        "chapter_section: $(json(g.chapter_section))",
        "see_also: $(json(g.see_also))",
        "source_references: $(json(g.source_references))",
        "---",
        "",
        "# $(g.id) — $(g.title)",
        "",
        "**Category:** $(g.category) — $(CAT_SEMANTICS[g.category])",
    ]
    g.analysis === nothing || isempty(g.analysis) || push!(fm, "**Analysis:** $(g.analysis)  ")
    push!(fm, "**Applies to:** $(something(g.applies_to, "None"))")
    push!(fm, "")
    parts = [join(fm, "\n")]
    for (name, lines) in g.sections
        any(l -> !isempty(strip(l)), lines) && push!(parts, render_section(name, lines))
    end
    if !isempty(g.see_also)
        push!(parts, "## See also\n\n" * join(("- $s" for s in g.see_also), "\n") * "\n")
    end
    write(joinpath(OUT, rel), join(parts, "\n"))
    push!(index, Pair{String,Any}[
        "id" => g.id, "type" => g.type, "category" => g.category, "title" => g.title,
        "analysis" => g.analysis, "applies_to" => g.applies_to, "see_also" => g.see_also,
        "file" => rel,
    ])
end

write(joinpath(OUT, "index.json"), json(index; indent=2) * "\n")

# ---------------------------------------------------------------- concept files
find_line(pattern, after=1) = findfirst(i -> i >= after && occursin(pattern, raw[i]), eachindex(raw))

# Lines a..b-1 (end-exclusive, like a Python slice).
block(a, b) = strip(join((clean(l) for l in raw[a:b-1]), "\n")) * "\n"

concepts = joinpath(OUT, "concepts")
mkpath(concepts)
s810 = find_line(r"^8\.10 The essential type model")
r101 = find_line(r"^Rule 10\.1\s", s810)
s8103 = find_line(r"^8\.10\.3 ")
r106 = find_line(r"^Rule 10\.6\s", s8103)
apx_c = find_line(r"^\s*Appendix C\s")
apx_e = find_line(r"^\s*Appendix E\s")
s811 = find_line(r"^8\.11 ")
r111 = find_line(r"^Rule 11\.1\s", s811)
s814 = find_line(r"^8\.14 ")
r141 = find_line(r"^Rule 14\.1\s", s814)
glossary = find_line(r"^\s*Appendix J\s")

const CONCEPTS = [
    "essential_type_model.md" => (
        "Essential type model (used by Rules 10.x, 14.x, 16.7, 20.8 and others)",
        [(s810, r101), (s8103, r106), (apx_c, apx_e)]),
    "pointer_type_conversions.md" => (
        "Pointer type conversions (background for Rules 11.x)", [(s811, r111)]),
    "control_statement_expressions.md" => (
        "Control statement expressions and loop counters (background for Rules 14.x)",
        [(s814, r141)]),
    "glossary.md" => ("Glossary (Appendix J)", [(glossary + 1, length(raw) + 1)]),
]
for (name, (title, spans)) in CONCEPTS
    body = join((block(a, b) for (a, b) in spans), "\n\n")
    write(joinpath(concepts, name), "# $title\n\n$body")
end

counts = Counter()
foreach(g -> inc!(counts, g.category), guidelines)
println("guidelines: ", length(guidelines), " ",
        join(("$k: $(counts[k])" for k in counts.order), ", "))
println("joins: ", total(join_log))
for (k, v) in most_common(join_log)
    println("  ", lpad(v, 4), "  ", k)
end
