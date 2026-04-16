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
        @test Config(; host="localhost", port=9000) == Config("localhost", 9000, 30)
        @test Config(; host="localhost", timeout=60) == Config("localhost", 8080, 60)
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

    @testset "@mutable per-subtype" begin
        @types MixedAnimal > (
            MixedCat(lives::Int),
            @mutable MixedDog(name::String)
        )
        @test !ismutabletype(MixedCat)
        @test  ismutabletype(MixedDog)
        @test supertype(MixedCat) === MixedAnimal
        @test supertype(MixedDog) === MixedAnimal
        d = MixedDog("Rex")
        d.name = "Spot"
        @test d.name == "Spot"
    end

    @testset "@const fields" begin
        @types ConstAnimal > (
            ConstCat(lives::Int),
            @mutable ConstDog(@const(name::String), legs::Int)
        )
        @test !ismutabletype(ConstCat)
        @test  ismutabletype(ConstDog)
        @test Base.isconst(ConstDog, :name)
        @test !Base.isconst(ConstDog, :legs)
        d = ConstDog("Rex", 4)
        d.legs = 3
        @test d.legs == 3
        @test_throws ErrorException (d.name = "Spot")

        # @const + defaults should not cause method overwrite errors
        @types ConstAnimal2 > @mutable ConstFoo(@const(a::Int), @const(b::String), c::Int = 1, d::Int = 2)
        f = ConstFoo(10, "hi")
        @test f.a == 10 && f.b == "hi" && f.c == 1 && f.d == 2
        f2 = ConstFoo(; a=10, b="hi", c=3, d=4)
        @test f2.a == 10 && f2.b == "hi" && f2.c == 3 && f2.d == 4
    end

    @testset "docstrings" begin
        @types DocAnimal > (
            "A cat with nine lives.",
            DocCat(lives::Int),
            DocDog(name::String),
            DocBird(wings::Int = 2; can_fly::Bool = true),
        )
        cat_doc = string(@doc(DocCat))
        dog_doc = string(@doc(DocDog))
        bird_doc = string(@doc(DocBird))
        @test occursin("A cat with nine lives.", cat_doc)
        @test occursin("DocAnimal >", dog_doc)
        @test occursin("DocDog(name::String)", dog_doc)
        @test occursin("DocAnimal >", bird_doc)
        @test occursin("DocBird(wings::Int = 2; can_fly::Bool = true)", bird_doc)

        # Nested hierarchy path in auto-doc
        @types DocShape > (
            DocFlat > (
                DocCircle(radius::Float64),
            )
        )
        @test occursin("DocShape > DocFlat >", string(@doc(DocCircle)))
    end

    @testset "autoshow" begin
        @types ShowShape > (
            ShowCircle(radius::Float64),
            ShowRect(width::Float64, height::Float64)
        )
        # Basic show
        @test repr(ShowCircle(3.14)) == "ShowCircle(radius=3.14)"
        @test repr(ShowRect(2.0, 3.0)) == "ShowRect(width=2.0, height=3.0)"

        # Zero-field type
        @types ShowAnimal > (ShowCat, ShowDog)
        @test repr(ShowCat()) == "ShowCat"
        @test repr(ShowDog()) == "ShowDog"

        # Parametric type
        @types ShowBox{T}(value::T)
        @test repr(ShowBox{Int}(42)) == "ShowBox{Int64}(value=42)"

        # Nested types are abbreviated
        @types ShowWrapper(name::String, shape::ShowShape)
        @test repr(ShowWrapper("w", ShowCircle(1.0))) == "ShowWrapper(name=\"w\", shape=ShowCircle(…))"

        # Double nesting
        @types ShowOuter(label::String, inner::ShowWrapper)
        @test repr(ShowOuter("top", ShowWrapper("mid", ShowCircle(1.0)))) ==
            "ShowOuter(label=\"top\", inner=ShowWrapper(…))"

        # Standalone concrete type
        @types ShowPoint(x::Float64, y::Float64)
        @test repr(ShowPoint(1.0, 2.0)) == "ShowPoint(x=1.0, y=2.0)"

        # Standalone concrete type with supertype
        @types ShowBase
        @types ShowChild(n::Int) <: ShowBase
        @test repr(ShowChild(5)) == "ShowChild(n=5)"

        # Non-terse types in fields are shown normally
        @types ShowMixed(n::Int, s::String, v::Vector{Int})
        @test repr(ShowMixed(1, "hi", [1,2,3])) == "ShowMixed(n=1, s=\"hi\", v=[1, 2, 3])"
    end

    @testset "bare parametric subtypes" begin
        @types Geometry > (
            GPoint,
            GCurve > (
                GLine,
                GLineString,
            ),
            GSurface > (
                GPolygon,
            ),
            GGeometryCollection > (
                GMulti{T}
            )
        )
        @test supertype(GPoint) === Geometry
        @test supertype(GLine) === GCurve
        @test supertype(GMulti{Int}) === GGeometryCollection
        @test GMulti{String}() isa GGeometryCollection
    end

    @testset "@hide fields" begin
        # Standalone type
        @types HidePoint(x::Float64, @hide(y::Float64))
        @test HidePoint(1.0, 2.0).y == 2.0
        @test repr(HidePoint(1.0, 2.0)) == "HidePoint(x=1.0)"

        # Hierarchy
        @types HideAnimal > (
            HideCat(lives::Int, @hide(secret::String)),
            HideDog(@hide(id::Int), name::String),
        )
        @test repr(HideCat(9, "whiskers")) == "HideCat(lives=9)"
        @test repr(HideDog(42, "Rex")) == "HideDog(name=\"Rex\")"
        @test HideDog(42, "Rex").id == 42

        # All fields hidden
        @types HideSecret(@hide(x::Int), @hide(y::Int))
        @test repr(HideSecret(1, 2)) == "HideSecret"

        # @hide + @const combo
        @types mutable HideConst(@hide(@const(id::Int)), name::String)
        h = HideConst(1, "test")
        @test repr(h) == "HideConst(name=\"test\")"
        @test h.id == 1
        @test Base.isconst(HideConst, :id)

        # @hide in keyword fields
        @types HideKW(name::String; @hide(debug::Bool) = false)
        @test repr(HideKW("hi")) == "HideKW(name=\"hi\")"
        @test HideKW("hi").debug == false
    end

    @testset "@esc escape hatch" begin
        @types EscAnimal > (
            EscCat(lives::Int),
            EscDog(name::String),
            @esc(sound(x::EscCat) = "meow"),
            @esc(sound(x::EscDog) = "woof"),
        )
        @test supertype(EscCat) === EscAnimal
        @test supertype(EscDog) === EscAnimal
        @test sound(EscCat(9)) == "meow"
        @test sound(EscDog("Rex")) == "woof"
    end

    @testset "parametric types with defaults/kwargs" begin
        # Parametric + keyword args (standalone)
        @types PRegion{G, E}(geometry::G; extent::E = nothing)
        r = PRegion("hello")
        @test r.geometry == "hello" && r.extent === nothing
        r2 = PRegion("hello"; extent=42)
        @test r2.geometry == "hello" && r2.extent == 42
        @test r2 isa PRegion{String, Int}

        # Parametric + positional defaults (standalone)
        @types PPair{A, B}(first::A, second::B = nothing)
        @test PPair(1).second === nothing
        @test PPair(1, "hi") isa PPair{Int, String}
        @test PPair(1; second="hi") isa PPair{Int, String}

        # Parametric + keyword args in hierarchy
        @types PShape{T} > (
            PCircle{T}(radius::T; label::String = "circle"),
            PSquare{T}(side::T),
        )
        @test PCircle(3.0) isa PShape{Float64}
        @test PCircle(3.0).label == "circle"
        @test PCircle(3.0; label="big") isa PShape{Float64}
    end

    @testset "computed constructors" begin
        # Standalone
        @types Polar(x, y) = new(r::Float64 = hypot(x, y), θ::Float64 = atan(y, x))
        p = Polar(3.0, 4.0)
        @test p.r ≈ 5.0
        @test p.θ ≈ atan(4.0, 3.0)
        @test !hasproperty(p, :x)

        # With supertype
        @types CoordBase
        @types PolarCoord(x, y) <: CoordBase = new(r::Float64 = hypot(x, y))
        @test supertype(PolarCoord) === CoordBase
        @test PolarCoord(3.0, 4.0).r ≈ 5.0

        # In hierarchy
        @types Transform > (
            Scale(factor::Float64) = new(matrix::Vector{Float64} = [factor, factor]),
            Translate(dx::Float64, dy::Float64) = new(offset::Vector{Float64} = [dx, dy]),
        )
        @test supertype(Scale) === Transform
        @test Scale(2.0).matrix == [2.0, 2.0]
        @test Translate(1.0, 2.0).offset == [1.0, 2.0]

        # Mutable
        @types mutable MutPolar(x, y) = new(r::Float64 = hypot(x, y))
        mp = MutPolar(3.0, 4.0)
        @test mp.r ≈ 5.0
        mp.r = 10.0
        @test mp.r == 10.0

        # Parametric
        @types ParamSum{T}(a::T, b::T) = new(total::T = a + b)
        @test ParamSum(1, 2).total == 3
        @test ParamSum(1.0, 2.0) isa ParamSum{Float64}

        # Autoshow works
        @test repr(Polar(3.0, 4.0)) == "Polar(r=5.0, θ=$(repr(atan(4.0, 3.0))))"
    end

    @testset "extend existing abstract type" begin
        abstract type ExistingAnimal end
        @types ExistingAnimal > (
            ExCat(lives::Int),
            ExDog(name::String)
        )
        @test supertype(ExCat) === ExistingAnimal
        @test supertype(ExDog) === ExistingAnimal
        @test ExCat(9) isa ExistingAnimal
        @test repr(ExDog("Rex")) == "ExDog(name=\"Rex\")"

        # Parametric existing abstract type
        abstract type ExistingContainer{T} end
        @types ExistingContainer{T} > (
            ExBox{T}(value::T),
        )
        @test supertype(ExBox{Int}) === ExistingContainer{Int}

        # Error on concrete type
        @types ExConcreteType(x::Int)
        @test_throws LoadError eval(:(@types ExConcreteType > (Foo(x::Int),)))
    end
end
