[![CI](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml)

# Terse.jl

Terse.jl provides the `@types` macro for defining type hierarchies concisely.

## Installation

```julia
using Pkg
Pkg.add("Terse")
```

## Usage

```julia
using Terse
```

**Standalone abstract type:**

```julia
@types Animal
```

**Abstract type with concrete subtypes:**

```julia
@types Animal > (
    Cat(lives::Int),
    Dog(name::String)
)
```

**Parametric types with bounded type parameters:**

```julia
@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Dog{T, S <: AbstractString}(name::S, family::T)
)
```

**Nested hierarchies:**

```julia
@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Invertebrate{T} > (
        Worm,
        Insect{T, I <: Integer}(legs::I, family::T)
    )
)
```

**Single concrete type (with optional supertype):**

```julia
@types Point(x::Float64, y::Float64)

@types Wrapper{T}(value::T) <: Animal{T}
```

## Comparison with Similar Packages

| Feature | `Base.@kwdef` | [QuickTypes.jl](https://github.com/cstjean/QuickTypes.jl) | [Parameters.jl](https://github.com/mauro3/Parameters.jl) | [ConcreteStructs.jl](https://github.com/SciML/ConcreteStructs.jl) | **Terse.jl** |
|---|:---:|:---:|:---:|:---:|:---:|
| Concise one-liner syntax | | ✓ | | ✓ | ✓ |
| Default field values | ✓ | ✓ | ✓ | | ✓ |
| Keyword constructors | ✓ | ✓ | ✓ | | ✓ |
| Mutable structs | ✓ | ✓ | | ✓ | ✓ |
| Parametric types | ✓ | ✓ | ✓ | ✓ (auto-inferred) | ✓ |
| Define abstract supertypes | | | | | ✓ |
| Full type hierarchy in one expression | | | | | ✓ |
| Nested abstract hierarchies | | | | | ✓ |

The key differentiator: `@types` lets you define an entire abstract type tree — with concrete leaf types, default values, and keyword constructors — in a single expression.
[QuickTypes.jl](https://github.com/cstjean/QuickTypes.jl) is the closest alternative for concise struct syntax but only defines one concrete type at a time with no hierarchy support.
[Parameters.jl](https://github.com/mauro3/Parameters.jl) focuses on keyword constructors and `@unpack` for numerical model parameters.
`Base.@kwdef` covers the common case (defaults + keyword constructors) with no extra dependencies.
