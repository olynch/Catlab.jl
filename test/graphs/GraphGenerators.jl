module TestGraphGenerators
using Test
using Statistics: mean

using Catlab.Graphs.BasicGraphs, Catlab.Graphs.GraphGenerators

# Path graphs
#------------

n = 5
g = path_graph(Graph, n)
@test (nv(g), ne(g)) == (n, n-1)
g = path_graph(SymmetricGraph, n)
@test (nv(g), ne(g)) == (n, 2(n-1))

# Cycle graphs
#-------------

g = cycle_graph(Graph, n)
@test (nv(g), ne(g)) == (n, n)
g = cycle_graph(SymmetricGraph, n)
@test (nv(g), ne(g)) == (n, 2n)

# Complete graphs
#----------------

for T in (Graph, SymmetricGraph)
  g = complete_graph(T, n)
  @test (nv(g), ne(g)) == (n, n*(n-1))
end
for T in (ReflexiveGraph, SymmetricReflexiveGraph)
  g = complete_graph(T, n)
  @test (nv(g), ne(g)) == (n, n*n)
end

# Star graphs
#------------

g = star_graph(Graph, n)
@test (nv(g), ne(g)) == (n, n-1)
@test length(unique(src(g,e) for e in edges(g))) == 1
g = star_graph(SymmetricGraph, n)
@test (nv(g), ne(g)) == (n, 2(n-1))

# Erdős-Rényi random graphs
#--------------------------

g = erdos_renyi(Graph, n, 2n)
@test (nv(g), ne(g)) == (n, 2n)
g = erdos_renyi(SymmetricGraph, n, 2n)
@test (nv(g), ne(g)) == (n, 4n)

p = 0.4
# DO YOU BELIEVE IN THE LAW OF LARGE NUMBERS???
gs = [erdos_renyi(Graph, n, p) for i in 1:100]
@test isapprox(mean(ne.(gs)), p * n * (n-1); atol=0.5)

# Expected Degree Graphs
#-----------------------

# Note: if you do this with larger expected degrees, it will not work
# Not a good algorithm
gs = [expected_degree_graph(Graph, [0.05 for _ in 1:100]) for _ in 1:1000]
@test isapprox(mean(mean.(degree.(gs))), 0.05; atol=0.01)

# Watts-Strogatz
#----------------

gs = [watts_strogatz(Graph, n, 2, 0.0) for _ in 1:100]
@test all(gs) do g
  all(2 .== degree(g))
end
gs = [watts_strogatz(Graph, n, 2, 0.5) for _ in 1:100]
@test all(gs) do g
  ne(g) == n
end

end
