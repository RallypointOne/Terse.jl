## Unreleased

## v0.2.1 - 2026-04-07

### Features

- Support bare parametric subtypes in `@types` hierarchies (e.g. `Multi{T}` as a child type)
- Support extending existing abstract types in `@types` hierarchies

## v0.2.0 - 2026-04-07

### Features

- Add autoshow support (automatic display of type hierarchies)
- Add auto-generated and user-defined docstrings to `@types` hierarchies

### Breaking

- Remove `@show_types` macro (replaced by autoshow)

## v0.1.0 - 2026-03-25

### Features

- Add `@qtype` macro for defining structs with positional constructors
- Add `@abstract` macro for defining abstract types
- Add `@types` macro for displaying type hierarchies
- Add `@mutable` per-subtype and `@const` field annotations for mutable struct support
- Add `@show_types` macro for displaying type hierarchies
- Support default field values and keyword argument constructors

### Documentation

- Add README with usage examples and comparison table against similar packages
- Add package comparison table with per-package code examples and source line counts

