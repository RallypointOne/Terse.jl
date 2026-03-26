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

**Per-type mutability and const fields:**

Use `@mutable` to mark individual subtypes as mutable, and `@const(field)` to freeze
specific fields within a mutable type (requires Julia 1.8+, explicit parentheses required):

```julia
@types Animal > (
    Cat(lives::Int = 9),
    @mutable Dog(@const(name::String), legs::Int)
)

d = Dog("Rex", 4)
d.legs = 3        # ok — legs is mutable
d.name = "Spot"   # error — name is const
```

## Comparison with Similar Packages

| Feature | `Base.@kwdef` | [QuickTypes.jl](https://github.com/cstjean/QuickTypes.jl) | [Parameters.jl](https://github.com/mauro3/Parameters.jl) | [ConcreteStructs.jl](https://github.com/SciML/ConcreteStructs.jl) | **Terse.jl** |
|---|:---:|:---:|:---:|:---:|:---:|
| Concise one-liner syntax | | ✓ | | ✓ | ✓ |
| Default field values | ✓ | ✓ | ✓ | | ✓ |
| Keyword constructors | ✓ | ✓ | ✓ | | ✓ |
| Mutable structs | ✓ | ✓ | ✓ | ✓ | ✓ |
| Parametric types | ✓ | ✓ | ✓ | ✓ (auto-inferred) | ✓ |
| Define abstract supertypes | | | | | ✓ |
| Full type hierarchy in one expression | | | | | ✓ |
| Nested abstract hierarchies | | | | | ✓ |
| Per-type mutability | | | | | ✓ |
| Const fields (Julia 1.8+) | | | | | ✓ |
| Source lines | — | ~540 | ~670 | ~245 | ~175 |
| Dependencies | — | ConstructionBase, MacroTools | OrderedCollections, UnPack | none | none |

To make the difference concrete, here is the same type hierarchy defined with each package — an abstract `Animal` with a `Cat` (default `lives=9`) and a mutable `Dog` with a const `name` field:

**Terse.jl — 4 lines**
```julia
@types Animal > (
    Cat(lives::Int = 9),
    @mutable Dog(@const(name::String), pointy_ears::Bool)
)
```

**[QuickTypes.jl](https://github.com/cstjean/QuickTypes.jl) — 6 lines** *(one type at a time; `@qmutable` has no const field support, falls back to plain Julia)*
```julia
abstract type Animal end
@qstruct Cat(lives::Int = 9) <: Animal
mutable struct Dog <: Animal
    const name::String
    pointy_ears::Bool
end
```

**[Parameters.jl](https://github.com/mauro3/Parameters.jl) — 9 lines** *(block syntax; no const field support in `@with_kw`, falls back to plain Julia)*
```julia
abstract type Animal end
@with_kw struct Cat <: Animal
    lives::Int = 9
end
mutable struct Dog <: Animal
    const name::String
    pointy_ears::Bool
end
```

**`Base.@kwdef` — 9 lines** *(no extra dependencies; no const field support in `@kwdef`, falls back to plain Julia)*
```julia
abstract type Animal end
Base.@kwdef struct Cat <: Animal
    lives::Int = 9
end
mutable struct Dog <: Animal
    const name::String
    pointy_ears::Bool
end
```
