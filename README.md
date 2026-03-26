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

To make the difference concrete, here is the same type hierarchy defined with each package — an abstract `Animal` with a `Cat` (default `lives=9`) and a `Dog`:

**Terse.jl — 4 lines**
```julia
@types Animal > (
    Cat(lives::Int = 9),
    Dog(name::String)
)
```

**[QuickTypes.jl](https://github.com/cstjean/QuickTypes.jl) — 3 lines** *(one type at a time; no hierarchy macro)*
```julia
abstract type Animal end
@qstruct Cat(lives::Int = 9) <: Animal
@qstruct Dog(name::String) <: Animal
```

**[Parameters.jl](https://github.com/mauro3/Parameters.jl) — 8 lines** *(block syntax; `@with_kw` only needed for types with defaults)*
```julia
abstract type Animal end
@with_kw struct Cat <: Animal
    lives::Int = 9
end
struct Dog <: Animal
    name::String
end
```

**`Base.@kwdef` — 8 lines** *(no extra dependencies; block syntax)*
```julia
abstract type Animal end
Base.@kwdef struct Cat <: Animal
    lives::Int = 9
end
struct Dog <: Animal
    name::String
end
```
