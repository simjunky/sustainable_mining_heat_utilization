# This script reads a .csv-file input, scales the data to make it fit the model and plots the resulting heat demand over the year into a .pdf-file. The scaled data is then written to another .csv-file which can be used as model input.


using CSV # CSV is used to easily read and write to .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# file destinations for read and write files
heat_origin_file = "data_input/load_profile_residential_shw_and_heating_yearlong_2010_DE11_Stuttgart.csv"
heat_target_file = "data_input/hourly_heat_load.csv"
heat_plot_file = "plots/heat_demand_profile.pdf"
temp_origin_file = "data_input/ninja_weather_temp_stuttgart.csv"
temp_target_file = "data_input/hourly_temp_profile.csv"
temp_plot_file = "plots/temp_profile.pdf"
solar_origin_file = "data_input/ninja_weather_solarradiance_stuttgart.csv"
solar_target_file = "data_input/hourly_solar_profile.csv"
solar_plot_file = "plots/solar_profile.pdf"


# the number of hours in a year and therefore the number of rows in the load data
n = 8760


# read from .csv-file and store only the columns containing hour and heat-load/temperature information into a DataFrame
heat_load_data = innerjoin(DataFrame(scenario = "Germany_Stuttgart", hour = 1:n), DataFrame(CSV.File(heat_origin_file, delim=',', select=[:hour, :load])), on = :hour)
temp_load_data = DataFrame(CSV.File(temp_origin_file, delim=',', select=[:hour, :temperature]))
solar_load_data = DataFrame(CSV.File(solar_origin_file, delim=',', select=[:hour, :radiation_surface]))


# average household in germany uses 100m^2 and on average 120kWh/m^2 but since house heat model uses single family homes which have 137m^2 we have to increase
# scaling factor to scale heat load (which is normalized to 1 000 000) to average load per household (which is 12 000 KWh)
heat_scaling_factor = 137 * 120 / 1000000
# scaling factor to scale solar radiance, which is in W/m^2 and should be in KW/m^2
solar_scaling_factor = 0.001
# scale and reduce the float62 type of the load info to float32 to avoid inport problems with GAMS
heat_load_data[!, :load] = convert.(Float32, heat_scaling_factor * heat_load_data[!, :load])
solar_load_data[!, :radiation_surface] = convert.(Float32, solar_scaling_factor * solar_load_data[!, :radiation_surface])


# write the reduced and scaled data without headers to the target destination .csv-file to be used as model input
CSV.write(heat_target_file, heat_load_data, writeheader = false)
CSV.write(temp_target_file, temp_load_data, writeheader = false)
CSV.write(solar_target_file, solar_load_data, writeheader = false)


# use the @df macro to easily plot the heat load and temperature over the year and store it as a plot
demand_plot = @df heat_load_data plot(:hour, :load, title = "scaled single household heat demand\n(in NUTS-DE11: Stuttgart)", xlabel = "hours of the year [h]", ylabel = "heat load [KWh]", label = "demand", legend = :outertopright)
temp_plot = @df temp_load_data plot(:hour, :temperature, title = "hourly air temperature for Stuttgart 2010)", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", label = "temperature", legend = :outertopright)
solar_plot = @df solar_load_data plot(:hour, :radiation_surface, title = "hourly solar radiation on surface level\nfor Stuttgart 2010)", xlabel = "hours of the year [h]", ylabel = "solar radiation [KW/m^2]", label = "solar radiation", legend = :outertopright)


# write the stored plot to a .pdf-file
savefig(demand_plot, heat_plot_file)
savefig(temp_plot, temp_plot_file)
savefig(solar_plot, solar_plot_file)
