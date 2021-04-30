module ParametrizedFunctions

using ..GAT, ..Theories, ..CategoricalAlgebra.Limits

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
  n = Seg(sum(length.(Xs)))
  splits = [0;cumsum(length.(Xs))]
  πs = [SegMap(n,Xs[i],(splits[i]+1):splits[i+1]) for i in eachindex(Xs)]
  Limit(Xs, Multispan(Seg(n), πs))
end

(f::SegMap)(v::AbstractVector) = @view v[f.range]

struct PFDom{T}
  seg::Seg
end

function indom(d::PFDom{T}, v::AbstractVector{T}) where {T}
  length(d.seg) == length(v)
end

struct PFunction{T}
  dom::PFDom{T}
  codom::PFDom{T}
  P::PFDom{T}
  chain::Vector{Tuple{SegMap,Function}}
end

_id(d::PFDom{T}) where {T} = PFunction{T}(d, d, PFDom{T}(Seg(0)), Tuple{SegMap,Function}[])

function _compose(fs::PFunction{T}...) where {T<:Real}
  n = length(fs)
  for i in 1:(n-1)
    @assert fs[i].codom == fs[i+1].dom
  end
  prod = product([f.P for f in fs])
  PFunction{T}(
    fs[1].dom,
    fs[end].codom,
    apex(prod.cone),
    vcat([(compose(legs(prod.cone)[i], segmap), f) for (segmap,f) in fs[i].chain] for i in 1:n)
  )
end

@instance Category{PFDom, PFunction} begin
  dom(f::PFunction) = f.dom
  codom(f::PFunction) = f.codom
  id(d::PFDom) = _id(d)
  compose(fs::PFunction...) = _compose(fs...)
end

function (f::PFunction{T})(p::AbstractVector{T}, x::AbstractVector{T}) where {T}
  @assert indom(f.dom,x) && indom(f.P, p)
  y = x
  for (segmap,g) in f.chain
    y = g(segmap(p),y)
  end
  y
end

end
