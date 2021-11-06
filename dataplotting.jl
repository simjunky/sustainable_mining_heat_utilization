# This script reads the .csv-files created by GAMS as inputs and plots the resulting parameter curves into .pdf-files.
# If invoked via command line the arguments are supposed to be the names of the scenario folders. If no argument is passed all scenario sub-directories are used.


using CSV # CSV is used to read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


# specify scenario directories using the command line arguments. If there are none use all sub directories in the scenarios directory.
scenario_directories = isempty(ARGS) ? first(walkdir("./scenarios"))[2] : ARGS


# iterate throug all scenario directories
for directory in scenario_directories

    # file destinations containing plotting Data
    file_by_source = "scenarios/$(directory)/data_output/data_vectors_bysource.csv"
    file_by_hour = "scenarios/$(directory)/data_output/data_vectors_hourly.csv"
    file_matrix = "scenarios/$(directory)/data_output/data_matrix.csv"

    # file destinations to save plots to
    cost_plot_file = "scenarios/$(directory)/plots/costs_per_hour.pdf"
    temp_plot_file = "scenarios/$(directory)/plots/temp_per_hour.pdf"
    supply_plot_file = "scenarios/$(directory)/plots/supply_per_hour.pdf"
    eff_supply_plot_file = "scenarios/$(directory)/plots/eff_supply_per_hour.pdf"
    cost_by_source_plot_file = "scenarios/$(directory)/plots/cost_by_source.pdf"
    supply_by_source_plot_file = "scenarios/$(directory)/plots/supply_by_source.pdf"


    # skip scenario if input files do not exist and inform about it
    if(!isfile(file_by_source) || !isfile(file_by_hour) || !isfile(file_matrix))
        printstyled("Input files of $(directory)/data_output/ not found\n", color = :light_red)
        continue
    end


    # create directory to save plot files in if it doesnt exist
    if(!isdir("scenarios/$(directory)/plots"))
        mkdir("scenarios/$(directory)/plots")
    end


    # read data from .csv-files and store it in DataFrames
    hourly_data = CSV.read(file_by_hour, DataFrame; delim=',')
    source_data = CSV.read(file_by_source, DataFrame; delim=',')


    # use the @df macro to plot the heat load over the year and store it as a plot
    cost_plot = @df hourly_data plot(:hour, [:total_heating_cost_per_hour, :electric_heating_cost_per_hour, :gas_heating_cost_per_hour, :mining_heating_cost_per_hour, :ac_heating_cost_per_hour], title = "hourly heating cost by source", xlabel = "hours of the year [h]", ylabel = "cost [\$]", label = ["total" "electric" "gas" "mining" "airconditioning"], legend = :outertopright)


    # use the @df macro to plot the different temperatures over the year and store it as a plot
    temp_plot = @df hourly_data plot(:hour, [:temperature_ambient, :temperature_envelope, :temperature_interior], title = "hourly temperature profiles", xlabel = "hours of the year [h]", ylabel = "temperature [°C]", label = ["ambient" "building envelope" "indoors" ], legend = :outertopright)


    # use the @df macro to plot the heat supply over the year and store it as a plot
    supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour, :electric_heat_supply_per_hour, :gas_heat_supply_per_hour, :mining_heat_supply_per_hour, :ac_heat_supply_per_hour, -:ac_heat_drain_per_hour], title = "hourly heat supply by source", xlabel = "hours of the year [h]", ylabel = "heat supply [kWh]", label = ["total" "electric" "gas" "mining" "ac-heating" "ac-cooling"], legend = :outertopright)


    # use the @df macro to plot the total effective heat supply over the year and store it as a plot
    eff_supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour - :ac_heat_drain_per_hour], title = "effective hourly heat supply", xlabel = "hours of the year [h]", ylabel = "heat supply [kWh]", label = "effective total", legend = :outertopright)


    # make a bar plot to show the different costs side by side
    cost_bar_plot = bar(source_data[!, :total_heating_cost_per_source], title = "total fuel cost by source", xlabel = "sources", ylabel = "total fuel cost [\$]", xticks = (1:4, ["electric", "gas", "mining", "airconditioning"]), legend = false)


    # make a bar plot to show the different supply ammounts side by side
    supply_bar_plot = groupedbar([source_data[!, :total_heat_supply_per_source] source_data[!, :total_heat_drain_per_source]], bar_position = :dodge, title = "total supply and drain by source", xlabel = "sources", ylabel = "total heat supply [kWh]", xticks = (1:4, ["electric", "gas", "mining", "airconditioning"]), legend = false)


    # write the stored plots to the .pdf-files
    savefig(cost_plot, cost_plot_file)
    savefig(temp_plot, temp_plot_file)
    savefig(supply_plot, supply_plot_file)
    savefig(eff_supply_plot, eff_supply_plot_file)
    savefig(cost_bar_plot, cost_by_source_plot_file)
    savefig(supply_bar_plot, supply_by_source_plot_file)


    printstyled("plotted output for $(directory)\n", color = :light_green)
end
