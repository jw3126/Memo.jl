using Memo
using Base.Test

run = 0
@testset "@memoize cache f" begin
    cache = Dict()
    @memoize cache function f(x)
        global run += 1
        x
    end
    @test f(1) == 1
    @test run == 1
    @test f(1) == 1
    @test run == 1
    empty!(cache)
    @test f(1) == 1
    @test run == 2
end

run = 0
# method local cache tests
@memoize function f(x::Int)
    global run += 1
    2x
end
@test f(1) === 2
@test run == 1
@memoize function f(x::Float64)
    global run += 1
    2x
end
@test f(1) === 2
@test run == 1  # cache of different methods do not interfere
@test f(1.) === 2.
@test run == 2
println("There should be a rewrite warning for f(::Int)")
@memoize function f(x::Int)
    global run += 1
    3x
end
@test f(1) === 3  # rewrite of method clears its cache
@test run == 3
@test f(1.) === 2.
@test run == 3    # rewrite of method does not interfere with cache of different method

include("tests_from_memoize.jl")
