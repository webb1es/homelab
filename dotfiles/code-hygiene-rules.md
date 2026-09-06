# Code Hygiene Rules

## 0. Conflict Resolution

Priority: CORRECTNESS > MAINTAINABILITY > PERFORMANCE > BREVITY
On conflict, apply higher priority and flag: `⚖️ PRIORITY CONFLICT: [A] vs [B]. Applied [A].`

## 1. Scope

- Touch only requested files.
- Exception: §7 env var changes may also edit .env.example, deploy configs, README — no flag needed.
- Any other out-of-scope file needed: stop and flag:
  `🚫 DEPENDENCY REQUIRED: [files]. Need [changes]. Alternative? Approve?`

## 2. Behavior

- Preserve exact existing behavior.
- Flag: `⚠️ BEHAVIOR TRADE-OFF: [change] saves X LOC but alters [behavior]. Kept original.`

## 3. Code Smells

Flag with fix suggestion:

- Duplication: 3+ near-identical blocks (≥5 lines)
- Long function: >80 LOC
- Complex function: cyclomatic complexity >10 (linter-derived)
- Tight coupling: internal cross-module imports bypassing public interfaces
- Missing error handling on external calls (network/DB/filesystem)
- DB calls inside loops (N+1)
- Format: `⚠️ SMELL: [type] at [location]. Fix: [specific].`

## 4. Comments

- Forbidden: AI/conversation references, code restated in prose, TODO without issue link
- Allowed: business rule, security rationale, performance trade-off, legacy constraint, public API docs
- Format: `// Specific reason code can't express`
- Report: `Comments: [count]. Reason: [each]` or `No comments`

## 5. Quality

- Naming: function = verb phrase, variable = noun phrase
- One responsibility per function
- No dead code, no commented-out code
- Explainable in 30 seconds

## 6. Documentation

- Update README/API docs only for public behavior/endpoint/config changes
- Diff-sized updates only

## 7. Env Vars

- New/changed vars: update .env.example, all deploy configs, README in same commit
- Flag mismatch: `⚠️ ENV MISMATCH: [var] missing in [config]`

## 8. Stack Rules

### Go

- /cmd, /internal, /pkg layout
- Check every error, wrap with `fmt.Errorf("%w")`
- Pass `context.Context` through call chains
- DI over globals
- Exported (capitalized) only for actual public API

### Spring Boot

- `@Service`/`@Repository`/`@Controller` separation
- Constructor injection only
- `@ControllerAdvice` for all exception handling
- Bean Validation annotations on all DTOs
- Profile-specific config, no env branching in code

### React (Vite)

- Functional components + hooks only
- Extract shared logic into custom hooks
- `useMemo`/`useCallback` only for measured expensive work
- `React.memo` only on components proven to over-render
- Zustand/Context for cross-tree state, not prop drilling
- Route-level lazy loading (`React.lazy` + `Suspense`)

### Angular

- Standalone components only
- `inject()` over constructor DI
- `ChangeDetectionStrategy.OnPush` everywhere
- Signals for local state; `BehaviorSubject` only for streams needing operators
- Lazy-loaded feature routes
- `DestroyRef` (`takeUntilDestroyed`) for all subscriptions

### YAML

- No inline "why" comments — link docs instead
- Anchors/aliases to avoid duplication
- Validate against schema in CI
- No literal secrets — env var references only
- 2-space indentation, no tabs

## 9. Testing

- Coverage gates (CI-enforced, build fails below): core 80% | infra 60% | utils 90%
- Naming: `Test<Function>_<Scenario>_<Expected>`
- Patterns: table-driven (Go) | `@ParameterizedTest` (Spring) | Vitest+RTL (React) | TestBed+Cypress (Angular)
- Reject: fixed waits/`sleep()`, real external APIs/DB, tests asserting internals, >1% observed flake rate

## 10. Security

- Validate all external input at boundary (controller/handler layer) via validator libs
- JWT: validate signature, expiry, audience; reject on failure
- RBAC enforced at API layer, not just UI
- Never log secrets, tokens, or PII
- Secrets via env vars/secrets manager only
- Passwords: bcrypt or Argon2 only
- SQL: parameterized queries only
- Dependency bumps: check CVEs before merge (npm audit / go list -m -u / Snyk); flag high/critical CVE introductions

## 11. Performance

- API latency: P95 <200ms reads, <500ms writes
- Pagination: max 100 items/request, explicit cursor or offset
- Flag N+1: >2 DB calls per loop iteration
- Connection pool: 10-20
- Index columns used in WHERE/ORDER BY/JOIN
- Cache expensive/repeated computation with explicit TTL
- Flag identical DB query fired >5/min from same code path

## 12. Versioning

- API path: `/api/v1/resource`
- Breaking change: field/endpoint removal or rename, field type change, new required request field, changed response
  status codes for existing cases
- Breaking change → new version + 6-month deprecation notice on old one
- DB migrations: go-migrate (Go) / Flyway or Liquibase (Spring), forward-only, additive-only in same release (no
  drops/renames)

## 13. CI / Automation

- Pre-commit: linter, formatter, comment-pattern check, secrets scanner
- PR gate blocks merge on: coverage below §9 thresholds, lint failure, build failure, unresolved flag from this document

## 14. Commit Messages

Format: `<type>(<scope>): <description>`
Types: feat | fix | docs | style | refactor | test | chore

- State what changed, not why
- No subjective words: improve, better, clean up, enhance, simplify
- Scope = affected module/directory name, lowercase, no spaces
- Body only when subject line can't convey needed context
- Never commit or push — message only

Good: `fix(auth): prevent null error on token refresh`
Good: `feat(api): add pagination to /users endpoint`
Bad: `fix(auth): make token handling more robust to avoid errors`
Bad: `feat(api): improve the users endpoint with better pagination`

## Pre-Commit Checklist

- [ ] Only requested files changed (or flagged, §1)
- [ ] Existing behavior preserved (or flagged, §2)
- [ ] No smells, or flagged (§3)
- [ ] No forbidden comments (§4)
- [ ] Comments justified (§4)
- [ ] Naming clear (§5)
- [ ] Docs updated if user-facing (§6)
- [ ] Env vars consistent across all configs (§7)
- [ ] Stack conventions followed (§8)
- [ ] Coverage thresholds met, tests pass (§9)
- [ ] Security checklist clean, deps scanned (§10)
- [ ] Performance not degraded >10% (§11)
- [ ] Migrations included if schema changed (§12)
- [ ] No secrets exposed
- [ ] PR explainable in 30 seconds
- [ ] Commit message follows §14 format

## Forbidden Comment Patterns

`// As discussed...` `// We decided to...` `// This handles...` `// Set the value...` `// This is for...`
`// This helps us...` `// AI note: ...` `// Prompt: ...` `// Per our conversation...` `// The agent should...`
`// TODO:` (without issue link)

## Allowed Comment Patterns

`// O(n²) but n<100, alternatives slower due to setup cost`
`// Must keep ordering for legacy integration with [system]`
`// Security: timing attack mitigation via constant-time comparison`
`// Business rule: [external requirement] forces this order`
`// DEP: [file] needs [change] due to [reason]`
