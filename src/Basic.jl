using LForaging
##
fig_dir = "/home/beatriz/Documents/Lforaging/Figures"
pokes = CSV.read("/home/beatriz/Documents/Lforaging/Miscellaneous/Poke_data.csv", DataFrame)
allowmissing!(pokes)

describe(pokes)

transform!(groupby(pokes,[:MOUSE,:DATE, :TRIAL,:SIDE]),
    :IN => (x -> collect(1:length(x))) => :POKE_TRIAL,
    :REWARD => (x -> pushfirst!(Int64.(cumsum(x)[1:end-1].+1),1)) => :BOUT,
    :IN => (i -> round.(i .- i[1], digits = 1)) => :IN_TRIAL,
    [:IN, :OUT] => ((i,o) -> round.(o .- i[1], digits =1)) => :OUT_TRIAL,
)

transform!(groupby(pokes,[:MOUSE,:DATE, :TRIAL,:SIDE, :BOUT]),
    :IN => (i -> round.(i .- i[1], digits = 1)) => :IN_BOUT,
    [:IN, :OUT] => ((i,o) -> round.(o .- i[1], digits =1)) => :OUT_BOUT,
    [:IN, :OUT] => ((i,o) -> round.(o .- i, digits =1)) => :DURATION,
)


trav_df = combine(groupby(pokes,[:MOUSE,:DATE, :TRIAL]),
    :KIND => last => :TRAVEL
)
allowmissing!(trav_df)
transform!(groupby(trav_df,[:MOUSE,:DATE]),
    :TRAVEL => (x -> (pushfirst!(x[1:end-1], missing))) => :TRAVEL
)
pokes = leftjoin(pokes, trav_df, on = [:MOUSE,:DATE,:TRIAL])

transform!(groupby(pokes,[:MOUSE,:DATE, :TRIAL,:SIDE]),
    :IN => (x-> vcat(falses(length(x)-1), [true])) => :LEAVE
)
# pokes[pokes.SIDE .== "travel", :BOUT] .= missing

open_html_table(pokes[1:500,:])

##
@df pokes density(:DURATION, group = :KIND, xrotation = 45)
savefig(joinpath(fig_dir,"Poke_Duration_density.png"))

@df pokes histogram(:DURATION, xrotation = 45, bins = 100)
savefig(joinpath(fig_dir,"Poke_Duration_histogram.png"))
##
fdf = filter(r-> r.SIDE != "travel", pokes)
fdf.MOUSE = categorical(fdf.MOUSE)
fdf.KIND = levels!(categorical(fdf.KIND),["poor", "medium", "rich"])
fdf.SIDE = categorical(fdf.SIDE)
fdf.TRAVEL = levels!(categorical(fdf.TRAVEL),["short", "long"])
fdf.REWARD = categorical(Bool.(fdf.REWARD))
f1 =  @formula(LEAVE ~ 1 + OUT_TRIAL+OUT_BOUT+DURATION+REWARD+TRAVEL+KIND + (1|MOUSE))
gm = fit(MixedModel, f1,fdf, Bernoulli())

##
pltdf = filter(r->r.DURATION <=2,fdf)
poke_rich, poke_rich_df =
    function_analysis(pltdf,:DURATION, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:0.1:2)
plot(poke_rich, ylabel = "Cumulative", xlabel = "Poke duration")
savefig(joinpath(fig_dir,"CumPokeRich.png"))
plt_trav = filter(r-> r.SIDE == "travel" && r.DURATION <=2, pokes)
dropmissing!(plt_trav)
poke_trav, poke_trav_df =
    function_analysis(plt_trav,:DURATION, cumulative_algorythm; grouping = :TRAVEL, calc = :bootstrapping, xaxis = 0:0.1:2)
plot(poke_trav, ylabel = "Cumulative", xlabel = "Poke duration")
savefig(joinpath(fig_dir,"CumPokeTrav.png"))
##
gd = groupby(filter(r->r.SIDE != "travel",pokes),[:MOUSE,:DATE,:TRIAL])
pre_trials = combine(gd) do dd
    DataFrame(
        DURATION_FULL = dd[end, :OUT_TRIAL],
        DURATION_SUM = round.(sum(dd.DURATION),digits =1),
        LAST_BOUT_FULL = dd[dd.LEAVE,:OUT_BOUT],
        LAST_BOUT_SUM = round.(sum(dd[dd.BOUT .== dd[dd.LEAVE,:BOUT],:DURATION]),digits =1),
        REWARDS = maximum(dd.BOUT),
        LAST_REWARD = Bool(dd[end,:REWARD]),
        SIDE = dd[1,:SIDE],
        KIND = dd[1,:KIND]
    )
end
open_html_table(pre_trials)

