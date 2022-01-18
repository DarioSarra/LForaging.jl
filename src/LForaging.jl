module LForaging

using Reexport
@reexport using DataFrames, CategoricalArrays, CSV, StatsPlots, BrowseTables, StatsBase, Bootstrap, MixedModels
import Statistics: median, std

include("Analysis_fun.jl")

export survivalrate_algorythm, cumulative_algorythm, hazardrate_algorythm, function_analysis
export median, std

end # module
