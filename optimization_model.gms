
* enable end of line comments
$eolcom //


* set a model title
$title mining heat utilization optimization model


* set a compile-time variable, if it is not already created via command line double dash parameter (as in: gams optimization_model.gms --SCENARIO_FOLDER=Germany_Stuttgart)
* it specifies the folder where files of the corresponding scenario are stored
* changing it is key to compute different scenarios
$if not set SCENARIO_FOLDER $set SCENARIO_FOLDER Germany_Stuttgart_HeatDataComparison_noMining




Sets
         t                               hours of the year /1*8760/    // 24h per 365 days
         heat_source                     available heat sources / electricity, mining, airconditioning /;    //additional heat sources may be added via scenario parameter file file


Scalars
* parameters for mining rig and economical calculations:

* very volatile, so fixed price maybe not best modeling approach but a good enough starting point
         btc_price                       constant bitcoin price in Dollars
* very dependent on current mining difficulty which is highly volatile
         btc_reward                      expected bitcoin reward per 1 Terrahash of computing power in BTC
* parameter of the choosen mining rig
         miner_hashrate                  constant mining rig hash rate in TH per hour
         interest_rate                   constant private interest rate to borrow money

* parameters for thermal model according to and using parameters of Sperber2020 category SFH H Var 2 : AeratedConcreteBrickwork
         target_temperature              interior target temperature througout the year in °C
         thermal_resistance_R_i_e        thermal resistance betwenn interior air and building envelope in °C per kW
         thermal_resistance_R_e_a        thermal resistance between building envelope and ambient air in °C per kW
         thermal_resistance_R_i_a        thermal resistance between interior air and ambient air in °C per kW
         thermal_capacity_C_i            thermal capacitance of the interior air in kWh per °C
         thermal_capacity_C_e            thermal capacitance of the building envelope in kWh per °C
         area_A_i                        effective window area to absorb solar radiation to interior air in m^2
         internal_heat_gains             other heat sources in a household in kWh

* parameters for the PV model
         USE_PV_MODULES                  if pv modules should be used in the simulation (1=true 0=false)
         capital_cost_pv                 capital cost of installing one pv module in Dollar
         lifetime_pv                     lifetime of the pv modules in years
         pay_rate_pv                     ammount of Dollars to pay per year for capital expenses for pv on loaned basis
         pv_module_area                  surface area of the used pv module in m^2
         power_supply_P_STC              power supply of single pv module under standard test conditions in one hour in kWh
         solar_radiation_P_STC           radiation under standard test conditions in kW per m^2
         pv_temperature_T_STC            pv module temperature under standard test conditions in °C
         radiation_heatup_factor_c_T     factor describing how much the pv module is heated up by radiation
         rel_eff_factor_k_1              constand factor used to fit pv efficiency model to real world data
         rel_eff_factor_k_2              constand factor used to fit pv efficiency model to real world data
         rel_eff_factor_k_3              constand factor used to fit pv efficiency model to real world data
         rel_eff_factor_k_4              constand factor used to fit pv efficiency model to real world data
         rel_eff_factor_k_5              constand factor used to fit pv efficiency model to real world data
         rel_eff_factor_k_6              constand factor used to fit pv efficiency model to real world data;




Parameters
         fuel_price(heat_source)                 fuelprices of each heating source in Dollar per kWh
         electricity_consumption(heat_source)    how much electricity is needed to heat one kWh
         peak_heat_supply_power(heat_source)     maximum ammount of heat produced by one unit in kW
         peak_heat_drain_power(heat_source)      maximum ammount of heat drained from the system by one unit in kW
         capital_cost(heat_source)               capital cost of installing one heating unit in Dollar
         lifetime(heat_source)                   expected lifetime until repurchase or obsolecence in years
         pay_rate(heat_source)                   ammount of Dollars to pay per year for capital expenses on loaned basis

         temperature_T_a(t)                      outside air temperature for every hour of the year in °C
         /
$ondelim
$offlisting
$include scenarios\%SCENARIO_FOLDER%\data_input\hourly_temp_profile.csv
$onlisting
$offdelim
                                         /

         solar_radiation_P_s(t)                  heating power of the sun in kW per m^2
         /
$ondelim
$offlisting
$include scenarios\%SCENARIO_FOLDER%\data_input\hourly_solar_profile.csv
$onlisting
$offdelim
                                         /

         scaled_solar_radiation_G(t)             solar radiation scaled with test condition
         scaled_pv_module_temperature_T(t)       pv module temperature scaled with test conditions
         pv_module_relative_efficiency_e_rel(t)  relative efficiency of the pv module;




