# lex-conditioner

Conditional rule engine for [LegionIO](https://github.com/LegionIO/LegionIO). Evaluates JSON-based rules against task payloads to determine whether downstream tasks should execute, enabling branching logic in task chains.

This is a core LEX required for task relationship conditions.

## Installation

```bash
gem install lex-conditioner
```

## Usage

Conditions use a JSON rule format with `all`/`any` grouping and `fact`/`operator`/`value` comparisons:

```json
{
  "all": [
    { "fact": "pet.type", "value": "dog", "operator": "equal" },
    { "fact": "pet.hungry", "operator": "is_true" }
  ]
}
```

Conditions can be nested to create complex and/or scenarios:

```json
{
  "all": [
    { "any": [
      { "fact": "pet.type", "value": "dog", "operator": "equal" },
      { "fact": "pet.type", "value": "cat", "operator": "equal" }
    ]},
    { "fact": "pet.hungry", "operator": "is_true" }
  ]
}
```

### Operators

`equal`, `not_equal`, `greater_than`, `less_than`, `contains`, `is_true`, `is_false`, and more.

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework

## License

MIT
