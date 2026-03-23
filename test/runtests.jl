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

    @testset "@types mutable" begin
        @types mutable Counter(n::Int)
        @types mutable Animal3
        @types mutable Labeled(label::String) <: Animal3
        @types mutable Vehicle > (Car(doors::Int), Bike(gears::Int))
        c = Counter(0)
        c.n = 5
        @test c.n == 5
        @test ismutabletype(Counter)
        @test ismutabletype(Labeled)
        @test ismutabletype(Car)
        @test ismutabletype(Bike)
    end

    @testset "@types default field values" begin
        @types Point2D(x::Float64 = 0.0, y::Float64 = 0.0)
        # positional with defaults
        @test Point2D() == Point2D(0.0, 0.0)
        @test Point2D(1.0) == Point2D(1.0, 0.0)
        @test Point2D(1.0, 2.0) == Point2D(1.0, 2.0)
        # keyword construction
        @test Point2D(x=3.0) == Point2D(3.0, 0.0)
        @test Point2D(y=4.0) == Point2D(0.0, 4.0)
        @test Point2D(x=1.0, y=2.0) == Point2D(1.0, 2.0)
    end

    @testset "@types mixed required and default fields" begin
        @types Config(host::String, port::Int = 8080, timeout::Int = 30)
        @test Config("localhost") == Config("localhost", 8080, 30)
        @test Config("localhost", 9000) == Config("localhost", 9000, 30)
        @test Config("localhost", port=9000) == Config("localhost", 9000, 30)
        @test Config("localhost", timeout=60) == Config("localhost", 8080, 60)
    end

    @testset "@types mutable with defaults" begin
        @types mutable MutPoint(x::Float64 = 0.0, y::Float64 = 0.0)
        p = MutPoint()
        p.x = 5.0
        @test p.x == 5.0
        @test ismutabletype(MutPoint)
        p2 = MutPoint(x=1.0)
        @test p2.x == 1.0 && p2.y == 0.0
    end

    @testset "@types explicit keyword args" begin
        # Required positional + keyword-only with default
        @types Server(host::String; port::Int = 8080)
        s = Server("localhost")
        @test s.host == "localhost" && s.port == 8080
        s2 = Server("localhost", port=9000)
        @test s2.port == 9000

        # Positional with default + keyword-only with default
        @types Request(path::String = "/"; method::String = "GET", timeout::Int = 30)
        r = Request()
        @test r.path == "/" && r.method == "GET" && r.timeout == 30
        r2 = Request("/api", method="POST")
        @test r2.path == "/api" && r2.method == "POST" && r2.timeout == 30

        # Required keyword arg (no default)
        @types Credentials(; username::String, password::String)
        c = Credentials(username="alice", password="secret")
        @test c.username == "alice" && c.password == "secret"
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
