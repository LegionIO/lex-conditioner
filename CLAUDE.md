# lex-conditioner: Conditional Rule Engine for LegionIO

**Repository Level 3 Documentation**
- **Category**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that applies conditional statements to tasks within relationships. Evaluates rules against task payloads to determine whether downstream tasks should execute, enabling branching logic in task chains.

**License**: MIT

## Architecture

```
Legion::Extensions::Conditioner
├── Actors/
│   └── Conditioner       # Subscription actor consuming condition evaluation requests
├── Runners/
│   └── Conditioner       # Executes conditional logic against task payloads
├── Helpers/
│   ├── Condition         # Condition parsing and evaluation
│   └── Comparator        # Comparison operators (eq, gt, lt, contains, etc.)
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
| `lib/legion/extensions/conditioner/helpers/condition.rb` | Condition parsing |
| `lib/legion/extensions/conditioner/helpers/comparator.rb` | Comparison operator implementations |
| `lib/legion/extensions/conditioner/actors/conditioner.rb` | AMQP subscription actor |

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

---

**Maintained By**: Matthew Iverson (@Esity)
