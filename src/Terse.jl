module Terse

export @types, @show_types

import InteractiveUtils: subtypes

const _MUTABLE_SYM = Symbol("@mutable")
const _CONST_SYM   = Symbol("@const")

#-----------------------------------------------------------------------------# @show_types helpers
function _st_typevar_str(tv::TypeVar)
    tv.ub === Any && return string(tv.name)
    return string(tv.name) * " <: " * string(tv.ub)
end

function _st_split(T)
    params = TypeVar[]
    while T isa UnionAll
        push!(params, T.var)
        T = T.body
    end
    return params, T
end

function _st_type_sig(T)
    params, body = _st_split(T)
    name = string(nameof(body))
    isempty(params) && return name, body
    return name * "{" * join(_st_typevar_str.(params), ", ") * "}", body
end

function _st_field_str(fname, ftype)
    ftype isa TypeVar && return string(fname) * "::" * string(ftype.name)
    return string(fname) * "::" * string(ftype)
end

function _st_concrete_str(T, indent=0; show_mutable=false)
    pad = "    " ^ indent
    sig, body = _st_type_sig(T)
    fnames = fieldnames(body)
    is_mut = ismutabletype(body)
    prefix = (show_mutable && is_mut) ? "@mutable " : ""
    isempty(fnames) && return pad * prefix * sig
    fields = map(zip(fnames, body.types)) do (n, t)
        s = _st_field_str(n, t)
        (is_mut && Base.isconst(body, n)) ? "@const(" * s * ")" : s
    end
    return pad * prefix * sig * "(" * join(fields, ", ") * ")"
end

function _st_leaves(T)
    result = Any[]
    for S in subtypes(T)
        isabstracttype(S) ? append!(result, _st_leaves(S)) : push!(result, S)
    end
    return result
end

function _st_impl(T, indent=0; all_mutable=false)
    pad = "    " ^ indent
    sig, _ = _st_type_sig(T)
    children = subtypes(T)
    isempty(children) && return pad * sig
    sub_strs = map(children) do S
        isabstracttype(S) ? _st_impl(S, indent + 1; all_mutable) :
            _st_concrete_str(S, indent + 1; show_mutable=!all_mutable)
    end
    return pad * sig * " > (\n" * join(sub_strs, ",\n") * "\n" * pad * ")"
end

function _show_types_str(T)
    if isabstracttype(T)
        leaves = _st_leaves(T)
        all_mut = !isempty(leaves) && all(ismutabletype, leaves)
        prefix = all_mut ? "mutable " : ""
        return prefix * _st_impl(T; all_mutable=all_mut)
    else
        _, body = _st_split(T)
        prefix = ismutabletype(body) ? "mutable " : ""
        return prefix * _st_concrete_str(T)
    end
end

#-----------------------------------------------------------------------------# @types helpers
_is_const_field(f) = Meta.isexpr(f, :macrocall) && f.args[1] === _CONST_SYM
_unwrap_const(f)   = _is_const_field(f) ? f.args[end] : f

function _to_struct_field(f)
    _is_const_field(f) && return Expr(:const, _plain(f.args[end]))
    return _plain(f)
end

function _terse_parse_type(ex)
    ex isa Symbol && return ex, Any[]
    Meta.isexpr(ex, :curly) && return ex.args[1], ex.args[2:end]
    error("@types: invalid type expression: $ex")
end

# Returns (name, params, pos_fields, kw_fields).
# kw_fields is non-empty only when the user used ; in the field list.
function _terse_parse_subtype(ex)
    Meta.isexpr(ex, :call) || error("@types: expected `TypeName(fields...)`, got: $ex")
    name, params = _terse_parse_type(ex.args[1])
    rest = ex.args[2:end]
    if !isempty(rest) && Meta.isexpr(rest[1], :parameters)
        return name, params, rest[2:end], rest[1].args
    else
        return name, params, rest, Any[]
    end
end

_ctor_name(sig) = Meta.isexpr(sig, :<:) ? _ctor_name(sig.args[1]) : (Meta.isexpr(sig, :curly) ? sig.args[1] : sig)

_plain(f) = Meta.isexpr(f, :kw) ? f.args[1] : f

_fname(f) = Meta.isexpr(f, :(::)) ? f.args[1] : f

_build_curly(name, params) = isempty(params) ? name : Expr(:curly, name, params...)

_is_docstr(ex) = ex isa AbstractString || Meta.isexpr(ex, :string)

