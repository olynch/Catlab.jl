module GATMatch

using Test

using Catlab.GAT
using Catlab.Theories
using Catlab.Present

@present Ex1(FreeCategory) begin
  (A,B,C)::Ob
  f::Hom(A,B)
  g::Hom(B,C)
  finv::Hom(B,A)

  f ⋅ finv == id(A)
end

function idreduce(homexpr)
  @gatmatch homexpr begin
    compose(f,id(B)) ⊣ (A::Ob,B::Ob,f::Hom(A,B)) => f
    compose(id(A),f) ⊣ (A::Ob,B::Ob,f::Hom(A,B)) => f
    _ => homexpr
  end
end

f,g,A,B,C = Ex1[:f],Ex1[:g],Ex1[:A],Ex1[:B],Ex1[:C]

@test idreduce(compose(f,id(B))) == f
@test idreduce(compose(id(B),g)) == g

function idexpand(homexpr)
  @gatmatch homexpr begin
    f ⊣ (A::Ob,B::Ob,f::Hom(A,B)) => compose(id(A),f)
    _ => homexpr
  end
end

@test idexpand(g) == compose(id(B),g)
@test idexpand(id(A)) == compose(id(A),id(A))

@theory Groupoid <: Category begin
  inv(f::Hom(A,B))::Hom(B,A) ⊣ (A::Ob,B::Ob)
  inv(f) ⋅ f == id(B) ⊣ (A::Ob, B::Ob, f::Hom(A,B))
  f ⋅ inv(f) == id(A) ⊣ (A::Ob, B::Ob, f::Hom(A,B))
  inv(id(A)) == id(A)
end

@present Ex2(Groupoid) begin
  (A,B,C)::Ob
  f::Hom(A,B)
  g::Hom(B,C)
end

function invreduce(homexpr)
  @gatmatch homexpr begin
    compose(f,inv(f)) ⊣ (A::Ob,B::Ob,f::Hom(A,B)) => id(A)
    compose(inv(f),f) ⊣ (A::Ob,B::Ob,f::Hom(A,B)) => id(B)
    _ => homexpr
  end
end

@test invreduce(compose(Ex2[:f],inv(Ex2[:f]))) == id(Ex2[:A])
