## Unreleased

## v0.3.0 - 2026-08-12

### Breaking

- A bare name inside a `@types` hierarchy now declares an **abstract** type instead of a
  zero-field concrete struct, matching what a bare name already meant at the top level
  (`@types A`). Parentheses now consistently mark concrete types: use `Name()` or
  `Name{T}()` for a zero-field struct. A bare name still inherits the parent's type
  parameters when it declares none.

  To migrate, add parentheses to any bare subtype you construct:

  ```julia
  @types Shape > (Point, Line)      # before: two zero-field structs
  @types Shape > (Point(), Line())  # after
  ```

### Fixes

- A custom docstring placed before a nested `>` group or a bare name is no longer silently
  discarded; it is attached to the generated abstract type.
- The Docs workflow now deploys versioned docs on `v*` tag pushes. It previously listened
  only for published releases, but TagBot creates those with `GITHUB_TOKEN` and GitHub
  never starts a workflow run from a token-authored event, so no released version was ever
  published to `gh-pages`.

### Chores

- Sync CI and docs workflows with JuliaPackageTemplate: Julia `lts` in the test matrix, a
  docs render smoke test, and a single `CI success` aggregate check for branch protection.

## v0.2.4 - 2026-04-16

### Features

- Add computed constructors to `@types`: new syntax `Name(args...) = new(field::T = expr, ...)` lets struct fields differ from constructor arguments. Works standalone, with `<:` subtypes, in hierarchies, parametric types, and mutable variants.

## v0.2.3 - 2026-04-09

### Fixes

- Fix method overwrite error when using `@mutable` with `@const` fields and default values (keyword constructor now uses all-keyword args to avoid dispatch overlap)

## v0.2.2 - 2026-04-09

### Fixes

- Fix parametric types with default values or keyword arguments (outer constructors with `where` clauses for proper type inference)

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

