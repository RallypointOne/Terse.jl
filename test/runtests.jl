using Terse
using Test

@testset "Terse.jl" begin
    @test Terse.greet() == "Hello from Terse!"
end
