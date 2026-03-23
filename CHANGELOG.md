# Changelog

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
