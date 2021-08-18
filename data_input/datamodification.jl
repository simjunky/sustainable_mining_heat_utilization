# This script reads a .csv-file input, scales the data to make it fit the model and plots the resulting heat demand over the year into a .pdf-file. The scaled data is then written to another .csv-file which can be used as model input.


using CSV # CSV is used to easily read and write to .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# file destinations for read and write files
origin_file = "data_input/load_profile_residential_shw_and_heating_yearlong_2010_DE11_Stuttgart.csv"
target_file = "data_input/hourly_heat_load.csv"
plot_file = "plots/heat_demand.pdf"


# read from .csv-file and store only the columns containing hour and load information into a DataFrame
load_data = DataFrame(CSV.File(origin_file, delim=',', select=[:hour, :load]))


#TODO: load is unitless and normalized to 1 000 000 => scale to the average household so that it is given in [Kwh]


# use the @df macro to easily plot the heat load over the year and store it as a plot
demand_plot = @df load_data plot(:hour, :load, title = "heat demand for NUTS-DE11: Stuttgart", xlabel = "Hours of the year [h]", ylabel = "heat load []")


# write the stored plot to a .pdf-file
savefig(demand_plot, plot_file)


# get the number of rows in the load data
n = nrow(load_data)


# create a column containing the scenario name
scenario_data = DataFrame( scenario = "Germany_Stuttgart", hour = 1:n)


# join the scenario column to the load data DataFrame from the left
input_data = innerjoin(scenario_data, load_data, on = :hour)


# write the reduced and scaled data without headers to the target destination .csv-file to be used as model input
CSV.write(target_file, input_data, writeheader = false)
