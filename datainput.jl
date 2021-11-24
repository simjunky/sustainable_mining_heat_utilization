# This script goes through all scenario sub-directories, reads .csv-file inputs, plots the data into .pdf-filesand writes them to another .csv-file which can be used as model input by GAMS.


using CSV # CSV is used to read and write to .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# specify scenario directories using the command line arguments. If there are none use all sub directories in the scenarios directory.
scenario_directories = isempty(ARGS) ? first(walkdir("./scenarios"))[2] : ARGS


# the number of hours in a year and therefore the number of rows in the load data
n = 8760


# set color theme and palette for the plots
theme(:vibrant, palette = [:darkorange1, :deepskyblue, :lawngreen, :red2, :cyan, :magenta2])


# iterate throug all scenario directories
for directory in scenario_directories

    # file destinations for read and write files
    temp_origin_file = "scenarios/$(directory)/data_input/ninja_weather_$(directory)_Temp.csv"
    temp_target_file = "scenarios/$(directory)/data_input/hourly_temp_profile.csv"
    temp_plot_file = "scenarios/$(directory)/plots/temp_profile.pdf"
    solar_origin_file = "scenarios/$(directory)/data_input/ninja_weather_$(directory)_Solar.csv"
    solar_target_file = "scenarios/$(directory)/data_input/hourly_solar_profile.csv"
    solar_plot_file = "scenarios/$(directory)/plots/solar_profile.pdf"


    # skip files if they do not exist and inform about it
    if(!isfile(temp_origin_file))
        printstyled("Input files of $(directory) not found\n", color = :light_red)
        continue
    end

    if(!isdir("scenarios/$(directory)/plots"))
        mkdir("scenarios/$(directory)/plots")
    end

    # read from .csv-file and store only the columns containing hour and heat-load/temperature information into a DataFrame
    temp_load_data = CSV.read(temp_origin_file, DataFrame; delim=',', header=4, select=[:temperature])
    solar_load_data = CSV.read(solar_origin_file, DataFrame; delim=',', header=4, select=[:radiation_surface])


    # add hours of the year to the DataFrames
    insertcols!(temp_load_data, 1, :hour => collect(1:8760))
    insertcols!(solar_load_data, 1, :hour => collect(1:8760))


    # scaling factor to scale solar radiance, which is in W/m^2 and should be in kW/m^2
    solar_scaling_factor = 0.001
    # scale and reduce the float62 type of the load info to float32 to avoid inport problems with GAMS
    solar_load_data[!, :radiation_surface] = convert.(Float32, solar_scaling_factor * solar_load_data[!, :radiation_surface])


    # write the reduced and scaled data WITHOUT headers to the target destination .csv-file to be used as model input
    CSV.write(temp_target_file, temp_load_data, writeheader = false)
    CSV.write(solar_target_file, solar_load_data, writeheader = false)


    # use the @df macro to easily plot the heat load and temperature over the year and store it as a plot
    temp_plot = @df temp_load_data plot(:hour, :temperature, title = "hourly air temperature ($(directory))", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", label = "temperature", legend = :outertopright)
    solar_plot = @df solar_load_data plot(:hour, :radiation_surface, title = "hourly solar radiation on surface level\n($directory)", xlabel = "hours of the year [h]", ylabel = "solar radiation [kW/m^2]", label = "solar radiation", legend = :outertopright)


    # write the stored plot to a .pdf-file
    savefig(temp_plot, temp_plot_file)
    savefig(solar_plot, solar_plot_file)


    printstyled("prepared input and plot for $(directory)\n", color = :light_green)
end
