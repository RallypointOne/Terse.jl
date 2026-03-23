module Terse

export @types

#-----------------------------------------------------------------------------# helpers
function _terse_parse_type(ex)
    ex isa Symbol && return ex, Any[]
    Meta.isexpr(ex, :curly) && return ex.args[1], ex.args[2:end]
    error("@types: invalid type expression: $ex")
end

function _terse_parse_subtype(ex)
    Meta.isexpr(ex, :call) || error("@types: expected `TypeName(fields...)`, got: $ex")
    name, params = _terse_parse_type(ex.args[1])
    return name, params, ex.args[2:end]
end

# Recursively build declarations for a type hierarchy.
# parent_head: the supertype expression to use, or nothing for the root.
function _types_impl(abstract_expr, subtypes_expr, parent_head=nothing)
    abstract_name, abstract_params = _terse_parse_type(abstract_expr)
    abstract_head = isempty(abstract_params) ? abstract_name : Expr(:curly, abstract_name, abstract_params...)

    abstract_body = parent_head === nothing ? abstract_head : Expr(:<:, abstract_head, parent_head)
    abstract_decl = Expr(:abstract, abstract_body)

    subtypes = Meta.isexpr(subtypes_expr, :tuple) ? subtypes_expr.args : [subtypes_expr]

    decls = map(subtypes) do st
        if Meta.isexpr(st, :call) && st.args[1] == :>
            # Nested hierarchy: recurse with this abstract type as parent
            _types_impl(st.args[2], st.args[3], abstract_head)
        elseif st isa Symbol
            # Bare symbol: zero-field struct, inherits parent's type params
            sig = isempty(abstract_params) ? st : Expr(:curly, st, abstract_params...)
            Expr(:struct, false, Expr(:<:, sig, abstract_head), Expr(:block))
        else
            # Regular subtype with explicit fields
            name, params, fields = _terse_parse_subtype(st)
            sig = isempty(params) ? name : Expr(:curly, name, params...)
            Expr(:struct, false, Expr(:<:, sig, abstract_head), Expr(:block, fields...))
        end
    end

    return Expr(:block, abstract_decl, decls...)
end

#-----------------------------------------------------------------------------# @types
"""
    @types AbstractType
    @types AbstractType > (Subtype1(fields...), Subtype2(fields...))
    @types AbstractType{T} > (Subtype1{T}(fields...), Subtype2{T, S}(fields...))

Define an abstract type and a set of concrete subtypes in one expression.
Subtypes can themselves use `>` to define nested type hierarchies.
Bare names (no parentheses) produce zero-field structs that inherit the parent's type parameters.

### Examples

```julia
@types Animal > (
    Cat(lives::Int),
    Dog(name::String)
)

@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Dog{T, S}(name::S, family::T)
)

@types Animal{T} > (
    Cat{T}(lives::Int, family::T),
    Dog{T, S <: AbstractString}(name::S, family::T),
    Invertebrate{T} > (
        Worm,
        Insect{T, I <: Integer}(legs::I, family::T)
    )
)
```
"""
macro types(ex)
    if ex isa Symbol || Meta.isexpr(ex, :curly)
        abstract_name, abstract_params = _terse_parse_type(ex)
        abstract_head = isempty(abstract_params) ? abstract_name : Expr(:curly, abstract_name, abstract_params...)
        return esc(Expr(:abstract, abstract_head))
    elseif Meta.isexpr(ex, :call) && ex.args[1] != :>
        name, params, fields = _terse_parse_subtype(ex)
        sig = isempty(params) ? name : Expr(:curly, name, params...)
        return esc(Expr(:struct, false, sig, Expr(:block, fields...)))
    elseif Meta.isexpr(ex, :<:)
        name, params, fields = _terse_parse_subtype(ex.args[1])
        sig = isempty(params) ? name : Expr(:curly, name, params...)
        return esc(Expr(:struct, false, Expr(:<:, sig, ex.args[2]), Expr(:block, fields...)))
    end
    Meta.isexpr(ex, :call) && ex.args[1] == :> ||
        error("@types: expected `AbstractType`, `ConcreteType(fields...)`, or `AbstractType > (subtypes...)`")
    return esc(_types_impl(ex.args[2], ex.args[3]))
end

end # module
