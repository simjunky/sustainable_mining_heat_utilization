# This script is used to create comparative plots using data from multipe scenarios.
# Those scenarios can be specified via command line arguments or by changing the code itself.


using CSV # CSV is used to read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"
using Indicators # Indicators is used  to compute a simple moving average


# specify scenario directories using the command line arguments. If there are none use all sub directories in the scenarios directory.
#scenario_directories = isempty(ARGS) ? first(walkdir("./scenarios"))[2] : ARGS


# What i want to show:
#TODO: total energy consumption from hot to cold for each group
#TODO: total energy by source from each group
#TODO: total cost/revenue for each location


# set color theme and palette for the plots
theme(:default, palette = [:darkorange1, :deepskyblue, :lawngreen, :red2, :cyan, :magenta2])


# plot the hourly temperature over the year for the scenarios with relatively stable temperatures
scenarios_stable = ["Sudan_Khartoum"  "SouthAfrica_CapeTown"  "Denmark_Copenhagen"  "Argentina_RioGrande" "Russia_Magadan"]

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

    plot!(plot_avg_temp_stable, data[!, :hour], sma(Array(data.temperature_ambient), n = 24), label = directory)
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

    plot!(plot_avg_temp_volatile, data[!, :hour], sma(Array(data.temperature_ambient), n = 24), label = directory)
end

savefig(plot_temp_volatile, "comparison/temp_profiles_volatile.pdf")
savefig(plot_avg_temp_volatile, "comparison/temp_profiles_volatile_avg.pdf")




# plot heating supply  by location in total and by source
source_data = zeros((length(scenarios_stable), 6))
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
    source_data[index, 2:6] = data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source]

    global index += 1
end

plot_supply_stable = groupedbar(source_data, bar_position = :dodge, title = "heat supply (total & by source)\nlocations with moderate fluctuation", xlabel = "locations", ylabel = "heat supply [kWh]", xticks = (1:5, ["Khartoum" "CapeTown" "Copenhagen" "RioGrande" "Magadan"]), label = ["total" "electric" "mining" "AC" "gas" "pv"], legend = :outertopright)

savefig(plot_supply_stable, "comparison/supply_bysource_temp_moderate.pdf")





# plot heating supply  by location in total and by source
source_data = zeros((length(scenarios_volatile), 6))
index = 1

for directory in scenarios_volatile

    inputfile = "scenarios/$(directory)/data_output/data_vectors_bysource.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        global index += 1
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=1, select=[:source, :total_heat_supply_per_source, :total_heat_drain_per_source])

    source_data[index, 1] = sum(data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source])
    source_data[index, 2:6] = data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source]

    global index += 1
end

plot_supply_volatile = groupedbar(source_data, bar_position = :dodge, title = "heat supply (total & by source)\nlocations with high fluctuation", xlabel = "locations", ylabel = "heat supply [kWh]", xticks = (1:5, ["Riad" "Islamabad" "Geneva" "Volgograd" "Ulaan Baatar"]), label = ["total" "electric" "mining" "AC" "gas" "pv"], legend = :outertopright)
savefig(plot_supply_volatile, "comparison/supply_bysource_temp_volatile.pdf")





scenarios_btc_price = ["Germany_Stuttgart_local_BTC_1" "Germany_Stuttgart_local_BTC_2" "Germany_Stuttgart_local_BTC_3" "Germany_Stuttgart_local_BTC_4" "Germany_Stuttgart_local_BTC_5" "Germany_Stuttgart_local_BTC_6" "Germany_Stuttgart_local_BTC_7" "Germany_Stuttgart_local_BTC_8"]

# plot heating supply  by location in total and by source
source_data = zeros((length(scenarios_btc_price), 3))
index = 1

for directory in scenarios_btc_price

    inputfile = "scenarios/$(directory)/data_output/data_scalars.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        global index += 1
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=0)

    # first the total annual cost
    source_data[index, 1] = sum(data[1,2])
    # then the total annual mining revenue
    source_data[index, 2] = sum(data[4,2])
    # then the total annual heating (fuel) cost
    source_data[index, 3] = sum(data[8,2])

    global index += 1
end

plot_btc_price = plot(title = "Total annual costs and revenue\ndepending on BTC-price", xlabel = "BTC price [k\$]", ylabel = "cost / revenue [k\$]", legend = :outertopright)

btc_prices = [30000, 35000, 40000, 45000, 50000, 55000, 60000, 65000]
plot!(plot_btc_price, btc_prices / 1000, source_data[:, 1]  / 1000, label = "total cost")
plot!(plot_btc_price, btc_prices  / 1000, source_data[:, 2]  / 1000, label = "mining revenue")
plot!(plot_btc_price, btc_prices  / 1000, source_data[:, 3]  / 1000, label = "heating cost")

