export MemoizedFunction

struct MemoizedFunction{F,C} <: Function
    f::F
    cache::C
end

makekey(f,args...;kw...) = (f,args,tuple(kw...))

function (m::MemoizedFunction)(args...;kw...)
    R = Core.Inference.return_type(m.f, typeof(args))
    key = makekey(m.f, args...; kw...)
    if !haskey(m.cache, key)
        m.cache[key] = m.f(args...; kw...)
    end
    m.cache[key]::R
end