gd_tr = groupby(filter(r->r.SIDE == "travel",pokes),[:MOUSE,:DATE,:TRIAL])
trials_tr = combine(gd_tr) do dd
    DataFrame(
        TRAVEL_FULL = dd[end, :OUT_TRIAL],
        TRAVEL_SUM = round.(sum(dd.DURATION),digits = 1),
        TRAVEL_KIND = dd[1,:KIND]
    )
end
trials_tr.TRIAL = trials_tr.TRIAL .+1

trials = leftjoin(pre_trials, trials_tr, on = [:MOUSE,:DATE,:TRIAL])
open_html_table(pre_trials)
##
bout_sum_rich, bout_sum_rich_df =
    function_analysis(trials,:LAST_BOUT_SUM, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:0.5:10)
plot(bout_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (SUM)")
savefig(joinpath(fig_dir,"CumBoutSumRich.png"))
bout_full_rich, bout_full_rich_df =
    function_analysis(trials,:LAST_BOUT_FULL, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:1:40)
plot(bout_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (FULL)")
savefig(joinpath(fig_dir,"CumBoutFullRich.png"))
##
trv_pltdf = filter(r->!ismissing(r.TRAVEL_KIND),trials)
bout_sum_rich, bout_sum_rich_df =
    function_analysis(trv_pltdf,:LAST_BOUT_SUM, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:0.5:10)
plot(bout_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (SUM)")
savefig(joinpath(fig_dir,"CumBoutSumTrav.png"))
bout_full_rich, bout_full_rich_df =
    function_analysis(trv_pltdf,:LAST_BOUT_FULL, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:1:40)
plot(bout_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (FULL)")
savefig(joinpath(fig_dir,"CumBoutFullTrav.png"))
##
trial_sum_rich, trial_sum_rich_df =
    function_analysis(trials,:DURATION_SUM, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:1:30)
plot(trial_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (SUM)")
savefig(joinpath(fig_dir,"CumTrialSumRich.png"))
trial_full_rich, trial_full_rich_df =
    function_analysis(trials,:DURATION_FULL, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:5:100)
plot(trial_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (FULL)")
savefig(joinpath(fig_dir,"CumTrialFullRich.png"))
##
trv_pltdf = filter(r->!ismissing(r.TRAVEL_KIND),trials)
trial_sum_rich, trial_sum_rich_df =
    function_analysis(trv_pltdf,:DURATION_SUM, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:1:30)
plot(trial_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (SUM)")
savefig(joinpath(fig_dir,"CumTrialSumTrav.png"))
trial_full_rich, trial_full_rich_df =
    function_analysis(trv_pltdf,:DURATION_FULL, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:5:100)
plot(trial_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (FULL)")
savefig(joinpath(fig_dir,"CumTrialFullTrav.png"))
##
gs0 = trials
gs0.DURATION_FULL = round.(gs0.DURATION_FULL)
filter!(r->r.DURATION_FULL <=60, gs0)
gs1 = combine(groupby(gs0,[:MOUSE,:DURATION_FULL,:KIND]),
    :LAST_BOUT_FULL	.=> [mean,sem]
)

gs2 = combine(groupby(gs1,[:DURATION_FULL,:KIND]),
    :LAST_BOUT_FULL_mean .=> [mean,sem] .=> [:LAST_BOUT_FULL_mean,:LAST_BOUT_FULL_sem]
)

sort!(gs2,:DURATION_FULL)
@df gs2 plot(:DURATION_FULL, :LAST_BOUT_FULL_mean, ribbon = :LAST_BOUT_FULL_sem, group = :KIND,
    xlabel = "Trial Duration (Full)", ylabel = "Last Bout Duration (Full)")
savefig(joinpath(fig_dir,"Full(BoutxTrav)_Kind.png"))
##
gs0 = trials
gs0.DURATION_FULL = round.(gs0.DURATION_FULL)
filter!(r->r.DURATION_FULL <=60, gs0)
gs1 = combine(groupby(gs0,[:MOUSE,:DURATION_FULL,:TRAVEL_KIND]),
    :LAST_BOUT_FULL	.=> [mean,sem]
)

gs2 = combine(groupby(gs1,[:DURATION_FULL,:TRAVEL_KIND]),
    :LAST_BOUT_FULL_mean .=> [mean,sem] .=> [:LAST_BOUT_FULL_mean,:LAST_BOUT_FULL_sem]
)

sort!(gs2,:DURATION_FULL)
filter!(r->!ismissing(r.TRAVEL_KIND), gs2)
@df gs2 plot(:DURATION_FULL, :LAST_BOUT_FULL_mean, ribbon = :LAST_BOUT_FULL_sem, group = :TRAVEL_KIND,
    xlabel = "Trial Duration (Full)", ylabel = "Last Bout Duration (Full)")
savefig(joinpath(fig_dir,"Full(BoutxTrav)_Travel.png"))
##
sum(trials.LAST_REWARD)/nrow(trials)
