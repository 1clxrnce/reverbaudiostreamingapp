---
inclusion: auto
name: antislop
description: Anti-slop rules for UI design and coding. Prevents generic AI patterns in Flutter UI work.
---

# antislop

For UI design and Flutter screen work, follow the antislop rules from `.claude/skills/antislop/SKILL.md`.

Before starting UI work, ask the user when antislop applies:
1. **DURING** the project (planning & execution) - Apply rules while building
2. **AFTER** the project is finished - Audit existing code and create findings report

Key principles:
- Every visual decision needs a purpose (not just "it looks good")
- Mobile responsiveness is mandatory (R-03)
- No fake data, statistics, or testimonials (R-17, R-18)
- All interactive elements must work (R-26)
- UI must handle empty, loading, and error states (R-27)
- Keyboard accessibility required (R-32)
- No em dashes (—) in UI text (R-02)

See the full skill file for complete rules and patterns to avoid.