savefig(plot_btc_price, "comparison/cost_&_mining_revenue_BTC.pdf")




scenarios_elec_price = ["Germany_Stuttgart_Elec_1" "Germany_Stuttgart_Elec_2" "Germany_Stuttgart_Elec_3" "Germany_Stuttgart_Elec_4" "Germany_Stuttgart_Elec_5" "Germany_Stuttgart_Elec_6" "Germany_Stuttgart_Elec_7"]

# plot heating supply  by location in total and by source
source_data = zeros((length(scenarios_elec_price), 4))
cost_data = zeros((length(scenarios_elec_price), 3))
index = 1

for directory in scenarios_elec_price

    inputfile = "scenarios/$(directory)/data_output/data_vectors_bysource.csv"
    inputfile2 = "scenarios/$(directory)/data_output/data_scalars.csv"

    # skip scenario if input files do not exist and inform about it
    if(!isfile(inputfile))
        printstyled("$(inputfile) not found\n", color = :light_red)
        global index += 1
        continue
    end

    data = CSV.read(inputfile, DataFrame; delim=',', header=1, select=[:source, :total_heat_supply_per_source, :total_heat_drain_per_source])
    data2 = CSV.read(inputfile2, DataFrame; delim=',', header=0)

    # total heating
    source_data[index, 1] = sum(data[!, :total_heat_supply_per_source] - data[!, :total_heat_drain_per_source])

    # mining heat supply
    source_data[index, 2] = data[2, :total_heat_supply_per_source]

    # ac heat supply
    source_data[index, 3] = data[3, :total_heat_supply_per_source]

    # ac heat drain
    source_data[index, 4] = data[3, :total_heat_drain_per_source]

    # first the total annual cost
    cost_data[index, 1] = sum(data2[1,2])
    # then the total annual mining revenue
    cost_data[index, 2] = sum(data2[4,2])
    # then the total annual heating (fuel) cost
    cost_data[index, 3] = sum(data2[8,2])

    global index += 1
end

elec_prices = [0.15, 0.18, 0.2, 0.23, 0.25, 0.28, 0.30]

plot_supply_elec = groupedbar(source_data, bar_position = :dodge, title = "heat supply (total & by source)\nfor different electricity prices", xlabel = "electricity prices [\$]", ylabel = "heat supply [kWh]", xticks = (1:7, elec_prices), label = ["total" "mining" "AC-heating" "AC-cooling"], legend = :outertopright)

savefig(plot_supply_elec, "comparison/supply_bysource_elec.pdf")

plot_elec_price = plot(title = "Total annual costs and revenue\ndepending on electricity price", xlabel = "electricity price [\$]", ylabel = "cost / revenue [k\$]", legend = :outertopright)

plot!(plot_elec_price, elec_prices, cost_data[:, 1]  / 1000, label = "total cost")
plot!(plot_elec_price, elec_prices, cost_data[:, 2]  / 1000, label = "mining revenue")
plot!(plot_elec_price, elec_prices, cost_data[:, 3]  / 1000, label = "heating cost")

savefig(plot_elec_price, "comparison/cost_&_mining_revenue_elec.pdf")




inputfile_model = "scenarios/Germany_Stuttgart_HeatDataComparison_onlyE/data_output/data_vectors_hourly.csv"
inputfile_data = "scenarios/Germany_Stuttgart_HeatDataComparison_onlyE/data_input/hourly_heat_load.csv"

#TODO: check if file exists

data_model = CSV.read(inputfile_model, DataFrame; delim=',', header=1, select=[:hour, :total_heat_supply_per_hour, :total_heat_drain_per_hour])
data_data = CSV.read(inputfile_data, DataFrame; delim=',', header=0)

demand_model = sma(Array(data_model.total_heat_supply_per_hour - data_model.total_heat_drain_per_hour), n = 24)
demand_data = sma(Array(data_data[!,3]), n = 24)

plot_heat_demand_comp = plot(title = "Heat demand comparison\nrolling average", xlabel = "hours of the year [h]", ylabel = "heat demand [kWh]", legend = :outertopright)
plot!(plot_heat_demand_comp, data_model[!,:hour], demand_model, label = "surrogate model")
plot!(plot_heat_demand_comp, data_model[!,:hour], demand_data, label = "Hotmaps project")

savefig(plot_heat_demand_comp, "comparison/heat_demand_comparison.pdf")
