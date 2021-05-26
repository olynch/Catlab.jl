using Plots, StatsPlots
using DataFrames, Query
using BenchmarkTools

function graphbench_data(suite)
  data = DataFrame(subcat=String[],bench=String[],platform=String[],
                   mt_normalized=Float64[],mediantime=Float64[])
  graphbenches = suite["Graphs"]
  catlab_times = Dict{Tuple{String,String},Float64}()
  for (subcat,subsuite) in graphbenches
    for (platform,results) in subsuite
      for (bench,result) in results
        if platform == "Catlab"
            catlab_times[(subcat,bench)] = median(result).time
        end
        new_row = (subcat=subcat,
                    bench=bench,
                    platform=platform,
                    mt_normalized=0.,
                    mediantime=median(result).time)
        push!(data, new_row)
      end
    end
  end
  for i in 1:length(data.subcat)
    data[i,:mt_normalized] = data[i,:mediantime] /
      catlab_times[(data[i,:subcat],data[i,:bench])]
  end
  data
end

function subcat_data(dat,subcat)
  dat |>
    @filter(_.subcat==subcat) |>
    @orderby((_.bench,_.platform)) |>
    @select(-:subcat) |>
    DataFrame
end

function plot_subcat(dat,subcat,yscale=:linear)
  subcat_data(dat,subcat) |>
    @df groupedbar(:bench,:mt_normalized,group=:platform,
                   xrotation=45,legend=:outerright,bar_width=0.5,yscale=yscale)
end

function plot_all_subcats(dat)
  for subcat in unique(dat[!,:subcat])
    yscale = subcat ∈ ["WeightedGraph", "LabeledGraph"] ? :log : :linear
    fig = plot_subcat(dat,subcat,yscale)
    savefig(fig, string("figures/",subcat,".pdf"))
  end
end
