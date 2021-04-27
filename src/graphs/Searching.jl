module Searching
export dfs, bfs

using ...CSetDataStructures, ..BasicGraphs
using DataStructures: Stack, Queue, enqueue!, dequeue!

function _pop!(s::Stack)
  pop!(s)
end

function _pop!(q::Queue)
  dequeue!(q)
end

function _push!(s::Stack{T}, x::T) where {T}
  push!(s,x)
end

function _push!(q::Queue{T}, x::T) where {T}
  enqueue!(q,x)
end

function _push_many!(xs, ys)
  for y in ys
    _push!(xs,y)
  end
end

function queue_search(::Type{T}, g::AbstractACSet, start::Int, pred::Function) where {T}
  q = T{Int}()
  _push_many!(q, outneighbors(g, start))
  while !isempty(q)
    a = _pop!(q)
    if pred(g,a)
      return a
    end
    _push_many!(q, outneighbors(g, a))
  end
  return nothing
end

function dfs(g::AbstractACSet, start::Int, pred::Function)
  queue_search(Stack, g, start, pred)
end

function bfs(g::AbstractACSet, start::Int, pred::Function)
  queue_search(Queue, g, start, pred)
end

end