function _expr_to_str(ex)
    ex isa Symbol && return string(ex)
    ex isa Number && return string(ex)
    ex isa AbstractString && return repr(ex)
    Meta.isexpr(ex, :(::)) && return _expr_to_str(ex.args[1]) * "::" * _expr_to_str(ex.args[2])
    Meta.isexpr(ex, :kw) && return _expr_to_str(ex.args[1]) * " = " * _expr_to_str(ex.args[2])
    Meta.isexpr(ex, :<:) && return _expr_to_str(ex.args[1]) * " <: " * _expr_to_str(ex.args[2])
    Meta.isexpr(ex, :curly) && return _expr_to_str(ex.args[1]) * "{" * join(_expr_to_str.(ex.args[2:end]), ", ") * "}"
    return string(ex)
end

function _autodoc_sig(name, params, pos_fields, kw_fields)
    name_str = isempty(params) ? string(name) : string(name) * "{" * join(_expr_to_str.(params), ", ") * "}"
    isempty(pos_fields) && isempty(kw_fields) && return name_str
    pos_strs = _expr_to_str.(_unwrap_const.(pos_fields))
    isempty(kw_fields) && return name_str * "(" * join(pos_strs, ", ") * ")"
    kw_strs = _expr_to_str.(_unwrap_const.(kw_fields))
    pfx = isempty(pos_strs) ? "" : join(pos_strs, ", ") * "; "
    return name_str * "(" * pfx * join(kw_strs, ", ") * ")"
end

_wrap_doc(doc, ex) = Expr(:macrocall, GlobalRef(Core, Symbol("@doc")), LineNumberNode(0, :none), doc, ex)

# If the expression is a `@mutable` macrocall, set flag and unwrap.
function _unwrap_mutable(is_mutable, ex)
    Meta.isexpr(ex, :macrocall) && ex.args[1] === _MUTABLE_SYM || return is_mutable, ex
    return true, ex.args[end]
end

function _make_struct(is_mutable, sig, pos_fields, kw_fields=Any[])
    has_const = any(_is_const_field, pos_fields) || any(_is_const_field, kw_fields)
    has_const && !is_mutable &&
        error("@types: @const fields are only valid inside a @mutable (or `@types mutable`) type")

    has_pos_defaults = any(f -> Meta.isexpr(_unwrap_const(f), :kw), pos_fields)
    has_explicit_kw  = !isempty(kw_fields)

    plain_pos  = map(f -> _plain(_unwrap_const(f)), pos_fields)
    plain_kw   = map(f -> _plain(_unwrap_const(f)), kw_fields)
    all_names  = map(_fname, [plain_pos; plain_kw])
    ctor       = _ctor_name(sig)
    struct_pos = map(_to_struct_field, pos_fields)
    struct_kw  = map(_to_struct_field, kw_fields)

    !has_pos_defaults && !has_explicit_kw &&
        return Expr(:struct, is_mutable, sig, Expr(:block, struct_pos...))

    new_call = Expr(:call, :new, all_names...)
    if has_explicit_kw
        ctor_def = Expr(:(=),
            Expr(:call, ctor, Expr(:parameters, map(_unwrap_const, kw_fields)...), map(_unwrap_const, pos_fields)...),
            new_call)
        return Expr(:struct, is_mutable, sig, Expr(:block, [struct_pos; struct_kw]..., ctor_def))
    else
        required = filter(f -> !Meta.isexpr(_unwrap_const(f), :kw), pos_fields)
        optional = filter(f ->  Meta.isexpr(_unwrap_const(f), :kw), pos_fields)
        pos_ctor = Expr(:(=), Expr(:call, ctor, map(_unwrap_const, pos_fields)...), new_call)
        kw_ctor  = Expr(:(=),
            Expr(:call, ctor, Expr(:parameters, map(_unwrap_const, optional)...), map(_unwrap_const, required)...),
            new_call)
        return Expr(:struct, is_mutable, sig, Expr(:block, struct_pos..., pos_ctor, kw_ctor))
    end
end

function _types_impl(abstract_expr, subtypes_expr, parent_head=nothing; is_mutable=false, docpath="")
    abstract_name, abstract_params = _terse_parse_type(abstract_expr)
    abstract_head = _build_curly(abstract_name, abstract_params)
    abstract_decl = Expr(:abstract, parent_head === nothing ? abstract_head : Expr(:<:, abstract_head, parent_head))
    current_path = isempty(docpath) ? string(abstract_name) : docpath * " > " * string(abstract_name)

    children = Meta.isexpr(subtypes_expr, :tuple) ? subtypes_expr.args : [subtypes_expr]

    decls = Any[]
    pending_doc = nothing
    for st in children
        if _is_docstr(st)
            pending_doc = st
            continue
        end
        local_mutable, st = _unwrap_mutable(is_mutable, st)
        if Meta.isexpr(st, :call) && st.args[1] == :>
            push!(decls, _types_impl(st.args[2], st.args[3], abstract_head; is_mutable=local_mutable, docpath=current_path))
            pending_doc = nothing
        elseif st isa Symbol
            struct_expr = _make_struct(local_mutable, Expr(:<:, _build_curly(st, abstract_params), abstract_head), Any[])
            doc = something(pending_doc, current_path * " > \n" * _autodoc_sig(st, abstract_params, Any[], Any[]))
            push!(decls, _wrap_doc(doc, struct_expr))
            pending_doc = nothing
        else
            name, params, pos_fields, kw_fields = _terse_parse_subtype(st)
            struct_expr = _make_struct(local_mutable, Expr(:<:, _build_curly(name, params), abstract_head), pos_fields, kw_fields)
            doc = something(pending_doc, current_path * " > \n" * _autodoc_sig(name, params, pos_fields, kw_fields))
            push!(decls, _wrap_doc(doc, struct_expr))
            pending_doc = nothing
        end
    end

    return Expr(:block, abstract_decl, decls...)
