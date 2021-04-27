module TestSearching

using Test

using Catlab.Graphs.BasicGraphs, Catlab.Graphs.Searching
using Catlab.Present, Catlab.CSetDataStructures
import Catlab.Graphs.BasicGraphs: TheoryGraph

@present TheoryLabelledGraph <: TheoryGraph begin
  T::Data
  label::Attr(V,T)
end

const LabelledGraph = ACSetType(TheoryLabelledGraph, index=[:src,:tgt])

g = @acset LabelledGraph{Symbol} begin
  V = 5
  E = 4
  src = [1,2,3,1]
  tgt = [5,3,4,2]
  label = [:nocookie, :nocookie, :nocookie, :cookie, :cookie]
end

@test bfs(g,1,(g,i) -> subpart(g,i,:label) == :cookie) == 5
@test dfs(g,1,(g,i) -> subpart(g,i,:label) == :cookie) == 4

end
