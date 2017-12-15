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

include("tests_from_memoize.jl")
