# Memo

## Usage
```julia
julia> using Memo

julia> @memoize function f(x)
           println("computing with argument: ", x)
           x
       end
f (generic function with 1 method)

julia> f(1)
computing with argument: 1
1

julia> f(1)
1

julia> f(2)
computing with argument: 2
2

julia> f(2)
2

julia> f(2)
2
```

### Fine grained control

```julia
julia> using Memo
julia> cache = Dict()
Dict{Any,Any} with 0 entries

julia> @memoize cache function f(x)
                  println("computing with argument: ", x)
                  x
              end
WARNING: redefining constant ####f_cached
(::MemoizedFunction) (generic function with 1 method)

julia> f(1)
computing with argument: 1
1

julia> cache
Dict{Any,Any} with 1 entry:
  (####f_inner, (1,), ()) => 1

julia> empty!(cache)
Dict{Any,Any} with 0 entries

julia> f(1)
computing with argument: 1
1
```

### Even more control

```julia
julia> using Memo

julia> f(x) = @show x
f (generic function with 1 method)

julia> cache = Dict()
Dict{Any,Any} with 0 entries

julia> g = MemoizedFunction(f, cache)
(::MemoizedFunction) (generic function with 1 method)

julia> g(1)
x = 1
1

julia> g(1)
1

julia> g.f(1)  # access the original function
x = 1
1

julia> g.cache # access the cache
Dict{Any,Any} with 1 entry:
  (f, (1,), ()) => 1
```

## Acknowledgement

This package was inspired by [Memoize.jl]("https://github.com/simonster/Memoize.jl") by simonster. It also
borrows large parts of the testsuit from that package.
