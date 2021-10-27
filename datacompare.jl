# This script is used to create comparative plots using data from multipe scenarios.
# Those scenarios can be specified via command line arguments or by changing the code itself.


using CSV # CSV is used to read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"
using Indicators # Indicators is used  to compute a simple moving average


# specify scenario directories using the command line arguments. If there are none use all sub directories in the scenarios directory.
scenario_directories = isempty(ARGS) ? first(walkdir("./scenarios"))[2] : ARGS


# What i want to show:
#TODO: total energy consumption from hot to cold for each group
#TODO: total energy by source from each group
#TODO: total cost/revenue for each location




# plot the hourly temperature over the year for the scenarios with relatively stable temperatures
scenarios_stable = ["Sudan_Karthoum"  "SouthAfrica_CapeTown"  "Denmark_Copenhagen"  "Argentina_RioGrande" "Russia_Magadan"]

plot_temp_stable = plot(title = "temperature profiles\nlocations with moderate fluctuation", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", legend = :outertopright)
plot_avg_temp_stable = plot(title = "average temperature profiles\nlocations with moderate fluctuation", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", legend = :outertopright)

for directory in scenarios_stable

    inputfile = "scenarios/$(directory)/data_output/data_vectors_hourly.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=1, select=[:hour, :temperature_ambient])

    plot!(plot_temp_stable, data[!, :hour], data[!, :temperature_ambient], label = directory)

    plot!(plot_avg_temp_stable, data[!, :hour], sma(data[!, :temperature_ambient], n = 24), label = directory)
end

savefig(plot_temp_stable, "comparison/temp_profiles_moderate.pdf")
savefig(plot_avg_temp_stable, "comparison/temp_profiles_moderate_avg.pdf")




# plot the hourly temperature over the year for the scenarios with relatively volatile temperatures
scenarios_volatile = ["SaudiArabia_Riad" "Pakistan_Islamabad" "Switzerland_Geneva" "Russia_Volgograd" "Mongolia_UlaanBaatar"]

plot_temp_volatile = plot(title = "temperature profiles\nlocations with high fluctuation", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", legend = :outertopright)
plot_avg_temp_volatile = plot(title = "average temperature profiles\nlocations with high fluctuation", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", legend = :outertopright)

for directory in scenarios_volatile

    inputfile = "scenarios/$(directory)/data_output/data_vectors_hourly.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=1, select=[:hour, :temperature_ambient])

    plot!(plot_temp_volatile, data[!, :hour], data[!, :temperature_ambient], label = directory)

    plot!(plot_avg_temp_volatile, data[!, :hour], sma(data[!, :temperature_ambient], n = 24), label = directory)
end

savefig(plot_temp_volatile, "comparison/temp_profiles_volatile.pdf")
savefig(plot_avg_temp_volatile, "comparison/temp_profiles_volatile_avg.pdf")




# plot heating supply  by location in total and by source
source_data = zeros((length(scenarios_stable), 5))
index = 1

for directory in scenarios_stable

    inputfile = "scenarios/$(directory)/data_output/data_vectors_bysource.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        global index += 1
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=1, select=[:source, :total_heat_supply_per_source, :total_heat_drain_per_source])

    source_data[index, 1] = sum(data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source])
    source_data[index, 2:5] = data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source]

    global index += 1
end

plot_supply_stable = groupedbar(source_data, bar_position = :dodge, title = "heat supply (total & by source)\nlocations with moderate fluctuation", xlabel = "locations", ylabel = "heat supply [kWh]", xticks = (1:5, ["Karthoum" "CapeTown" "Copenhagen" "RioGrande" "Magadan"]), label = ["total" "electric" "gas" "mining" "AC"], legend = :outertopright)

savefig(plot_supply_stable, "comparison/supply_bysource_moderate.pdf")
