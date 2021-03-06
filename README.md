# sustainable_mining_heat_utilization

Model and codebase to determine the change in profitability in crypto currency mining for the residential sector when utilizing waste heat.




## Short introduction to the model

What we try to find out is what kind of different heat sources are best suited to heat a single-family home with a given heat demand.

The given heat sources are among other parameters characterized by their upfront investment cost, fuel consumption, fuel cost as well as their heating (and cooling) potential. Using those metrics an **objective function for a mixed integer linear optimizer can be formulated, which minimizes the overall cost for one year of use**.

Upfront investment and interests thereof are handled by calculating a **fixed annuity** for the lifetime of the heat source.

Standing out among the other available heat sources and central to this work is the use of a mining rig as a heat source, which not only costs money but also allows for income generation.

Since the current prices for Bitcoin as well as its mining difficulty vary greatly and modelling them via stochastic processes is a task on and by itself they are in this models first iteration **treated as constant**.

To get reliable heat demand data for different regions on earth with different climates and economic environments a **weather data based approach** is formulated. Using a **reduced-order model** studied by [sperber2020] the indoor temperature can be calculated using the ambient air temperature and solar radiation on ground level. Based on this the heat demand can be calculated to meet a target temperature of around 20 °C. Both temperature and solar radiation data sets are available in hourly resolution through [renewables.ninja] on a worldwide scale thereby making it possible to use and compare drastically different scenarios. [globalpetrolprices.com] is a good source for electricity, gas and other prices.




## How the code works

Central piece of the code is a GAMS model located in [optimization_model.gms](https://github.com/simjunky/sustainable_mining_heat_utilization/blob/main/optimization_model.gms), in which all the above mentioned equations and constraints are formulated. To feed necessary and scenario based data into the model a folder hierarchy is used containing original `.csv` data files and some `Julia` code to parse it to GAMS readable `.csv` files.

After compilation the model is passed from GAMS to CPLEX (or some other solver of ones choosing) to calculate the results using mixed integer linear programming.

Those results are passed back to GAMS and written into output files depending on their data structure (scalar, time dependent, ...) from where a `Julia` script then plots the most important data for evaluation.




## How to use code & model

The entire calculation and plotting procedure is automated and can be invoked using the `Julia` script [run_sim.jl](https://github.com/simjunky/sustainable_mining_heat_utilization/blob/main/run_sim.jl). By default running it without arguments computes and plots all scenarios for which scenario directories and input files exist. Running it with scenario names as arguments computes only those specified scenarios. This is the way to go to compute new, or recompute single scenarios after changing or adding some data.

Before running a scenario, the weather data must be accessible in accordingly named folders and files (e.g. `<scenarioname>\data_input\hourly_temp_profile.csv`). Apart from that all other folders and files are created automatically or are updated if already existing.

Due to the nature of the `Julia` language of compiling code on runtime the invocation of the [run_sim.jl](https://github.com/simjunky/sustainable_mining_heat_utilization/blob/main/run_sim.jl) script via command line is not the fastest way, when many small succsessive changes are studied. Instead it is a better idea to run the code from within an interactive session, e.g. the REPL. Using the `include` function all methods are brought into the local name space and all dependencies are compiled. From here the functions provided by [run_sim.jl](https://github.com/simjunky/sustainable_mining_heat_utilization/blob/main/run_sim.jl) can and should be used for a much faster workflow and more granular control or for troubleshooting.




## References (exerpt)
[sperber2020]: Evelyn Sperber, Ulrich Frey, Valentin Bertsch, Reduced-order models for assessing demand response with heat pumps – Insights from the German energy system, Energy and Buildings, Volume 223, 2020, 110144, ISSN 0378-7788, [sciencedirect.com](https://www.sciencedirect.com/science/article/pii/S037877881933378X)

[renewables.ninja]: https://www.renewables.ninja

[globalpetrolprices.com]: https://www.globalpetrolprices.com/
