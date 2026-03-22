module Terse

export @qtype, @abstract

#--------------------------------------------------------------------------------# @qtype
"""
    @qtype [mutable] Name(field::Type, ...) [<: Supertype]

Define a struct with positional field syntax.

### Examples

```julia
@qtype Point(x::Float64, y::Float64)

@qtype NamedPoint(x::Float64, y::Float64) <: AbstractPoint

@qtype mutable Counter(n::Int) <: AbstractCounter
```
"""
macro qtype(expr)
    esc(_make_struct(expr, false))
end

macro qtype(mutable_kw, expr)
    mutable_kw == :mutable || error("@qtype: expected 'mutable', got $mutable_kw")
    esc(_make_struct(expr, true))
end

function _make_struct(expr, is_mutable)
    if expr isa Expr && expr.head == :(<:)
        call_expr = expr.args[1]
        typename = Expr(:(<:), call_expr.args[1], expr.args[2])
    else
        call_expr = expr
        typename = call_expr.args[1]
    end
    fields = call_expr.args[2:end]
    Expr(:struct, is_mutable, typename, Expr(:block, fields...))
end

#--------------------------------------------------------------------------------# @abstract
macro abstract(expr)
    stmts = Expr[]
    _abstract!(stmts, expr, nothing)
    esc(Expr(:block, stmts...))
end

function _abstract!(stmts, expr, parent)
    if expr isa Symbol
        push!(stmts, parent === nothing ?
                     :(abstract type $expr end) :
                     :(abstract type $expr <: $parent end))
    elseif expr isa Expr && expr.head == :call
        name = expr.args[1]
        push!(stmts, parent === nothing ?
                     :(abstract type $name end) :
                     :(abstract type $name <: $parent end))
        for child in expr.args[2:end]
            _abstract!(stmts, child, name)
        end
    else
        error("@abstract_types: expected Symbol or call expression, got: $expr")
    end
end

end # module
