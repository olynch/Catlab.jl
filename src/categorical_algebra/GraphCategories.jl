""" Categories of graphs and other categorical and algebraic aspects of graphs.
"""
module GraphCategories

using ..FinSets, ..CSets, ..Limits
using ...Graphs.BasicGraphs
import ...Graphs.GraphAlgorithms: connected_component_projection, connected_component_projection_bfs

using DataStructures: Queue, enqueue!, dequeue!

function connected_component_projection(g::AbstractACSet)::FinFunction
  proj(coequalizer(FinFunction(src(g), nv(g)),
                   FinFunction(tgt(g), nv(g))))
end

# This algorithm is linear in the number of vertices of g, so it should be
# significantly faster than the previous one in some cases.
function connected_component_projection_bfs(g::AbstractACSet)
  label = zeros(Int, nv(g))

  for v in 1:nv(g)
    label[v] != 0 && continue
    label[v] = v
    q = Queue{Int}()
    enqueue!(q, v)
    while !isempty(q)
      src = dequeue!(q)
      for vertex in neighbors(g, src)
        if label[vertex] == 0
          enqueue!(q,vertex)
          label[vertex] = v
        end
      end
    end
  end
  
  normalize_labeling(label)
end

end
