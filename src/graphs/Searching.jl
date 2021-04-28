module Searching
export dfs, bfs, tree_graph

using ...CSetDataStructures, ..BasicGraphs
using DataStructures: Stack, CircularDeque, enqueue!, dequeue!

function _pop!(s::Stack)
  pop!(s)
end

function _pop!(q::CircularDeque)
  pop!(q)
end

function _push!(s::Stack{T}, x::T) where {T}
  push!(s,x)
end

function _push!(q::CircularDeque{T}, x::T) where {T}
  pushfirst!(q,x)
end

function _push_many!(xs, ys)
  for y in ys
    _push!(xs,y)
  end
end

struct Node{T}
  val::T
  children::Vector{Node{T}}
end

function tree_graph!(g::AbstractACSet, n::Node{Int})
  for c in n.children
    add_edge!(g, n.val,c.val)
    tree_graph!(g, c)
  end
end

function tree_graph(root::Node{Int}, max::Int)
  g = Graph(max)
  tree_graph!(g, root)
  return g
end

function reduce_tree(root::Node{Int}, reducer::Function)
  reducer(root.val, map(c -> reduce_tree(c,reducer), root.children)...)
end

function tree_graph(root::Node{Int})
  tree_graph(root, reduce_tree(root, max))
end

function queue_search(q, g::AbstractACSet, start::Int)
  visited = BitSet([start])
  @inline function push_children!(n)
    for c in outneighbors(g,n.val)
      if !(c in visited)
        _push!(q, n => Node{Int}(c,Node{Int}[]))
      end
    end
  end
  root = Node(start, Node{Int}[])
  push_children!(root)
  while !isempty(q)
    parent, a = _pop!(q)
    done = false
    while a.val in visited
      if isempty(q)
        done = true
        break
      end
      parent, a = _pop!(q)
    end
    if done
      break
    end
    push!(visited, a.val)
    push!(parent.children, a)
    push_children!(a)
  end
  return root
end

function dfs(g::AbstractACSet, start::Int)
  queue_search(Stack{Pair{Node{Int},Node{Int}}}(), g, start)
end

function bfs(g::AbstractACSet, start::Int)
  n = nv(g)
  queue_search(CircularDeque{Pair{Node{Int},Node{Int}}}(ne(g)), g, start)
end

end
