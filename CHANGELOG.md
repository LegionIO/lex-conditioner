# Changelog

## [0.3.1] - 2026-03-17

### Added
- `Condition#explain` method returns structured per-rule explanation with `fact`, `operator`, `value`, `actual`, and `result` for each rule
- `Condition#explain_test` evaluates all rules without short-circuiting, producing complete explanation trees
- `Condition#explain_rule` handles nested `all`/`any` groups recursively, and omits `value` key for unary operators
- Six new specs covering passing, failing, full evaluation (no short-circuit), nested groups, unary operators, and numeric operators

## [0.3.0] - 2026-03-17

### Added
- 14 new operators: `greater_than`, `less_than`, `greater_or_equal`, `less_or_equal`, `between` (numeric); `contains`, `starts_with`, `ends_with`, `matches` (string); `in_set`, `not_in_set`, `empty`, `not_empty`, `size_equal` (collection)
- Comprehensive comparator specs at `spec/legion/extensions/conditioner/helpers/comparator_spec.rb` covering all 23 operators
- Integration specs for new operator categories in condition_spec.rb

## [0.2.5] - 2026-03-13

### Added
- Initial release
