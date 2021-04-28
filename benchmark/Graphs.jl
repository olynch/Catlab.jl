# Benchmark Catlab.Graphs against LightGraphs and MetaGraphs.
using BenchmarkTools
const SUITE = BenchmarkGroup()

using Random
import LightGraphs, MetaGraphs
const LG, MG = LightGraphs, MetaGraphs

using Catlab, Catlab.CategoricalAlgebra, Catlab.Graphs
using Catlab.Graphs.BasicGraphs: TheoryGraph

testdatadir = joinpath(dirname(@__FILE__), "..", "test", "testdata")

# Example Graphs
# 
################
  
# Stolen from the Lightgraphs benchmark suite

dg1fn = joinpath(testdatadir, "graph-50-500.jgz")

LG_GRAPHS = Dict{String,LG.DiGraph}(
    "complete100"   => LG.complete_digraph(100),
    # "5000-50000"    => LG.loadgraph(dg1fn)["graph-5000-50000"],
    "path500"       => LG.path_digraph(500)
)

GRAPHS = Dict(k => from_lightgraph(g) for (k,g) in LG_GRAPHS)

LG_SYMGRAPHS = Dict{String,LG.Graph}(
    "complete100"   => LG.complete_graph(100),
    "tutte"         => LG.smallgraph(:tutte),
    "path500"       => LG.path_graph(500),
    # "5000-49947"    => LG.SimpleGraph(DIGRAPHS["5000-50000"])
)

SYMGRAPHS = Dict(k => from_lightgraph(g) for (k,g) in LG_SYMGRAPHS)


# Helpers
#
########

# `bench_iter_edges` and `bench_has_edge` adapted from LightGraphs:
# https://github.com/JuliaGraphs/LightGraphs.jl/blob/master/benchmark/core.jl

function bench_iter_edges(g)
  count = 0
  for e in edges(g)
    s, t = src(g,e), tgt(g,e)
    count += 1
  end
  count
end
function bench_iter_edges_vectorized(g)
  count = 0
  for (s,t) in zip(src(g), tgt(g))
    count += 1
  end
  count
end

function bench_has_edge(g)
  Random.seed!(1)
  n = nv(g)
  srcs, tgts = rand(1:n, n÷4), rand(1:n, n÷4)
  count = 0
  for (s, t) in zip(srcs, tgts)
    if has_edge(g, s, t)
      count += 1
    end
  end
  count
end

function bench_iter_neighbors(g)
  count = 0
  for v in vertices(g)
    count += length(neighbors(g, v))
  end
  count
end

@inline Graphs.nv(g::LG.AbstractGraph) = LG.nv(g)
@inline Graphs.vertices(g::LG.AbstractGraph) = LG.vertices(g)
@inline Graphs.edges(g::LG.AbstractGraph) = LG.edges(g)
@inline Graphs.src(g::LG.AbstractGraph, e::LG.AbstractEdge) = LG.src(e)
@inline Graphs.tgt(g::LG.AbstractGraph, e::LG.AbstractEdge) = LG.dst(e)
@inline Graphs.has_edge(g::LG.AbstractGraph, args...) = LG.has_edge(g, args...)
@inline Graphs.neighbors(g::LG.AbstractGraph, args...) = LG.neighbors(g, args...)

function lg_connected_components_projection(g)
  label = Vector{Int}(undef, LG.nv(g))
  LG.connected_components!(label, g)
end

# Graphs
########

bench = SUITE["Graph"] = BenchmarkGroup()

n = 10000
bench[("make-path", "Catlab")] = @benchmarkable path_graph(Graph,n)

bench[("make-path", "LightGraphs")] = @benchmarkable begin
  g = LG.DiGraph()
  LG.add_vertices!(g, n)
  for v in 1:(n-1)
    LG.add_edge!(g, v, v+1)
  end
end

g = path_graph(Graph, n)
lg = LG.DiGraph(g)

