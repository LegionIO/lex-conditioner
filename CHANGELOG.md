# Changelog

## [0.4.0] - 2026-10-30

### Breaking changes

- Direct `Condition` and `Comparator` callers must use keyword arguments; there are no positional compatibility shims:

  | API | Before 0.4.0 | 0.4.0 |
  | --- | --- | --- |
  | Construct a condition | `Condition.new(options_hash)` | `Condition.new(conditions: rules, values: payload)` |
  | Binary comparison | `Comparator.equal?(fact, expected, values)` | `Comparator.equal?(fact: fact, value: expected, values: values)` |
  | Unary comparison | `Comparator.nil?(fact, values)` | `Comparator.nil?(fact: fact, values: values)` |

- `Condition.new` accepts only `conditions:` and `values:`; previously ignored extra options are no longer accepted. Validation and evaluation happen during construction. Handle `Legion::Extensions::Conditioner::ConfigurationError` from construction or `Client#evaluate`; unknown operators and malformed rules no longer silently pass.
- Condition groups require exactly one `all` or `any` Array. Every rule in that group is evaluated for a consistent decision/explanation, so malformed branches cannot hide behind short-circuit evaluation. Comparator predicates now return Booleans, not the original truthy fact value.
- The old public traversal helpers (`to_dotted_hash`, `validate_vars`, `validate_test`, `evaluate_rule`, `explain_test`, `explain_rule`) and operator-list constants (`BINARY_OPS`, `UNARY_OPS`, `UNARY_METHOD_MAP`) are removed. Use `Client#evaluate` or `Condition#valid?` and `Condition#explain`.
- Runner rejections now return `success: false`. A failed Conditioner condition returns `task.skipped` without dispatch; a missing downstream route or malformed rule returns a failed outcome rather than apparent success. Callers must not assume a returned Hash means acceptance.
- Rejected publication and destination persistence errors propagate. Successful forwarding does not complete the destination task. Auxiliary runners (`ConsentTiers`, `DomainClassifier`, `ConflictResolver`) return outcomes and leave invocation persistence to Core; direct calls no longer update a supplied task ID themselves.
- Optional operator permissions use a Boolean map at `extensions.conditioner.allowed_operators`, not an Array or truthy strings. Set supported operator names to `false` to deny them.

### Fixed
- Derive condition decisions and explanations from one boolean evaluation tree. Missing truthy facts fail, unknown/disabled operators and malformed rule trees raise a logged configuration error, and nested `all`/`any` groups agree with their explanations.
- Preserve array and hash facts while resolving dotted paths and array indices; collection operators now inspect the original container.
- Return explicit skipped/failed runner outcomes, reject missing downstream routes, and require accepted publication with `publish!`. A rejected publication remains retryable rather than becoming success.
- Restore normal ingress and Runner execution for the Conditioner actor. Pass destination identity as stage arguments so forwarding cannot complete the target; preserve lineage, authorization context, engine/schema options and business arguments through the Transformer handoff.
- Propagate Conditioner persistence errors without a second status write; auxiliary runners return outcomes and leave invocation persistence to Core.
- Evaluate competing conditions only after the primary rejects, preserving primary precedence when an unused alternative is malformed.
- Keep defaults in the root `conditioner.rb`, move `ConfigurationError` to `configuration_error.rb`, and restore fixed exchange, queue, and route names instead of configuring wire identities.

### Changed
- Add extension defaults for operator allowlists, consent tiers, and classification labels; use Transport-owned stable task statuses/routes and kwargs-only task updates. Operator policy stays local; publication policy belongs to Transport.
- Read standalone operator policy from the live canonical settings tree; rely on automatic framework settings injection for runners and actors without custom namespace overrides.
- Use real JSON, logging and settings libraries in specs; remove fail-open expectations, logging stubs and implementation-only tests.
- Require legion-settings 1.4.5 and legion-transport 1.4.32; remove unused cache, crypt and data dependencies. Standalone evaluation does not require LegionIO or a database.
- Update operator and stage documentation, guarded companion dependency paths and generated-artifact ignores.
- Use the canonical `Legion::Transport::Task::Protocol` namespace without execution-schema dependencies; preserve trusted internal admission and destination stage envelopes.
- Resolve development dependencies from existing workspace checkouts; use released Transport and retain only the coordinated Settings CI pin. Remove unnecessary Data installation and companion pins.

## [0.3.5] - 2026-04-13

### Added
- `:engine` to `send_task` whitelist — conditioner now forwards the engine field from the relationship hash to the downstream SubTask message

## [0.3.4] - 2026-03-30

### Added
- Specs for DomainClassifier (12 examples), ConsentTiers (11 examples), and ConflictResolver (17 examples)

### Fixed
- DomainClassifier now emits `conditioner.failed` status on invalid classifications
- ConflictResolver `valid:` field now reflects the actual resolution outcome
- Collapsed Lint/DuplicateBranch offense in ConflictResolver

## [0.3.3] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.3.2] - 2026-03-27

### Changed
- Replace prior pattern of `log.error '...had an exception'` followed by `log.warn e.message` and `log.warn e.backtrace` with a single `log.log_exception(e, component_type: :runner)` call for structured exception events
- Update runner spec to assert `log_exception` is called with an explicit logger double instead of `receive_message_chain`; update example description to match asserted behaviour

## [0.3.1] - 2026-03-22

### Changed
- Migrated to sub-gem helpers (Tier 1): added runtime dependencies on legion-cache >= 1.3.11, legion-crypt >= 1.4.9, legion-data >= 1.4.17, legion-json >= 1.2.1, legion-logging >= 1.3.2, legion-settings >= 1.3.14, legion-transport >= 1.3.9
- Replaced direct `Legion::Logging` calls in runner with `log` helper method via `Helpers::Lex` (includes `Legion::Logging::Helper`)
- Updated spec_helper to use real sub-gem helpers with `Helpers::Lex` module and actor stubs; removed inline Legion::Logging and Legion::JSON stubs
- Updated runner spec to remove framework stubs covered by spec_helper; added scoped `Helpers::Task`, `Transport::Messages::SubTask`, and `Exception::MissingArgument` stubs

## [0.3.0] - 2026-03-17

### Added
- 14 new operators: `greater_than`, `less_than`, `greater_or_equal`, `less_or_equal`, `between` (numeric); `contains`, `starts_with`, `ends_with`, `matches` (string); `in_set`, `not_in_set`, `empty`, `not_empty`, `size_equal` (collection) — 23 total
- Structured condition explanation via `Condition#explain` returning per-rule results with `fact`, `operator`, `value`, `actual`, and `result`
- Standalone `Client` class for framework-independent evaluation
- SimpleCov coverage reporting
- Modern packaging: grouped test dependencies, `require_relative` in gemspec, `rubocop-rspec`

### Fixed
- `Comparator.false?` returning `nil` instead of `false` for truthy values
- Typo `funciton_id` corrected to `function_id` in runner `send_task` whitelist

## [0.2.5] - 2026-03-13

### Added
- Initial release
