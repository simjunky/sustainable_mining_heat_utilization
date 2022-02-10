
using CSV # CSV is used to read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"
using Indicators # Indicators is used  to compute a simple moving average


include("dataplotting.jl") # contains plot_data function




function run_computation(scenario_directories::Vector{String})
    for directory in scenario_directories
        run(`gams optimization_model.gms --SCENARIO_FOLDER=$directory`)
    end
end

function run_computation()
    run_computation(first(walkdir("./scenarios"))[2])
end




function plot_results(scenario_directories::Vector{String})
    plot_data(scenario_directories)
end

function plot_results()
    plot_results(first(walkdir("./scenarios"))[2])
end




function main(scenario_directories::Vector{String})
    printstyled("running simulation for "*join(scenario_directories, ", ")*"\n", color = :light_green)

    #TODO: check if folders (scen, input, output, plots) and files?? exist.

    #TODO: run gams
    run_computation(scenario_directories)
    #TODO: run plotting
    plot_results(scenario_directories)

    printstyled("programm terminated\n", color = :light_green)
end

function main()
    main(first(walkdir("./scenarios"))[2])
end




if isinteractive()
    printstyled("compiled dependencies\n", color = :light_green)
else
    # specify scenario directories using the command line arguments. If there are none use all sub directories in the scenarios directory.
    scenario_directories = isempty(ARGS) ? first(walkdir("./scenarios"))[2] : ARGS
    main(scenario_directories)
end
