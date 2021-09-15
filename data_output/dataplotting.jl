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


# read from .csv-files and store them into DataFrames
cost_data = CSV.File(file_by_hour, delim=',') |> DataFrame


# use the @df macro to easily plot the heat load over the year and store it as a plot

cost_plot = @df cost_data plot(:hour, [:total_heating_cost_per_hour, :electric_heating_cost_per_hour, :gas_heating_cost_per_hour, :mining_heating_cost_per_hour], title = "total heating cost per hour", xlabel = "hours of the year [h]", ylabel = "cost [\$]", label = ["total" "electric" "gas" "mining"], legend = :outertopright)


# write the stored plot to a .pdf-file
savefig(cost_plot, cost_plot_file)
