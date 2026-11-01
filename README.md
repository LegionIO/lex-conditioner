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

Each group has exactly one key (`all` or `any`) containing an array. Rules require a nonempty string `fact`, a supported `operator`, and a `value` for binary operators only. Unknown keys, malformed groups, unknown/disabled operators, invalid JSON and invalid comparisons raise a logged `Legion::Extensions::Conditioner::ConfigurationError`; they never permit dispatch. Every rule is evaluated, including branches that ordinary short-circuit evaluation would skip.

Decisions and explanations come from the same boolean tree. Empty `all` is true; empty `any` is false. `is_true` and `is_false` use Ruby truthiness: only `nil` and `false` are falsy, and a missing fact is `nil`. Arrays and hashes remain intact for equality, type, emptiness and size checks. `items.0.active` addresses an array child without discarding the `items` array. Facts can use symbol or string hash keys.

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
- Condition fails: `{ success: false, valid: false, status: 'task.skipped', explanation: ... }`, no dispatch
- Condition passes without a usable target route: explicit failed outcome with `conditioner.failed`, no dispatch
- Invalid rule/configuration: explicit failed outcome; comparison/runtime errors are never treated as success

Successful results describe forwarding (`task.queued` or `transformer.queued`), **not completion of the eventual target task**. The subscription actor uses normal ingress and `Legion::Runner.run`, carrying the destination envelope as business arguments rather than the stage's execution identity. Core claims and completes the destination only when its own runner executes. Successful handoffs use confirmed, mandatory `publish!`; rejected/unroutable publication raises `Legion::Transport::PublishRejected` for subscription retry and is not recorded as a completed or failed target execution.

The forwarding envelope retains canonical task/parent/master/chain identity, relationship/function identity, principal/worker/tenant context, schedule/occurrence identity, deadline/depth, correlation/message identity, engine/schema/options and business `args`/`kwargs`/`function_args`/`payload`/`results`. Consumed `conditions` are not forwarded back into the conditioner. LegionIO 1.9.53 provides the required stage actor and kwargs-only task status integration; use the coordinated legion-settings 1.4.5 and legion-transport 1.4.32 releases.

The condition-stage subscription explicitly declares `trusted_internal true` for Core admission. This is an actor-side trust decision, never a claim inferred from payload `source`, roles or principal strings. Restrict publishing to the internal task exchange with broker permissions; preserved user identity remains authorization/audit context and does not grant administrator privileges.

### Additional runners

| Runner | Function | Behavior |
|--------|----------|----------|
| `DomainClassifier` | `classify(conditions:, domain: nil, **payload)` | Returns a requested/default domain on acceptance; configured unclassified label otherwise |
| `ConsentTiers` | `evaluate(conditions:, tier: nil, **payload)` | Grants a configured tier only on acceptance; absent/unknown tier uses the first configured tier |
| `ConflictResolver` | `resolve(conditions:, competing_conditions: nil, **payload)` | Prefers a matching primary, then secondary, otherwise none; malformed alternatives fail closed |

All runner functions return Hash outcomes. Rejections and exceptions carry `success: false`; auxiliary runners use Transport's canonical task statuses rather than inventing local lifecycle spellings.

## Configuration

Extension settings live at `extensions.conditioner`. Framework runners and actors use their automatically injected `settings` helper; standalone evaluation and transport objects read `Legion::Settings[:extensions][:conditioner]` directly. Defaults are registered at startup, while every new evaluation reads the live user policy without a cached settings tree:

| Setting | Default | Purpose |
|---------|---------|---------|
| `allowed_operators` | Boolean map with every supported operator enabled | Set an operator to `false` to explicitly disable it; unknown names/nonboolean permissions are rejected |
| `consent_tiers` | `['tier1', 'tier2', 'tier3']` | Ordered tiers, least privilege first |
| `default_domain` / `unclassified_domain` | `'default'` / `'unclassified'` | Domain classification labels |
| `resolutions` | `{primary: 'primary', secondary: 'secondary', none: 'none'}` | Resolution labels, independent of acceptance decisions |
| `transport.exchange` / `transport.queue` | `'task'` / `'task.conditioner'` | Exchange and queue declarations |
| `transport.binding_queue` / `transport.legacy_route` | `'conditioner'` / `'task.subtask'` | Existing queue binding and compatibility input route |
| `transport.success_route` | `'task.conditioner.succeeded'` | Extension success-message route |

Pipeline statuses, canonical metadata fields and conditioner/transform routes are immutable wire identities owned by `Legion::Transport::TaskProtocol`, not process-local settings. Operator policy remains dynamic under `extensions.conditioner`; strict publication policy belongs to `transport.task_publication`. Local overrides cannot rename a downstream stage or reinterpret its status. No database/cache/crypt dependency or service is required for standalone evaluation; AMQP actor dispatch requires a functioning transport.

Example operator restriction:

```ruby
Legion::Settings[:extensions][:conditioner][:allowed_operators][:matches] = false
```

Permissions are a boolean map, not an additive array: `false` survives default registration and nested settings overlays, while omitted entries retain defaults. Array-form operator policies are not accepted.

## Transport

- **Exchange**: `task` (inherits from `Legion::Transport::Exchanges::Task`)
- **Queue**: `task.conditioner`
- **Routing keys**: `task.subtask`, `task.subtask.conditioner`

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework (for AMQP actor mode)
- Standalone Client requires only installed gem dependencies, without loading LegionIO or connecting to a database/broker

## License

MIT
