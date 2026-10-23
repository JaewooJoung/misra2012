# MISRA C:2012 rule set (AI-readable)

Generated from `MISRA C 2012 Guideline.txt` by `tools/split_misra.jl` (Julia, standard library only).
Re-generate with:

```sh
julia tools/split_misra.jl "MISRA C 2012 Guideline.txt" misra_rules
```

One file per guideline (16 directives + 143 rules = 159), grouped by category:

| Folder        | Count | Meaning for the checker                                                        |
|---------------|------:|--------------------------------------------------------------------------------|
| `mandatory/`  |    10 | Must always be satisfied. Deviation is **not** permitted. Report as error.      |
| `required/`   |   110 | Must be satisfied unless a formal, recorded deviation exists. Report as error.  |
| `advisory/`   |    39 | Recommended practice. Report as warning; non-compliance should be justified.    |
| `concepts/`   |     – | Shared definitions referenced by many rules (essential types, loop counter, glossary). |

`index.json` lists every guideline with `id`, `type`, `category`, `title`, `analysis`,
`applies_to`, `see_also` and `file` — load it first to pick the rules to check.

## File layout

File name: `rule_<chapter>_<number>.md` or `dir_<chapter>_<number>.md` (zero-padded,
e.g. `required/rule_10_01.md` = Rule 10.1).

Each file has YAML front matter followed by Markdown sections:

```yaml
---
id: "Rule 10.1"
type: rule                # rule | directive
category: Required        # Mandatory | Required | Advisory
title: "Operands shall not be of an inappropriate essential type"
analysis: "Decidable, Single Translation Unit"   # null for directives
applies_to: "C90, C99"
chapter_section: "8.10 The essential type model"
see_also: ["Rule 10.2"]
source_references: [...]  # C90/C99 undefined/unspecified behaviour references
---
```

Sections (present only when the guideline has them):

- `## Amplification` – precise statement of what the rule requires
- `## Rationale` – why the rule exists
- `## Exception` – cases that are explicitly allowed
- `## Example` – compliant / non-compliant code (`/* Compliant */`, `/* Non-compliant */`)
- `## See also` – related guidelines

`analysis` tells the checker how the rule can be verified:
*Decidable* rules can be checked mechanically; *Undecidable* rules need judgement.
*Single Translation Unit* rules can be checked per file; *System* rules need the whole project.

Note: the source text came from a PDF extraction, so the code inside `## Example`
blocks keeps its original (sometimes flattened) line breaks.
