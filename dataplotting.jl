# This script contains a function, that reads the .csv-files created by GAMS as inputs and plots the resulting parameter curves into .pdf-files.
# The arguments are supposed to be the names of the scenario folders.


using CSV # CSV is used to read from .csv-files
using DataFrames # DataFrames are used to manipulate the data and handle it for plotting purposes
using Plots # Plot function to visualize data
using StatsPlots # StatsPlots is used to plot directly from the Dataframes instead of "Plots"


function plot_data(scenario_directories::Vector{String})

    # set color theme and palette for the plots
    theme(:default, palette = [:darkorange1, :deepskyblue, :lawngreen, :red2, :cyan, :magenta2])

    # iterate throug all scenario directories
    for directory in scenario_directories

        # file destinations containing plotting Data
        file_by_source = "scenarios/$(directory)/data_output/data_vectors_bysource.csv"
        file_by_hour = "scenarios/$(directory)/data_output/data_vectors_hourly.csv"
        file_matrix = "scenarios/$(directory)/data_output/data_matrix.csv"

        # file destinations to save plots to
        cost_plot_file = "scenarios/$(directory)/plots/costs_per_hour"
        temp_plot_file = "scenarios/$(directory)/plots/temp_per_hour"
        pv_plot_file = "scenarios/$(directory)/plots/pv_per_hour"
        scaled_pv_plot_file = "scenarios/$(directory)/plots/pv_per_hour_scaled"
        pv_eff_plot_file = "scenarios/$(directory)/plots/pv_efficiency"
        supply_plot_file = "scenarios/$(directory)/plots/supply_per_hour"
        eff_supply_plot_file = "scenarios/$(directory)/plots/eff_supply_per_hour"
        cost_by_source_plot_file = "scenarios/$(directory)/plots/cost_by_source"
        supply_by_source_plot_file = "scenarios/$(directory)/plots/supply_by_source"
        supply_pie_plot_file = "scenarios/$(directory)/plots/supply_pie"


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


        # use the @df macro to plot the pv output over the year and store it as a plot
        pv_plot = @df hourly_data plot(:hour, [:pv_power_produced, :pv_power_used], title = "hourly photovoltaics profiles", xlabel = "hours of the year [h]", ylabel = "power [kW]", label = ["pv production" "used pv power" ], legend = :outertopright)


        # use the @df macro to plot the solar radiation and pv output for one m^2 over the year and store it as a plot
        scaled_pv_plot = @df hourly_data plot(:hour, [:solar_radiation, :scaled_pv_power_produced, :scaled_pv_power_used], title = "scaled hourly photovoltaics profiles\n(1 m^2)", xlabel = "hours of the year [h]", ylabel = "power [kW/m^2]", label = ["solar radiation" "pv production" "used pv power" ], legend = :outertopright)


        # use the @df macro to plot the relative efficiency of a pv panel over the year and store it as a plot
        pv_eff_plot = @df hourly_data plot(:hour, [:pv_relative_efficiency], title = "relative efficiency over the year", xlabel = "hours of the year [h]", ylabel = "rel-efficiency []", label = ["relative efficiency"], legend = :outertopright)


        # plot the heat supply over the year and store it as a plot
        symbols = [:total_heat_supply_per_hour, :electric_heat_supply_per_hour, :gas_heat_supply_per_hour, :mining_heat_supply_per_hour, :ac_heat_supply_per_hour, :ac_heat_drain_per_hour]
        labels = ["total" "electric" "gas" "mining" "ac-heating" "ac-cooling"]
        supply_plot = plot(title = "hourly heat supply by source", xlabel = "hours of the year [h]", ylabel = "heat supply [kWh]", legend = :outertopright)

        for i in collect(1:length(symbols))
            plot!( supply_plot, hourly_data[!, :hour], hourly_data[!, symbols[i]] , label = labels[i])
            #savefig(supply_plot, supply_plot_file * string(i) * ".pdf")
            savefig(supply_plot, supply_plot_file * string(i) * ".png")
        end

        supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour, :electric_heat_supply_per_hour, :gas_heat_supply_per_hour, :mining_heat_supply_per_hour, :ac_heat_supply_per_hour, -:ac_heat_drain_per_hour], title = "hourly heat supply by source", xlabel = "hours of the year [h]", ylabel = "heat supply [kWh]", label = ["total" "electric" "gas" "mining" "ac-heating" "ac-cooling"], legend = :outertopright)


        # use the @df macro to plot the total effective heat supply over the year and store it as a plot
        eff_supply_plot = @df hourly_data plot(:hour, [:total_heat_supply_per_hour - :total_heat_drain_per_hour], title = "effective hourly heat supply", xlabel = "hours of the year [h]", ylabel = "heat supply [kWh]", label = "effective total", legend = :outertopright)


        # make a bar plot to show the different costs side by side
        cost_bar_plot = bar(source_data[!, :total_heating_cost_per_source], title = "total fuel cost by source", xlabel = "sources", ylabel = "total fuel cost [\$]", xticks = (1:length(source_data[!, :source]), source_data[!, :source]), legend = false)


        # make a bar plot to show the different supply ammounts side by side
        supply_bar_plot = groupedbar([source_data[!, :total_heat_supply_per_source] source_data[!, :total_heat_drain_per_source]], bar_position = :dodge, title = "total supply and drain by source", xlabel = "sources", ylabel = "total heat supply [kWh]", xticks = (1:length(source_data[!, :source]), source_data[!, :source]), legend = false)


        # make a pie chart to show the different supply ammounts side by side
        supply_pie_plot = pie(source_data[!, :total_heat_supply_per_source], title = "relative heat supply by source", label = reshape(source_data[!, :source], 1, length(source_data[!, :source])), legend = :outertopright)
        #TODO: apparently pie chart legends do not take this legend so its bugged...


        # write the stored plots to both .png and .pdf-files
        savefig(cost_plot, cost_plot_file * ".pdf")
        savefig(cost_plot, cost_plot_file * ".png")

        savefig(temp_plot, temp_plot_file * ".pdf")
        savefig(temp_plot, temp_plot_file * ".png")

        savefig(pv_plot, pv_plot_file * ".pdf")
        savefig(pv_plot, pv_plot_file * ".png")

        savefig(scaled_pv_plot, scaled_pv_plot_file * ".pdf")
        savefig(scaled_pv_plot, scaled_pv_plot_file * ".png")

        savefig(pv_eff_plot, pv_eff_plot_file * ".pdf")
        savefig(pv_eff_plot, pv_eff_plot_file * ".png")

        savefig(supply_plot, supply_plot_file * ".pdf")
        savefig(supply_plot, supply_plot_file * ".png")

        savefig(eff_supply_plot, eff_supply_plot_file * ".pdf")
        savefig(eff_supply_plot, eff_supply_plot_file * ".png")

        savefig(cost_bar_plot, cost_by_source_plot_file * ".pdf")
        savefig(cost_bar_plot, cost_by_source_plot_file * ".png")

        savefig(supply_bar_plot, supply_by_source_plot_file * ".pdf")
        savefig(supply_bar_plot, supply_by_source_plot_file * ".png")

        savefig(supply_pie_plot, supply_pie_plot_file * ".pdf")
        savefig(supply_pie_plot, supply_pie_plot_file * ".png")


        printstyled("plotted output for $(directory)\n", color = :light_green)
    end
end