Variables
         cost                                    annual cost of the heating system in Dollars
         heat_cost(heat_source, t)               cost of fuel used up to supply heat in Dollars
         usage_cost(heat_source)                 the average cost of using a heat source per Kwh
         temperature_T_i(t)                      interior temperature that we want regulated in °C
         temperature_T_e(t)                      building envelope temperature in °C
         temperature_change_dT_i(t)              change of interior temperature each timestep in °C*h
* the temperature derivatives are calculated using central differences and periodic boundary conditions.
         temperature_change_dT_e(t)              change of building envelope temperature each timestep in °C*h;


positive Variables
         heat_supply(heat_source, t)             ammount of heat produced by each source per hour in kWh
         heat_drain(heat_source, t)              ammount of heat removed from the system by each source per hour in kWh
         mining_revenue(t)                       ammount of money in Dollar mined using the energy later used to heat
         power_supply_pv(t)                      ammount of power produced by photovoltaic modules
         power_used_pv(t)                        ammount of produced power which ist used for heating;


integer Variables
         n_pv_modules                            number of photovoltaic modules
         n_heating_units(heat_source)            number of heating units nessecairy to produce the supplied heat;




* include scenario specific parameter file in which values are set
$include scenarios\%SCENARIO_FOLDER%\data_input\scenario_parameters.inc

* calculate how much interest has to be payed annualy in addition to the regulat annual downpayment of the capital investment (annuity).
pay_rate(heat_source)                    = capital_cost(heat_source) * ((1 + interest_rate)**lifetime(heat_source) * interest_rate) / ((1 + interest_rate)**lifetime(heat_source) - 1);
pay_rate_pv                              = capital_cost_pv * ((1 + interest_rate)**lifetime_pv * interest_rate) / ((1 + interest_rate)**lifetime_pv - 1);

scaled_solar_radiation_G(t)              = solar_radiation_P_s(t) / solar_radiation_P_STC;
* TODO: Find out: Has the radiation to be scaled to the dimensions of the module? Or is the radiation under STC also per m^2?

scaled_pv_module_temperature_T(t)        = temperature_T_a(t) + radiation_heatup_factor_c_T * solar_radiation_P_s(t) - pv_temperature_T_STC;

* the relative efficiency is set to zero and only if the argument scaled_solar_radiation_G(t) is not zero (which would break the LOG function) we calculate the relative efficiency via the provided formula
pv_module_relative_efficiency_e_rel(t)   = 0.0 $(scaled_solar_radiation_G(t) < 0.05) + (1.0 + rel_eff_factor_k_1 * log(scaled_solar_radiation_G(t)) + rel_eff_factor_k_2 * power(log(scaled_solar_radiation_G(t)),2) + scaled_pv_module_temperature_T(t) * (rel_eff_factor_k_3 + rel_eff_factor_k_4 * log(scaled_solar_radiation_G(t)) + rel_eff_factor_k_5 * power(log(scaled_solar_radiation_G(t)),2)) + power(scaled_pv_module_temperature_T(t),2) * rel_eff_factor_k_6) $(scaled_solar_radiation_G(t) >= 0.05);
* TODO: Check if the boundary for the relative efficiency is maybe not to big and can be set closer to zero




Equations
         costfunction                            the objective function to be minimized
         heating_cost(heat_source, t)            calculates cost of used up fuel
         mining_process(t)                       calculates how much money the mining-rig can earn while heating
         heat_drain_bound(heat_source, t)        sets an upper bound for the overall heat drained from the system every hour via the number of heating units
         heat_supply_bound(heat_source, t)       sets an upper bound for the overall heat supplied every hour via the number of heating units
         calc_usage_cost(heat_source)            calculates the usage cost of a heat source
         temperature_interior(t)                 calculates interior temperature
         temperature_envelope(t)                 calculates building envelope temperature
         temperature_bounds_upper(t)             gives upper bounds for interior temperature
         temperature_bounds_lower(t)             gives lower bounds for interior temperature
         pv_powerproduction(t)                   calculates the total pv power produced by all modules
         pv_poweruse_prod_bound(t)               sets upper bound for the used power of the pv modules via the produced ammount
         pv_poweruse_usebound(t)                 sets upper bound for the used power of the pv modules via the used electricity since there is no storage;


