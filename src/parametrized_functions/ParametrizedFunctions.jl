module ParametrizedFunctions

export Seg, SegMap, PFDom, PFunction

using ..GAT, ..Theories, ..CategoricalAlgebra.Limits, ..CategoricalAlgebra.FreeDiagrams
using MLStyle
import ..Theories: dom, codom, compose, ⋅, id
import ..CategoricalAlgebra.Limits: limit
import Base: length

struct Seg
  length::Int
end

length(s::Seg) = s.length

struct SegMap
  dom::Seg
  codom::Seg
  range::UnitRange{Int64}
end

@instance Category{Seg, SegMap} begin
  dom(f::SegMap) = f.dom
  codom(f::SegMap) = f.codom
  id(s::Seg) = SegMap(s,s,1:s.length)
  function compose(f::SegMap,g::SegMap)
    @assert codom(f) == dom(g)
    SegMap(dom(f), codom(g), (f.range.start + g.range.start - 1):(f.range.start + g.range.stop - 1))
  end
end

function limit(Xs::DiscreteDiagram{Seg})
  splits = [0;cumsum(length.(Xs))]
  n = Seg(splits[end])
  πs = [SegMap(n,Xs[i],(splits[i]+1):splits[i+1]) for i in 1:length(Xs)]
  Limit(Xs, Multispan(n, πs))
end

(f::SegMap)(v::AbstractVector) = @view v[f.range]

struct PFDom{T}
  seg::Seg
end

function indom(d::PFDom{T}, v::AbstractVector{T}) where {T}
  length(d.seg) == length(v)
end

@data PFunctionImpl{T} begin
  Fun(Function)
  Chain(Vector{Tuple{SegMap, PFunction{T}}})
  Parallel(Vector{Tuple{SegMap, PFunction{T}}})
end

struct PFunction{T}
  dom::PFDom{T}
  codom::PFDom{T}
  P::PFDom{T}
  impl::PFunctionImpl{T}
end

id(d::PFDom{T}) where {T} = PFunction{T}(d, d, PFDom{T}(Seg(0)), Chain(Tuple{SegMap,Function}[]))
otimes(d1::PFDom{T}, d2::PFDom{T}) where {T} = PFDom{T}(Seg(d1.seg.length + d2.seg.length))
munit(::Type{PFDom{T}}) where {T} = PFDom{T}(Seg(0))

function compose(fs::PFunction{T}...) where {T<:Real}
  n = length(fs)
  for i in 1:(n-1)
    @assert fs[i].codom == fs[i+1].dom
  end
  prod = product([f.P.seg for f in fs])
  PFunction{T}(
    fs[1].dom,
    fs[end].codom,
    PFDom{T}(apex(prod.cone)),
    Chain([zip(legs(prod.cone), fs)...])
  )
end

function otimes(fs::PFunction{T}...) where {T<:Real}
  n = length(fs)
  newdom = product([f.dom.seg for f in fs])
  newcodom = product([f.codom.seg for f in fs])
  newP = product([f.P.seg for f in fs])
  PFunction{T}(
    apex(newdom.cone),
    apex(newcodom.cone),
    apex(newP.cone),
    Parallel([zip(legs(newP.cone), fs)...])
  )
end

function braid(f::PFDom{T},g::PFDom{T}) where {T <: Real}
  
end

@instance SymmetricMonoidalCategory{PFDom, PFunction} begin
  @import id, compose, otimes

  dom(f::PFunction) = f.dom
  codom(f::PFunction) = f.codom
end

# function (f::PFunction{T})(p::AbstractVector{T}, x::AbstractVector{T}) where {T}
#   @assert indom(f.dom,x) && indom(f.P, p)
#   y = x
#   for (segmap,g) in f.chain
#     y = g(segmap(p),y)
#   end
#   y
# end

end
