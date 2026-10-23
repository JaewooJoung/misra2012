---
name: misra-codeguard-reviewer
description: Analyzes C source code for MISRA C:2012 guideline violations and suggests refactored safe code.
---

## Rule references

The MISRA C:2012 guidelines are in `misra_rules/` (see `misra_rules/README.md`):

- `misra_rules/index.json` – all 159 guidelines with id, category, title and file path.
- `misra_rules/mandatory/`, `misra_rules/required/`, `misra_rules/advisory/` – one Markdown file per guideline.
- `misra_rules/concepts/` – shared definitions (essential type model, loop counter, glossary).

When reviewing code:

1. Load `index.json` and select the guidelines relevant to the code under review.
2. Read each selected rule file; use its Amplification, Exception and Example sections to decide compliance.
3. Report each violation with the guideline id, category and location, then propose a compliant rewrite.
   Mandatory and Required violations are errors; Advisory violations are warnings.