* model equations:
costfunction ..                                  cost =e= sum((heat_source, t), heat_cost(heat_source, t)) - sum(t, mining_revenue(t)) + sum(heat_source, n_heating_units(heat_source) * pay_rate(heat_source)) + (n_pv_modules * pay_rate_pv - sum(t, power_used_pv(t)) * fuel_price('electricity')) $(USE_PV_MODULES);

heating_cost(heat_source, t) ..                  heat_cost(heat_source, t) =e= (heat_supply(heat_source, t) + heat_drain(heat_source, t)) * fuel_price(heat_source);
mining_process(t) ..                             mining_revenue(t) =e= heat_supply('mining', t) * miner_hashrate * btc_reward * btc_price / peak_heat_supply_power('mining');
heat_drain_bound(heat_source, t) ..              heat_drain(heat_source, t)  =l= n_heating_units(heat_source) * peak_heat_drain_power(heat_source);
heat_supply_bound(heat_source, t) ..             heat_supply(heat_source, t) =l= n_heating_units(heat_source) * peak_heat_supply_power(heat_source);

temperature_interior(t) ..                       (temperature_T_i(t++1) - temperature_T_i(t)) =e= (temperature_T_e(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_a) + (area_A_i * solar_radiation_P_s(t)) / thermal_capacity_C_i + (sum(heat_source, heat_supply(heat_source, t) - heat_drain(heat_source, t)) + internal_heat_gains) / thermal_capacity_C_i;
temperature_envelope(t) ..                       (temperature_T_e(t++1) - temperature_T_e(t)) =e= (temperature_T_i(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_e_a);
temperature_bounds_upper(t) ..                   temperature_T_i(t) - target_temperature =g= -0.5; //Temperature deviation has to be less than half a degree from the target temperature of 20°C
temperature_bounds_lower(t) ..                   temperature_T_i(t) - target_temperature =l= 0.5;

pv_powerproduction(t)..                          power_supply_pv(t) =e= n_pv_modules * power_supply_P_STC * scaled_solar_radiation_G(t) * pv_module_relative_efficiency_e_rel(t);
pv_poweruse_prod_bound(t)..                      power_used_pv(t) =l= power_supply_pv(t);
pv_poweruse_usebound(t)..                        power_used_pv(t) =l= sum(heat_source, heat_supply(heat_source, t) * electricity_consumption(heat_source)) + sum(heat_source, heat_drain(heat_source, t) * electricity_consumption(heat_source));

* equations usefull for output (is this still needed???)
calc_usage_cost(heat_source) ..                  usage_cost(heat_source) =e= fuel_price(heat_source) + capital_cost(heat_source) / lifetime(heat_source) / peak_heat_supply_power(heat_source) * sum(t, heat_supply(heat_source, t) + heat_drain(heat_source, t)) / 8760.0;



* set up model and solve it by minimizing the costfunction using some mixed integer linear programming, since the model itself is linear but uses one integer variable
Model optimization_model /all/;
Solve optimization_model using mip minimizing cost;



* set up output files in the output folder of the scenario
* for later ease of plotting each file handles one type of data: scalar, vectors depending on the heat source, vectors depending on the hour and matrices depending on both
Files
         data_scalars            / scenarios\%SCENARIO_FOLDER%\data_output\data_scalars.csv /
         data_vectors_hourly     / scenarios\%SCENARIO_FOLDER%\data_output\data_vectors_hourly.csv /
         data_vectors_bysource   / scenarios\%SCENARIO_FOLDER%\data_output\data_vectors_bysource.csv /
         data_matrix             / scenarios\%SCENARIO_FOLDER%\data_output\data_matrix.csv /;


* print file content for scalar file
* use print control = 5 for comma delimited file
data_scalars.pc = 5;
put data_scalars;
*put 'found minimum of total cost(lower,level,upper,marginal)', cost.lo, cost.l, cost.up, cost.m /;
put 'found minimum of total cost', cost.l /; 
put 'sum_of_heat_supply', sum((heat_source, t), heat_supply.l(heat_source, t)) /;
put 'sum_of_heat_drain', sum((heat_source, t), heat_drain.l(heat_source, t)) /;
put 'sum_of_mining_revenue', sum(t, mining_revenue.l(t)) /;
put 'sum_of_produced_power_pv', sum(t, power_supply_pv.l(t)) /;
put 'sum_of_used_power_pv', sum(t, power_used_pv.l(t)) /;
put 'sum_of_pv_revenue', (sum(t, power_used_pv.l(t)) * fuel_price('electricity')) /;
put 'sum_of_heating_cost', sum((heat_source, t), heat_cost.l(heat_source, t)) /;
put 'sum_of_capital_investment', (sum(heat_source, capital_cost(heat_source) * n_heating_units.l(heat_source)) + n_pv_modules.l * capital_cost_pv) /;
put 'sum_of_capital_cost', (sum(heat_source, n_heating_units.l(heat_source) * pay_rate(heat_source) * lifetime(heat_source)) + n_pv_modules.l * pay_rate_pv * lifetime_pv) /;
put 'mining_revenue_per_kwh', (miner_hashrate * btc_reward * btc_price / peak_heat_supply_power('mining')) /;
putclose;


* print file content for heat source dependent data
* use print control = 5 for comma delimited file
data_vectors_bysource.pc = 5;
* increase page width to 1000 to avoid gams cut off of the header
data_vectors_bysource.pw = 1000;
put data_vectors_bysource;
* write header line
put                      'source',       'total_heat_supply_per_source',         'total_heat_drain_per_source',         'total_heating_cost_per_source',        'n_heating_units',               'pay_rate',             'usage_cost' /;
* loop over heat sources and write data
loop (heat_source, put   heat_source.tl, sum(t, heat_supply.l(heat_source, t)),  sum(t, heat_drain.l(heat_source, t)),  sum(t, heat_cost.l(heat_source, t)),    n_heating_units.l(heat_source),  pay_rate(heat_source),  usage_cost.l(heat_source) / );
put                     'photovoltaics', 0,                                      0,                                     0,                                      n_pv_modules.l,                  pay_rate_pv,            0  /;
putclose;

* set variable to one if it is unused or zero so that we do not divide by it.
n_pv_modules.l $(USE_PV_MODULES) = 1;
n_pv_modules.l $(n_pv_modules.l = 0) = 1;

* print file content for time dependent data
* use print control = 5 for comma delimited file
data_vectors_hourly.pc = 5;
* increase page width to 1000 to avoid gams cut off of the header
data_vectors_hourly.pw = 1000;
put data_vectors_hourly;
* write header line
put           'hour', 'mining_revenue',     'total_heating_cost_per_hour',                  'total_heat_supply_per_hour',                     'total_heat_drain_per_hour',                     'electric_heating_cost_per_hour',  'electric_heat_supply_per_hour',   'gas_heating_cost_per_hour',   'gas_heat_supply_per_hour',  'mining_heating_cost_per_hour',  'mining_heat_supply_per_hour',   'ac_heating_cost_per_hour',         'ac_heat_supply_per_hour',            'ac_heat_drain_per_hour',           'temperature_ambient',  'temperature_interior', 'temperature_envelope', 'solar_radiation',      'pv_relative_efficiency',               'pv_power_produced',   'pv_power_used',     'scaled_pv_power_produced',                                 'scaled_pv_power_used' /;
* loop over hours and write data
loop (t, put  ord(t), mining_revenue.l(t),  sum(heat_source, heat_cost.l(heat_source, t)),  sum(heat_source, heat_supply.l(heat_source, t)),  sum(heat_source, heat_drain.l(heat_source, t)),  heat_cost.l('electricity', t),     heat_supply.l('electricity', t),   heat_cost.l('gas', t),         heat_supply.l('gas', t),     heat_cost.l('mining', t),        heat_supply.l('mining', t),      heat_cost.l('airconditioning', t),  heat_supply.l('airconditioning', t),  heat_drain.l('airconditioning', t)  temperature_T_a(t),     temperature_T_i.l(t),   temperature_T_e.l(t),   solar_radiation_P_s(t), pv_module_relative_efficiency_e_rel(t), power_supply_pv.l(t),  power_used_pv.l(t),  (power_supply_pv.l(t) / n_pv_modules.l / pv_module_area),   (power_used_pv.l(t) / n_pv_modules.l / pv_module_area)     / );
putclose;


* print file content for both time and heat source dependent data
* use print control = 5 for comma delimited file
data_matrix.pc = 5;
put data_matrix;
* write header line
put                              'heat_source',  'hour', 'heat_supply',                  'heat_drain'                    /;
* loop over heat sources and hours and write data
loop ((heat_source, t), put      heat_source.tl, ord(t), heat_supply.l(heat_source, t)   heat_drain.l(heat_source, t)    / );
putclose;