bench[("iter-edges", "Catlab")] = @benchmarkable bench_iter_edges($g)
bench[("iter-edges", "Catlab-vectorized")] = @benchmarkable bench_iter_edges_vectorized($g)
bench[("iter-edges", "LightGraphs")] = @benchmarkable bench_iter_edges($lg)
bench[("has-edge", "Catlab")] = @benchmarkable bench_has_edge($g)
bench[("has-edge", "LightGraphs")] = @benchmarkable bench_has_edge($lg)
bench[("iter-neighbors", "Catlab")] = @benchmarkable bench_iter_neighbors($g)
bench[("iter-neighbors", "LightGraphs")] = @benchmarkable bench_iter_neighbors($lg)

n₀ = 2000
g₀ = path_graph(Graph, n₀)
g = ob(coproduct(fill(g₀, 5)))
lg = LG.DiGraph(g)
bench[("path-graph-components","Catlab")] = @benchmarkable connected_components($g)
bench[("path-graph-components","Catlab-proj")] =
  @benchmarkable connected_component_projection($g)
bench[("path-graph-components","LightGraphs")] =
  @benchmarkable LG.weakly_connected_components($lg)

g₀ = star_graph(Graph, n₀)
g = ob(coproduct(fill(g₀, 5)))
lg = LG.DiGraph(g)
bench[("star-graph-components","Catlab")] = @benchmarkable connected_components($g)
bench[("star-graph-components","Catlab-proj")] =
  @benchmarkable connected_component_projection($g)
bench[("star-graph-components","LightGraphs")] =
  @benchmarkable LG.weakly_connected_components($lg)

bench = SUITE["GraphConnComponents"] = BenchmarkGroup()

for gn in keys(GRAPHS)
  bench[(gn,"Catlab")] = @benchmarkable connected_component_projection($(GRAPHS[gn]))
  bench[(gn,"LightGraphs")] = @benchmarkable lg_connected_components_projection($(LG_GRAPHS[gn]))
end

# Symmetric graphs
##################

bench = SUITE["SymmetricGraph"] = BenchmarkGroup()

n = 10000
bench[("make-path", "Catlab")] = @benchmarkable path_graph(SymmetricGraph, n)

bench[("make-path", "LightGraphs")] = @benchmarkable begin
  g = LG.Graph()
  LG.add_vertices!(g, n)
  for v in 1:(n-1)
    LG.add_edge!(g, v, v+1)
  end
end

g = path_graph(SymmetricGraph, n)
lg = LG.Graph(g)

bench[("iter-edges","Catlab")] = @benchmarkable bench_iter_edges($g)
bench[("iter-edges","Catlab-vectorized")] = @benchmarkable bench_iter_edges_vectorized($g)
bench[("iter-edges","LightGraphs")] = @benchmarkable bench_iter_edges($lg)
bench[("has-edge", "Catlab")] = @benchmarkable bench_has_edge($g)
bench[("has-edge", "LightGraphs")] = @benchmarkable bench_has_edge($lg)
bench[("iter-neighbors", "Catlab")] = @benchmarkable bench_iter_neighbors($g)
bench[("iter-neighbors", "LightGraphs")] = @benchmarkable bench_iter_neighbors($lg)

bench = SUITE["SymmetricGraphConnComponent"] = BenchmarkGroup()

for gn in keys(SYMGRAPHS)
  bench[(gn,"Catlab")] = @benchmarkable connected_component_projection($(SYMGRAPHS[gn]))
  bench[(gn,"LightGraphs")] = @benchmarkable lg_connected_components_projection($(LG_SYMGRAPHS[gn]))
end

# Weighted graphs
#################

bench = SUITE["WeightedGraph"] = BenchmarkGroup()

n = 10000
g = path_graph(WeightedGraph{Float64}, n; E=(weight=range(0,1,length=n-1),))
mg = MG.MetaDiGraph(g)

bench[("sum-weights","Catlab-vectorized")] = @benchmarkable sum(weight($g))
bench[("sum-weights", "Catlab")] = @benchmarkable begin
  total = 0.0
  for e in edges($g)
    total += weight($g, e)
  end
  total
end
bench[("sum-weights","MetaGraphs")] = @benchmarkable begin
  total = 0.0
  for e in MG.edges($mg)
    total += MG.get_prop($mg, e, :weight)
  end
  total
end

bench[("increment-weights","Catlab-vectorized")] = @benchmarkable begin
  $g[:weight] = $g[:weight] .+ 1.0
