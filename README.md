# lex-conditioner

Conditional rule engine for [LegionIO](https://github.com/LegionIO/LegionIO). Evaluates JSON-based rules against task payloads to determine whether downstream tasks should execute, enabling branching logic in task chains.

## Installation

```bash
gem install lex-conditioner
```

Or add to your Gemfile:

```ruby
gem 'lex-conditioner'
```

## Standalone Client

Use the conditioner without the full LegionIO framework:

```ruby
require 'legion/extensions/conditioner/client'

client = Legion::Extensions::Conditioner::Client.new

result = client.evaluate(
  conditions: { all: [
    { fact: 'response.code', operator: 'greater_or_equal', value: 200 },
    { fact: 'response.code', operator: 'less_than', value: 300 }
  ] },
  values: { response: { code: 200, body: 'OK' } }
)

result[:valid]       # => true
result[:explanation] # => { valid: true, group: :all, rules: [...] }
```

The explanation includes per-rule results with actual values:

```ruby
result[:explanation][:rules]
# => [
#   { fact: "response.code", operator: "greater_or_equal", value: 200, actual: 200, result: true },
#   { fact: "response.code", operator: "less_than", value: 300, actual: 200, result: true }
# ]
```

## Condition Format

Rules use `all`/`any` grouping with `fact`/`operator`/`value` entries. Facts use dot notation for nested keys.

```json
{
  "all": [
    { "fact": "response.code", "operator": "greater_or_equal", "value": 200 },
    { "any": [
      { "fact": "action", "operator": "equal", "value": "opened" },
      { "fact": "action", "operator": "equal", "value": "reopened" }
    ]}
  ]
}
```

## Operators

### Binary (require `fact` + `value`)

| Operator | Description |
|----------|-------------|
| `equal` | Exact equality |
| `not_equal` | Inequality |
| `greater_than` | Numeric greater than |
| `less_than` | Numeric less than |
| `greater_or_equal` | Numeric greater than or equal |
| `less_or_equal` | Numeric less than or equal |
| `between` | Value within range (value is `[min, max]`) |
| `contains` | String contains substring |
| `starts_with` | String starts with prefix |
| `ends_with` | String ends with suffix |
| `matches` | String matches regex pattern |
| `in_set` | Value is in the given array |
| `not_in_set` | Value is not in the given array |
| `size_equal` | Collection/string size equals value |

### Unary (require `fact` only)

| Operator | Description |
|----------|-------------|
| `nil` | Value is nil |
| `not_nil` | Value is not nil |
| `is_true` | Value is truthy |
| `is_false` | Value is falsy |
| `is_string` | Value is a String |
| `is_array` | Value is an Array |
| `is_integer` | Value is an Integer |
| `empty` | Value is nil or empty |
| `not_empty` | Value is present and not empty |

## Runners

### Conditioner

#### `check(conditions:, **payload)`

Evaluates conditions against the payload. Routes to transformation or task queue based on result:

- Condition passes + transformation present: routes to `task.subtask.transform`
- Condition passes + routing key present: routes to `runner_routing_key`
- Condition fails: `conditioner.failed`, no dispatch

## Transport

- **Exchange**: `task` (inherits from `Legion::Transport::Exchanges::Task`)
- **Queue**: `task.conditioner`
- **Routing keys**: `task.subtask`, `task.subtask.conditioner`

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (for AMQP actor mode)
- Standalone Client works without the framework

## License

MIT
