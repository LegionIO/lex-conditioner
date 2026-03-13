# lex-conditioner: Conditional Rule Engine for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that applies conditional statements to tasks within relationships. Evaluates JSON-based rules against task payloads to determine whether downstream tasks should execute, enabling branching logic in task chains.

**GitHub**: https://github.com/LegionIO/lex-conditioner
**License**: MIT
**Version**: 0.2.5

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

Rules use `all`/`any` grouping with `fact`/`operator`/`value` entries. Facts use dot notation to address nested payload keys.

### Operators

**Binary** (require `fact` + `value`):
- `equal` - exact equality
- `not_equal` - inequality

**Unary** (require `fact` only):
- `nil` - value is nil
- `not_nil` - value is not nil
- `is_true` - value is truthy
- `is_false` - value is falsy
- `is_string` - value is a String
- `is_array` - value is an Array
- `is_integer` - value is an Integer

## Condition Evaluation Logic

After evaluation, the runner sets task status based on outcome:
- Condition passes + transformation present: `transformation.queued`
- Condition passes + routing key present: `task.queued`
- Condition passes but no routing info: `task.exception`
- Condition fails: `conditioner.failed`

## Dependencies

| Gem | Purpose |
|-----|---------|
| `legion-exceptions` | Exception handling |

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

Spec files: `spec/legion/extensions/conditioner_spec.rb`, `spec/legion/extensions/comparator_spec.rb`, `spec/legion/extensions/condition_spec.rb`

---

**Maintained By**: Matthew Iverson (@Esity)
