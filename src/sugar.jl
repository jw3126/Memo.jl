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
const GET_CACHED_NAME = :get_cached
@eval function $GET_CACHED_NAME end
@eval export $GET_CACHED_NAME

function get_cached_def(p; f_cached_name::Symbol=nothing, get_cached_name::Expr=nothing)
    f_name = p[:name]
    arg1 = :(::typeof($f_name))
    Ts = map(p[:args]) do arg
        name, T, vararg, default = splitarg(arg)
        T
    end
    arg2 = :(::Type{Tuple{$(Ts...)}})
    f_name = p[:name]
    body = f_cached_name
    
    q = Dict(
        :name => get_cached_name,
        :body => f_cached_name,
        :args => [arg1, arg2],
        :whereparams => p[:whereparams],
        :kwargs => []
    )
    combinedef(q)
end

function complete_def(p, cache)
    # TODO
    # We want that a method rewrite
    # of f triggers method rewrites of f_inner, f_cached
    # this is important for gc.
    # For this we need deterministic symbols
    #
    # OTOH we probably don't want f_cached to be overwritten
    # when a new memoized method of f is defined.
    # Also we would like to be able to redefine the type
    # of cache we use. For this we need new symbols everytime

    DETERMINISTIC_SYMBOLS = true
    f_inner_name = Symbol("####", p[:name], :_inner)
    f_cached_name = Symbol("####", p[:name], :_cached)
    if !DETERMINISTIC_SYMBOLS
        f_inner_name = gensym(f_inner_name)
        f_cached_name = gensym(f_cached_name)
    end
    get_cached_name = Expr(Symbol("."), MODULE, QuoteNode(GET_CACHED_NAME))
    cache = :($(MODULE)._makecache($(cache)))
    Expr(:block,
        f_inner_def(p, f_inner_name=f_inner_name),
        f_cached_def(p, cache, f_inner_name=f_inner_name, f_cached_name=f_cached_name),
        f_surface_def(p, f_cached_name=f_cached_name),
        get_cached_def(p, f_cached_name=f_cached_name, get_cached_name=get_cached_name),
        f_cached_name,
        p[:name],
    )
end
