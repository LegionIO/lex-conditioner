# lex-conditioner: Conditional Rule Engine for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that applies conditional statements to tasks within relationships. Evaluates JSON-based rules against task payloads to determine whether downstream tasks should execute, enabling branching logic in task chains.

**GitHub**: https://github.com/LegionIO/lex-conditioner
**License**: MIT
**Version**: 0.3.1

## Architecture

```
Legion::Extensions::Conditioner
├── Actors/
│   └── Conditioner       # Subscription actor consuming condition evaluation requests
├── Runners/
│   └── Conditioner       # Executes conditional logic against task payloads
│       ├── check         # Main entry point: evaluates conditions, dispatches or fails
│       └── send_task     # Routes to transformation or task queue based on result
├── Helpers/
│   ├── Condition         # Condition parsing (all/any nesting, dotted-path facts)
│   └── Comparator        # Comparison operator implementations (class methods)
└── Transport/
    ├── Exchanges/Task    # Publishes to the task exchange
    ├── Queues/Conditioner # Subscribes to condition evaluation queue
    └── Messages/Conditioner # Message format for condition requests
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/conditioner.rb` | Entry point, extension registration |
| `lib/legion/extensions/conditioner/runners/conditioner.rb` | Core condition evaluation logic |
| `lib/legion/extensions/conditioner/helpers/condition.rb` | Condition parsing and all/any evaluation |
| `lib/legion/extensions/conditioner/helpers/comparator.rb` | Comparison operator implementations |
| `lib/legion/extensions/conditioner/actors/conditioner.rb` | AMQP subscription actor |

## Condition Rule Format

Rules use `all`/`any` grouping with `fact`/`operator`/`value` entries. Facts use dot notation to address nested payload keys. Groups can be nested arbitrarily.

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
| `between` | Value within range (`value` is `[min, max]`) |
| `contains` | String contains substring |
| `starts_with` | String starts with prefix |
| `ends_with` | String ends with suffix |
| `matches` | String matches regex pattern |
| `in_set` | Value is in the given array |
| `not_in_set` | Value is not in the given array |
| `size_equal` | Collection or string size equals value |

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

## Condition Evaluation Logic

After evaluation, the runner routes based on outcome:
- Condition passes + transformation present: `transformation.queued` (routes to `task.subtask.transform`)
- Condition passes + routing key present: `task.queued` (routes to `runner_routing_key`)
- Condition passes but no routing info: `task.exception` (`send_task` raises `MissingArgument`)
- Condition fails: `conditioner.failed` (`send_task` is skipped)

Each evaluation also returns an explanation chain with per-rule results including actual values, for use by lex-synapse and standalone callers.

## Standalone Client

`Legion::Extensions::Conditioner::Client` includes the `Conditioner` runner. Instantiate without the full framework:

```ruby
require 'legion/extensions/conditioner/client'
client = Legion::Extensions::Conditioner::Client.new
result = client.evaluate(conditions: { all: [...] }, values: { ... })
result[:valid]        # => true/false
result[:explanation]  # => per-rule results with actual values
```

## Dependencies

| Gem | Purpose |
|-----|---------|
| `legion-exceptions` | Exception handling |

## Testing

```bash
bundle install
bundle exec rspec     # 140 examples, 0 failures
bundle exec rubocop   # 0 offenses
```

Spec files: `spec/legion/extensions/conditioner_spec.rb`, `spec/legion/extensions/comparator_spec.rb`, `spec/legion/extensions/condition_spec.rb`, `spec/legion/extensions/conditioner/runners/conditioner_spec.rb`

---

**Maintained By**: Matthew Iverson (@Esity)
