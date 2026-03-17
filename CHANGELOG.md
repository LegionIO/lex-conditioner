# Changelog

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
