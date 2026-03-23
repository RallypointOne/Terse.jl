[![CI](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/Terse.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/Terse.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/Terse.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/Terse.jl/dev/)

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
