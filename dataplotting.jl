# This script reads .csv-file inputs and plots the resulting parameter curves into .pdf-files.
# If invoked via command line the first argument is supposed to be the name of the scenario folder.


using CSV # CSV is used to easily read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# specify scenario folder using the command line arguments. if there are none use folder provided here
scenario_folder = isempty(ARGS) ? "Germany_Stuttgart" : ARGS[1]

# files containing plotting Data
file_by_source = "$scenario_folder/data_output/data_vectors_bysource.csv"
file_by_hour = "$scenario_folder/data_output/data_vectors_hourly.csv"
file_matrix = "$scenario_folder/data_output/data_matrix.csv"

# files to save plots to
cost_plot_file = "$scenario_folder/plots/costs_per_hour.pdf"
temp_plot_file = "$scenario_folder/plots/temp_per_hour.pdf"
supply_plot_file = "$scenario_folder/plots/supply_per_hour.pdf"
eff_supply_plot_file = "$scenario_folder/plots/eff_supply_per_hour.pdf"
cost_by_source_plot_file = "$scenario_folder/plots/cost_by_source.pdf"
supply_by_source_plot_file = "$scenario_folder/plots/supply_by_source.pdf"


# read from .csv-files and store them into DataFrames
hourly_data = CSV.File(file_by_hour, delim=',') |> DataFrame
source_data = CSV.File(file_by_source, delim=',') |> DataFrame


# use the @df macro to easily plot the heat load over the year and store it as a plot

cost_plot = @df hourly_data plot(:hour, [:total_heating_cost_per_hour, :electric_heating_cost_per_hour, :gas_heating_cost_per_hour, :mining_heating_cost_per_hour, :ac_heating_cost_per_hour], title = "hourly heating cost by source", xlabel = "hours of the year [h]", ylabel = "cost [\$]", label = ["total" "electric" "gas" "mining" "airconditioning"], legend = :outertopright)


# use the @df macro to plot the different temperatures over the year and store it as a plot

temp_plot = @df hourly_data plot(:hour, [:temperature_ambient, :temperature_envelope, :temperature_interior], title = "hourly temperature profiles", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", label = ["ambient" "building envelope" "indoors" ], legend = :outertopright)


# use the @df macro to plot the heat supply over the year and store it as a plot

supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour, :electric_heat_supply_per_hour, :gas_heat_supply_per_hour, :mining_heat_supply_per_hour, :ac_heat_supply_per_hour, -:ac_heat_drain_per_hour], title = "hourly heat supply by source", xlabel = "hours of the year [h]", ylabel = "heat supply [KWh]", label = ["total" "electric" "gas" "mining" "ac-heating" "ac-cooling"], legend = :outertopright)


# use the @df macro to plot the total effective heat supply over the year and store it as a plot

eff_supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour - :ac_heat_drain_per_hour], title = "effective hourly heat supply", xlabel = "hours of the year [h]", ylabel = "heat supply [KWh]", label = "effective total", legend = :outertopright)


# make a bar plot to show the different costs side by side

cost_bar_plot = bar(source_data[!, :total_heating_cost_per_source], title = "total fuel cost by source", xlabel = "sources", ylabel = "total fuel cost [\$]", xticks = (1:4, ["electric", "gas", "mining", "airconditioning"]), legend = false)


# make a bar plot to show the different supply ammounts side by side

supply_bar_plot = groupedbar([source_data[!, :total_heat_supply_per_source] source_data[!, :total_heat_drain_per_source]], bar_position = :dodge, title = "total supply and drain by source", xlabel = "sources", ylabel = "total heat supply [KWh]", xticks = (1:4, ["electric", "gas", "mining", "airconditioning"]), legend = false)


# write the stored plots to the .pdf-files
savefig(cost_plot, cost_plot_file)
savefig(temp_plot, temp_plot_file)
savefig(supply_plot, supply_plot_file)
savefig(eff_supply_plot, eff_supply_plot_file)
savefig(cost_bar_plot, cost_by_source_plot_file)
savefig(supply_bar_plot, supply_by_source_plot_file)