end

function _types_single(is_mutable, ex)
    is_mutable, ex = _unwrap_mutable(is_mutable, ex)
    if ex isa Symbol || Meta.isexpr(ex, :curly)
        abstract_name, abstract_params = _terse_parse_type(ex)
        return Expr(:abstract, _build_curly(abstract_name, abstract_params))
    elseif Meta.isexpr(ex, :call) && ex.args[1] != :>
        name, params, pos_fields, kw_fields = _terse_parse_subtype(ex)
        return _make_struct(is_mutable, _build_curly(name, params), pos_fields, kw_fields)
    elseif Meta.isexpr(ex, :<:)
        name, params, pos_fields, kw_fields = _terse_parse_subtype(ex.args[1])
        return _make_struct(is_mutable, Expr(:<:, _build_curly(name, params), ex.args[2]), pos_fields, kw_fields)
    elseif Meta.isexpr(ex, :call) && ex.args[1] == :>
        return _types_impl(ex.args[2], ex.args[3]; is_mutable)
    end
    error("@types: unrecognised syntax: $ex")
end

#-----------------------------------------------------------------------------# @types
"""
    @types AbstractType
    @types [mutable] ConcreteType(pos_fields...; kw_fields...)
    @types [mutable] ConcreteType(pos_fields...; kw_fields...) <: SuperType
    @types [mutable] AbstractType > (Subtype1(fields...), Subtype2(fields...))
    @types [mutable] AbstractType{T} > (Subtype1{T}(fields...), Subtype2{T, S}(fields...))

Define abstract types, concrete structs, or full type hierarchies in one expression.

- `mutable` makes all generated concrete structs mutable.
- `@mutable SubType(...)` makes an individual subtype mutable within a hierarchy.
- `@const(field::T)` marks a field as const within a `@mutable` or `mutable` type.
- Fields with default values (`field::T = val`) generate inner constructors for both
  positional-with-defaults and keyword argument construction.
- Use `;` to separate positional fields from keyword-only fields, generating a single
  constructor that mirrors the exact positional/keyword split you specify.
- Subtypes can themselves use `>` to define nested hierarchies.
- Bare names (no parentheses) produce zero-field structs inheriting the parent's type parameters.
- Each concrete subtype gets an auto-generated docstring showing its hierarchy path and
  constructor signature (e.g. `"Animal > \nDog(name::String)"`). Place a string literal
  immediately before a subtype entry to override it with a custom docstring.

### Examples

```julia
@types Animal

@types Cat(lives::Int)

@types Dog(name::String) <: Animal

@types mutable Counter(n::Int = 0)

@types Server(host::String; port::Int = 8080, timeout::Int = 30)

@types Animal > (
    Cat(lives::Int),
    Dog(name::String)
)

@types Animal > (
    Cat(lives::Int = 9),
    @mutable Dog(@const(name::String), legs::Int)
)

# Custom docstrings: place a string before the entry to override the auto-generated doc
@types Animal > (
    "A feline with a fixed number of lives.",
    Cat(lives::Int = 9),
    Dog(name::String),  # auto-doc: "Animal > \nDog(name::String)"
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
    esc(_types_single(false, ex))
end

macro types(mutable_kw, ex)
    mutable_kw === :mutable || error("@types: expected `mutable`, got `$mutable_kw`")
    esc(_types_single(true, ex))
end

#-----------------------------------------------------------------------------# @show_types
"""
    @show_types T

Display the type hierarchy rooted at `T` in `@types` syntax.

### Examples

```julia
@types Animal > (
    Cat(lives::Int),
    Dog(name::String)
)

@show_types Animal
# Animal > (
#     Cat(lives::Int64),
#     Dog(name::String)
# )
```
"""
macro show_types(T)
    :(println(_show_types_str($(esc(T)))))
end


end # module
