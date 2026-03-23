using Terse
using Test

@testset "Terse.jl" begin
    @testset "@types standalone abstract" begin
        @types MyAbstract
        @types MyAbstract2{T}
        @test isabstracttype(MyAbstract)
        @test isabstracttype(MyAbstract2)
    end

    @testset "@types simple" begin
        @types Shape > (
            Circle(radius::Float64),
            Rectangle(width::Float64, height::Float64)
        )
        @test supertype(Circle) === Shape
        @test supertype(Rectangle) === Shape
        @test Circle(1.0) isa Shape
        @test Rectangle(2.0, 3.0) isa Shape
    end

    @testset "@types parametric" begin
        @types Container{T} > (
            Box{T}(value::T),
            Pair{T, S}(first::T, second::S)
        )
        @test supertype(Box{Int}) === Container{Int}
        @test supertype(Pair{Int, String}) === Container{Int}
        @test Box{Int}(42) isa Container{Int}
        @test Pair{Int, String}(1, "a") isa Container{Int}
    end

    @testset "@types nested hierarchy" begin
        @types Animal2{T} > (
            Cat2{T}(lives::Int, family::T),
            Dog2{T, S <: AbstractString}(name::S, family::T),
            Invertebrate{T} > (
                Worm,
                Insect{T, I <: Integer}(legs::I, family::T)
            )
        )
        @test supertype(Cat2{Int}) === Animal2{Int}
        @test supertype(Dog2{Int, String}) === Animal2{Int}
        @test supertype(Invertebrate{Int}) === Animal2{Int}
        @test supertype(Worm{Int}) === Invertebrate{Int}
        @test supertype(Insect{Int, Int32}) === Invertebrate{Int}
        @test Worm{Float64}() isa Invertebrate{Float64}
        @test Insect{Int, Int32}(6, 1) isa Invertebrate{Int}
    end

    @testset "@types single concrete type" begin
        @types Point(x::Float64, y::Float64)
        @types Wrapped{T}(value::T)
        @test !isabstracttype(Point)
        @test !isabstracttype(Wrapped)
        @test Point(1.0, 2.0) isa Point
        @test Wrapped{Int}(42) isa Wrapped{Int}
    end

    @testset "@types single concrete type with supertype" begin
        @types MySupertype
        @types TypedSub{T}(x::T) <: MySupertype
        @test !isabstracttype(TypedSub)
        @test supertype(TypedSub{Int}) === MySupertype
        @test TypedSub{String}("hi") isa MySupertype
    end

    @testset "@types bounded type params" begin
        @types Wrapper{T} > (
            Plain{T}(value::T),
            Labelled{T, S <: AbstractString}(value::T, label::S)
        )
        @test supertype(Plain{Int}) === Wrapper{Int}
        @test supertype(Labelled{Int, String}) === Wrapper{Int}
        @test Plain{Int}(1) isa Wrapper{Int}
        @test Labelled{Int, String}(1, "hello") isa Wrapper{Int}
        @test_throws TypeError Labelled{Int, Int}(1, 2)  # S must be <: AbstractString
    end
end
