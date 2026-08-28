[![CI](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Terse.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/Terse.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/Terse.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/Terse.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/Terse.jl/dev/)

# Terse.jl

Terse.jl provides the `@types` macro for defining type hierarchies concisely.


## Usage

```julia
using Terse

@types Shape > (
    TwoDimensional > (
        Circle(radius::Float64 = 1.0),
        Rectangle(width::Float64 = 1.0, height::Float64 = 1.0),
        Triangle(base::Float64, height::Float64)
    ),
    @mutable ThreeDimensional > (
        Sphere(@const(radius::Float64); hollow::Bool = false),
        Cube(@const(side::Float64); hollow::Bool = false),
        Prism > (
            TriangularPrism(base::Float64, height::Float64),
            Cylinder(radius::Float64 = 1.0; height::Float64 = 1.0)
        )
    )
)

Circle()             # Circle(1.0)           — default radius
Rectangle(2.0)       # Rectangle(2.0, 1.0)   — default height
Triangle(3.0, 4.0)   # Triangle(3.0, 4.0)

s = Sphere(5.0)
s.hollow = true      # mutable field
s.radius = 1.0       # ERROR: const field
```

### Standalone abstract type

```julia
@types Animal
```

### Abstract type with concrete subtypes

```julia
@types Animal > (
    Cat(lives::Int),
    Dog(name::String)
)
```

### Parametric types with bounded type parameters

```julia
@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Dog{T, S <: AbstractString}(name::S, family::T)
)
```

### Nested hierarchies

```julia
@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Invertebrate{T} > (
        Mollusc,                    # abstract type Mollusc{T} <: Invertebrate{T}
        Worm{T}(),                  # struct Worm{T} <: Invertebrate{T}  (no fields)
        Insect{T, I <: Integer}(legs::I, family::T)
    )
)
```

Parentheses decide abstract vs. concrete: a bare name declares an abstract type (inheriting
the parent's type parameters when it declares none), while empty parentheses declare a
zero-field concrete struct.

### Single concrete type (with optional supertype)

```julia
@types Point(x::Float64, y::Float64)

@types Wrapper{T}(value::T) <: Animal{T}
```

### Per-type mutability and const fields

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

### Hidden fields

Use `@hide(field)` to suppress a field from the auto-generated `show` method (the field is still part of the struct and constructor):

```julia
@types Token(value::String, @hide(raw::Vector{UInt8}))

Token("abc", UInt8[0x61, 0x62, 0x63])  # Token(value="abc")
```

### Computed constructors

Use `= new(field::T = expr, ...)` when the struct's stored fields should differ from the constructor arguments. Each `new(...)` argument defines a struct field and how it's computed:

```julia
@types Polar(x, y) = new(r::Float64 = hypot(x, y), θ::Float64 = atan(y, x))

Polar(3.0, 4.0)  # Polar(r=5.0, θ=0.9272952180016122)
```

Works everywhere — standalone, with `<:`, in hierarchies, parametric, and mutable:

```julia
@types Transform > (
    Scale(factor::Float64) = new(matrix::Vector{Float64} = [factor, factor]),
    Translate(dx::Float64, dy::Float64) = new(offset::Vector{Float64} = [dx, dy]),
)

@types Sum{T}(a::T, b::T) = new(total::T = a + b)
```

### Escape hatch for arbitrary code

Use `@esc(expr)` inside a hierarchy to splice arbitrary expressions (e.g. interface methods) into the output alongside the type definitions:

```julia
@types Animal > (
    Cat(lives::Int),
    Dog(name::String),
    @esc(sound(x::Cat) = "meow"),
    @esc(sound(x::Dog) = "woof"),
)

sound(Cat(9))   # "meow"
sound(Dog("Rex"))  # "woof"
```
