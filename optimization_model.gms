
* enable end of line comments
$eolcom //


* set a model title
$title mining heat utilization optimization model


* set a compile-time variable, if it is not already created via command line double dash parameter (as in: gams optimization_model.gms --SCENARIO_FOLDER=Germany_Stuttgart)
* it specifies the folder where files of the corresponding scenario are stored
* changing it is key to compute different scenarios
$if not set SCENARIO_FOLDER $set SCENARIO_FOLDER Germany_Stuttgart




Sets
         t                               hours of the year /1*8760/    // 24h per 365 days
         heat_source                     available heat sources / electricity, mining, airconditioning /;    //additional heat sources may be added via scenario parameter file file


Scalars
* parameters for mining rig and economical calculations:
         btc_price                       fixed bitcoin price in Dollars
* very volatile, so fixed price maybe not best modeling approach but a good enough starting point

         btc_reward                      expected bitcoin reward per 1 Terrahash of computing power in BTC
* very dependent on current mining difficulty which is highly volatile

         miner_hashrate                  fixed mining rig hash rate in TH per hour
* parameter of the choosen mining rig

         interest_rate                   fixed private interest rate to borrow money
* could not find adequate source, Local Bank: from 3.9% to 10.5% with state-mandated example at 7%

* parameters for thermal model according to and using parameters of Sperber2020 category SFH H Var 2 : AeratedConcreteBrickwork
         target_temperature              interior target temperature througout the year in °C
         thermal_resistance_R_i_e        thermal resistance betwenn interior air and building envelope in °C per kW
         thermal_resistance_R_e_a        thermal resistance between building envelope and ambient air in °C per kW
         thermal_resistance_R_i_a        thermal resistance between interior air and ambient air in °C per kW
         thermal_capacity_C_i            thermal capacitance of the interior air in kWh per °C
         thermal_capacity_C_e            thermal capacitance of the building envelope in kWh per °C
         area_A_i                        effective window area to absorb solar radiation to interior air in m^2
         internal_heat_gains             other heat sources in a household;


Parameters
         fuel_price(heat_source)                 fuelprices of each heating source in Dollar per kWh
* Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per kWh as with electric heating
* air conditioners dont heat/cool fully electric but have also some heat-pump effect to them and therefore only use electricity for ~1/3rd of the power => fuel price = elec-Price * 1/3
* NOTE: German electricity price in Dollars: 36ct per kWh

         peak_heat_supply_power(heat_source)     maximum ammount of heat produced by one unit in kW
*8kW is typical throughput of a residential gas pipe, 2.5kW the equivalent of a 4 heater (each 0.6kW) electric heating system for which the above capital cost was given

         peak_heat_drain_power(heat_source)      maximum ammount of heat drained from the system by one unit in kW
* the only heat_source that can also cool is the air conditioner... in later implementations also heat pumps

         capital_cost(heat_source)               capital cost of installing one heating unit in Dollar

         lifetime(heat_source)                   expected lifetime until repurchase or obsolecence in years
* difficult to get acurate for mining but one product-cycle seems to be 1 year and one product should remain competitive two to three generations.

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
                                         /;


$include scenarios\%SCENARIO_FOLDER%\data_input\scenario_parameters.inc



* calculate how much interest has to be payed annualy in addition to the regulat annual downpayment of the capital investment (annuity).
pay_rate(heat_source) = capital_cost(heat_source) * ((1 + interest_rate)**lifetime(heat_source) * interest_rate) / ((1 + interest_rate)**lifetime(heat_source) - 1);




*
Variables
         cost                                    annual cost of the heating system in Dollars
         heat_cost(heat_source, t)               cost of fuel used up to supply heat in Dollars
         usage_cost(heat_source)                 the average cost of using a heat source per Kwh
         temperature_T_i(t)                      interior temperature that we want regulated in °C
         temperature_T_e(t)                      building envelope temperature in °C
         temperature_change_dT_i(t)              change of interior temperature each timestep in °C*h
         temperature_change_dT_e(t)              change of building envelope temperature each timestep in °C*h; //the temperature derivatives are calculated using central differences and periodic boundary conditions.


positive Variables
         heat_supply(heat_source, t)             ammount of heat produced by each source per hour in kWh
         heat_drain(heat_source, t)              ammount of heat removed from the system by each source per hour in kWh
         mining_revenue(t)                       ammount of money in Dollar mined using the energy later used to heat;


integer Variables
         n_heating_units(heat_source)            number of heating units nessecairy to produce the supplied heat
         /       electricity.lo          0
                 electricity.up          20
                 gas.lo                  0
                 gas.up                  20
                 mining.lo               0
                 mining.up               20
                 airconditioning.lo      0
                 airconditioning.up      20      /;
* lower and upper bounds given to make sure a solution exists


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
         temperature_bounds_lower(t)             gives lower bounds for interior temperature;


