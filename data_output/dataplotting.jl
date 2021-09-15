# This script reads .csv-file inputs and plots the resulting parameter curves into a .pdf-file.


using CSV # CSV is used to easily read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# files containing plotting Data
file_by_source = "data_output/data_vectors_bysource.csv"
file_by_hour = "data_output/data_vectors_hourly.csv"
file_matrix = "data_output/data_matrix.csv"

# files to save plots to
cost_plot_file = "plots/costs_per_hour.pdf"
supply_plot_file = "plots/supply_per_hour.pdf"
supply_by_source_plot_file = "plots/supply_by_source.pdf"


# read from .csv-files and store them into DataFrames
hourly_data = CSV.File(file_by_hour, delim=',') |> DataFrame
source_data = CSV.File(file_by_source, delim=',') |> DataFrame


# use the @df macro to easily plot the heat load over the year and store it as a plot

cost_plot = @df hourly_data plot(:hour, [:total_heating_cost_per_hour, :electric_heating_cost_per_hour, :gas_heating_cost_per_hour, :mining_heating_cost_per_hour], title = "hourly heating cost by source", xlabel = "hours of the year [h]", ylabel = "cost [\$]", label = ["total" "electric" "gas" "mining"], legend = :outertopright)


# use the @df macro to plot the heat supply over the year and store it as a plot

supply_plot = @df hourly_data plot(:hour, [:heat_demand, :electric_heat_supply_per_hour, :gas_heat_supply_per_hour, :mining_heat_supply_per_hour], title = "hourly heat supply by source", xlabel = "hours of the year [h]", ylabel = "heat supply [KWh]", label = ["total" "electric" "gas" "mining"], legend = :outertopright)


# make a bar plot to show the different supply ammounts side by side

supply_bar_plot = bar(source_data[!, :total_heating_cost_per_source], title = "total supply by source", xticks = (1:3, ["electric", "gas", "mining"]), legend = false)


# write the stored plots to the .pdf-files
savefig(cost_plot, cost_plot_file)
savefig(supply_plot, supply_plot_file)
savefig(supply_bar_plot, supply_by_source_plot_file)