end
bench[("increment-weights","Catlab")] = @benchmarkable begin
  for e in edges($g)
    $g[e,:weight] += 1.0
  end
end
bench[("increment-weights", "MetaGraphs")] = @benchmarkable begin
  for e in MG.edges($mg)
    MG.set_prop!($mg, e, :weight, MG.get_prop($mg, e, :weight) + 1.0)
  end
end

# Labeled graphs
################

bench = SUITE["LabeledGraph"] = BenchmarkGroup()

@present TheoryLabeledGraph <: TheoryGraph begin
  Label::Data
  label::Attr(V,Label)
end
const LabeledGraph = ACSetType(TheoryLabeledGraph, index=[:src,:tgt])
const IndexedLabeledGraph = ACSetType(TheoryLabeledGraph, index=[:src,:tgt],
                                      unique_index=[:label])

function discrete_labeled_graph(n::Int; indexed::Bool=false)
  g = (indexed ? IndexedLabeledGraph{String} : LabeledGraph{String})()
  add_vertices!(g, n, label=("v$i" for i in 1:n))
  g
end

function discrete_labeled_metagraph(n::Int; indexed::Bool=false)
  mg = MG.MetaDiGraph()
  for i in 1:n
    MG.add_vertex!(mg, :label, "v$i")
  end
  if indexed; MG.set_indexing_prop!(mg, :label) end
  mg
end

n = 5000
bench[("make-discrete","Catlab")] = @benchmarkable discrete_labeled_graph($n)
bench[("make-discrete","MetaGraphs")] = @benchmarkable discrete_labeled_metagraph($n)
bench[("make-discrete-indexed", "Catlab")] =
  @benchmarkable discrete_labeled_graph($n, indexed=true)
bench[("make-discrete-indexed", "MetaGraphs")] =
  @benchmarkable discrete_labeled_metagraph($n, indexed=true)

n = 10000
g = discrete_labeled_graph(n)
mg = discrete_labeled_metagraph(n)
bench[("iter-labels","Catlab")] = @benchmarkable begin
  for v in vertices($g)
    label = $g[v,:label]
  end
end
bench[("iter-labels","MetaGraphs")] = @benchmarkable begin
  for v in MG.vertices($mg)
    label = MG.get_prop($mg, v, :label)
  end
end

g = discrete_labeled_graph(n, indexed=true)
mg = discrete_labeled_metagraph(n, indexed=true)
Random.seed!(1)
σ = randperm(n)
bench[("indexed-lookup","Catlab")] = @benchmarkable begin
  for i in $σ
    @assert incident($g, "v$i", :label) == i
  end
end
bench[("indexed-lookup","MetaGraphs")] = @benchmarkable begin
  for i in $σ
    @assert $mg["v$i", :label] == i
  end
end

# Random Graphs
###############

bench = SUITE["RandomGraph"] = BenchmarkGroup()

sizes = [10,100,1000,10000]
ps = [0.001,0.1, 0.5]
for size in sizes, p in ps
  bench[("erdos_renyi-$size-$p", "Catlab")] =
    @benchmarkable erdos_renyi($Graph, $size, $p)
  bench[("erdos_renyi-$size-$p", "LightGraphs")] =
    @benchmarkable LightGraphs.erdos_renyi($size, $p)
end

ks = [2,10,20]

for size in sizes, k in ks
  bench[("expected_degree_graph-$size-$k", "Catlab")] =
    @benchmarkable expected_degree_graph($Graph, $([min(k,size-1) for _ in 1:size]))
  bench[("expected_degree_graph-$size-$k", "LightGraphs")] =
    @benchmarkable LightGraphs.expected_degree_graph($([min(k,size-1) for _ in 1:size]))
end

for size in sizes, k in ks
  bench[("watts_strogatz-$size-$k", "Catlab")] =
    @benchmarkable watts_strogatz($Graph, $size, $(min(k,size-1)), 0.5)
  bench[("watts_strogatz-$size-$k", "LightGraphs")] =
    @benchmarkable LightGraphs.watts_strogatz($size, $(min(k,size-1)), 0.5)
end
  
# Searching
###########


