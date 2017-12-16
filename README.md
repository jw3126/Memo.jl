# Memo

[![Build Status](https://travis-ci.org/jw3126/Memo.jl.svg?branch=master)](https://travis-ci.org/jw3126/Memo.jl)
[![codecov.io](https://codecov.io/github/jw3126/Memo.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/Memo.jl?branch=master)

Function memoization, inspired by [Memoize.jl]("https://github.com/simonster/Memoize.jl") by simonster.

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

### Customize the cache

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

### Inspection

```julia
julia> using Memo

julia> @memoize function f(x)
           println("long running computation on $x")
           x
       end
f (generic function with 1 method)

julia> f(1)
long running computation on 1
1

julia> cache = @get_cache f(1)  # get cache of the f(1) method
ObjectIdDict with 1 entry:
  (##f#Any#####inner##, (1,), ()) => 1

julia> empty!(cache)
ObjectIdDict with 0 entries

julia> f(1)  # again the long running computation
long running computation on 1
1

julia> @recompute f(1)  # force recompute
long running computation on 1
1

julia> f_inner = @get_inner f(1)  # get the original function of the f(1) method
##f#Any#####inner## (generic function with 1 method)

julia> f(1)  # no long running computation
1

julia> f_inner(1)
long running computation on 1
1

julia> f_inner(1)
long running computation on 1
1
```

## Relation to Memoize.jl

This package was heavily inspired by [Memoize.jl]("https://github.com/simonster/Memoize.jl"). It should act as a drop in replacement of the latter.

Almost the whole testsuit of [Memoize.jl]("https://github.com/simonster/Memoize.jl")
is borrowed here to ensure compatibility.

In addition to the features of [Memoize.jl]("https://github.com/simonster/Memoize.jl") this package provides easier customization and inspection.

There are also some subtle behavior differences. For example [Memoize.jl]("https://github.com/simonster/Memoize.jl") 
uses one cache per function, this package uses one cache per method.
As a consequence adding a memoized method does not reset the cache of the whole function in this package.
