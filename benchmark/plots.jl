using Plots, StatsPlots
using DataFrames, Query
using BenchmarkTools

function graphbench_data(suite)
  data = DataFrame(subcat=String[],bench=String[],platform=String[],
                   mt_normalized=Float64[],mediantime=Float64[])
  graphbenches = suite["Graphs"]
  catlab_times = Dict{Tuple{String,String},Float64}()
  for (subcat,subsuite) in graphbenches
    for ((bench,platform),result) in subsuite
      if platform == "Catlab"
        catlab_times[(subcat,bench)] = median(result).time
      end
      push!(data, (subcat=subcat,
                   bench=bench,
                   platform=platform,
                   mt_normalized=0.,
                   mediantime=median(result).time))
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

function plot_subcat(dat,subcat)
  subcat_data(dat,subcat) |>
    @df groupedbar(:bench,log.(2,:mt_normalized),group=:platform,
                   xrotation=45,legend=:outerright,bar_width=0.5)
end