* model equations:
costfunction ..                                  cost =e= sum((heat_source, t), heat_cost(heat_source, t)) - sum(t, mining_revenue(t)) + sum(heat_source, n_heating_units(heat_source) * pay_rate(heat_source));
heating_cost(heat_source, t) ..                  heat_cost(heat_source, t) =e= (heat_supply(heat_source, t) + heat_drain(heat_source, t)) * fuel_price(heat_source);
mining_process(t) ..                             mining_revenue(t) =e= heat_supply('mining', t) * miner_hashrate * btc_reward * btc_price / peak_heat_supply_power('mining');
heat_drain_bound(heat_source, t) ..              heat_drain(heat_source, t)  =l= n_heating_units(heat_source) * peak_heat_drain_power(heat_source);
heat_supply_bound(heat_source, t) ..             heat_supply(heat_source, t) =l= n_heating_units(heat_source) * peak_heat_supply_power(heat_source);
temperature_interior(t) ..                       (temperature_T_i(t++1) - temperature_T_i(t)) =e= (temperature_T_e(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_a) + (area_A_i * solar_radiation_P_s(t)) / thermal_capacity_C_i + (sum(heat_source, heat_supply(heat_source, t) - heat_drain(heat_source, t)) + internal_heat_gains) / thermal_capacity_C_i;
temperature_envelope(t) ..                       (temperature_T_e(t++1) - temperature_T_e(t)) =e= (temperature_T_i(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_e_a);

*Alternative way to calculate derivative:
*temperature_interior(t) ..                      (temperature_T_i(t++1) - temperature_T_i(t--1)) / 2 =e= (temperature_T_e(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_a) + (area_A_i * solar_radiation_P_s(t)) / thermal_capacity_C_i + (sum(heat_source, heat_supply(heat_source, t) - heat_drain(heat_source, t)) + internal_heat_gains) / thermal_capacity_C_i;
*temperature_envelope(t) ..                      (temperature_T_e(t++1) - temperature_T_e(t--1)) / 2 =e= (temperature_T_i(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_e_a);

temperature_bounds_upper(t) ..                   temperature_T_i(t) - target_temperature =g= -0.5; //Temperature deviation has to be less than half a degree from the target temperature of 20°C
temperature_bounds_lower(t) ..                   temperature_T_i(t) - target_temperature =l= 0.5;

// equations usefull for output
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
put 'found minimum of total cost(lower,level,upper,marginal)', cost.lo, cost.l, cost.up, cost.m /;
put 'sum_of_heat_supply', sum((heat_source, t), heat_supply.l(heat_source, t)) /;
put 'sum_of_heat_drain', sum((heat_source, t), heat_drain.l(heat_source, t)) /;
put 'sum_of_mining_revenue', sum(t, mining_revenue.l(t)) /;
put 'sum_of_heating_cost', sum((heat_source, t), heat_cost.l(heat_source, t)) /;
put 'sum_of_capital_investment', sum(heat_source, capital_cost(heat_source) * n_heating_units.l(heat_source)) /;
put 'sum_of_capital_cost', sum(heat_source, pay_rate(heat_source) * lifetime(heat_source)) /;
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
putclose;


* print file content for time dependent data
* use print control = 5 for comma delimited file
data_vectors_hourly.pc = 5;
* increase page width to 1000 to avoid gams cut off of the header
data_vectors_hourly.pw = 1000;
put data_vectors_hourly;
* write header line
put           'hour', 'mining_revenue',     'total_heating_cost_per_hour',                  'total_heat_supply_per_hour',                     'total_heat_drain_per_hour',                     'electric_heating_cost_per_hour',  'electric_heat_supply_per_hour',   'gas_heating_cost_per_hour',   'gas_heat_supply_per_hour',  'mining_heating_cost_per_hour',  'mining_heat_supply_per_hour',   'ac_heating_cost_per_hour',         'ac_heat_supply_per_hour',            'ac_heat_drain_per_hour',           'temperature_ambient',  'temperature_interior', 'temperature_envelope' /;
* loop over hours and write data
loop (t, put  ord(t), mining_revenue.l(t),  sum(heat_source, heat_cost.l(heat_source, t)),  sum(heat_source, heat_supply.l(heat_source, t)),  sum(heat_source, heat_drain.l(heat_source, t)),  heat_cost.l('electricity', t),     heat_supply.l('electricity', t),   heat_cost.l('gas', t),         heat_supply.l('gas', t),     heat_cost.l('mining', t),        heat_supply.l('mining', t),      heat_cost.l('airconditioning', t),  heat_supply.l('airconditioning', t),  heat_drain.l('airconditioning', t)  temperature_T_a(t),     temperature_T_i.l(t),   temperature_T_e.l(t)     / );
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





