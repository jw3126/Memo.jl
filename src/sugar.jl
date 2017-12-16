export @memoize
const MODULE = Memo
using MacroTools: combinedef, splitdef, combinearg, splitarg

patch(d; kw...) = merge(d, Dict(kw))

function f_cached_def(p, cache; f_inner_name::Symbol=nothing, f_cached_name::Symbol=nothing)
    :(const $f_cached_name = $MODULE.MemoizedFunction($f_inner_name, $cache))
end

function f_inner_def(p; f_inner_name::Symbol=nothing)
    q = patch(p,
        name=f_inner_name,
    )
    combinedef(q)
end

function f_surface_def(p; f_cached_name::Symbol=nothing)
    callargs = map(p[:args]) do arg
        name, T, variadic, default = splitarg(arg)
        variadic ? Expr(Symbol("..."), name) : name 
    end
    callkwargs = map(p[:kwargs]) do kwarg
        name, T, variadic, default = splitarg(kwarg)
        variadic ? Expr(Symbol("..."), name) : Expr(:kw, name, name)
    end
    f_body = Expr(:call, f_cached_name, Expr(:parameters, callkwargs...), callargs...)
    q = patch(p, 
        body=f_body,
    )
    combinedef(q)
end

macro memoize(cache, fdef)
    esc(memoize(fdef, cache))
end

macro memoize(fdef)
    esc(memoize(fdef))
end

function memoize(fdef, cache = :(ObjectIdDict()))
    p = splitdef(fdef)
    complete_def(p, cache)
end

_makecache(c) = c
function _makecache(C::Type)
    warn("@memoize $C expr is deprecated. Use @memoize $C() expr instead.")
    C()
end

function get_memoized end

for fname in [:get_cache, :get_inner]
    mname = Symbol("@", fname)
    @eval begin
        export $mname
        macro ($fname)(ex0)
            Base.gen_call_with_extracted_types($(Expr(:quote,fname)), ex0)
        end
    end
end

export get_cache, get_inner
function get_cache(f, ::Type{T}) where {T <: Tuple}
    get_memoized(f, T).cache
end
function get_inner(f, ::Type{T}) where {T <: Tuple}
    get_memoized(f, T).f
end

function argtupletype(p)
    Ts = map(p[:args]) do arg
        name, T, vararg, default = splitarg(arg)
        T
    end
    :(Tuple{$(Ts...)})
end

function get_memoized_def(p; f_cached_name::Symbol=nothing, get_memoized_name::Expr=nothing)
    f_name = p[:name]
    arg1 = :(::typeof($f_name))
    TT = argtupletype(p)
    arg2 = :(::Type{<: $TT})
    f_name = p[:name]
    body = f_cached_name
    
    q = Dict(
        :name => get_memoized_name,
        :body => f_cached_name,
        :args => [arg1, arg2],
        :whereparams => p[:whereparams],
        :kwargs => []
    )
    combinedef(q)
end

function method_symbol(p, suffix="")
    # HACK
    # We want that a method rewrite
    # of f triggers method rewrites of f_inner, f_cached
    # this is important for gc.
    # For this we need that each method rewrite of f
    # produces the same f_inner (resp. f_cached) symbol.
    #
    # OTOH we don't want f_cached to be overwritten
    # when a new memoized method of f with different signature is defined.

    argtypes = map(p[:args]) do arg
        _,T,_,_ = splitarg(arg)
        T
    end
    pieces = ["#", p[:name], argtypes...,
        "#", p[:whereparams]...,
        "#", suffix, "#"]
    Symbol(join(pieces, "#"))
end

function complete_def(p, cache)

    f_inner_name = method_symbol(p, :inner)
    f_cached_name = method_symbol(p, :cached)
    get_memoized_name = Expr(Symbol("."), MODULE, QuoteNode(:get_memoized))
    cache = :($(MODULE)._makecache($(cache)))
    Expr(:block,
        f_inner_def(p, f_inner_name=f_inner_name),
        f_cached_def(p, cache, f_inner_name=f_inner_name, f_cached_name=f_cached_name),
        f_surface_def(p, f_cached_name=f_cached_name),
        get_memoized_def(p, f_cached_name=f_cached_name, get_memoized_name=get_memoized_name),
        p[:name],
    )
end
