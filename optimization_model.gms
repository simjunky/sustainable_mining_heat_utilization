
*enable end of line comments:
$eolcom //

$title mining heat utilization optimization model

*Table myTable(*,*)
*$ondelim
*$include data_output\data_vectors_bysource.csv
*$offdelim


*display myTable


Sets
    scenario scenario determining location / Germany_Stuttgart /
    t all hours of a year /1*8760/    // 24h per 365 days
    heat_source heat Sources / electricity, gas, mining, airconditioning /;


Scalars
    total_heat_demand       sum of the heat demand throughout the year in KWh /12000/
    btc_price               fixed bitcoin price in Dollars /37500/ // very volatile so fixed price maybe not best modeling approach but good enough starting point
    btc_reward              expected bitcoin reward per 1 Terrahash of computing power in BTC /0.0000003649/ // very dependent on current mining difficulty which is highly volatile
    miner_hashrate          fixed mining rig hash rate in TH /73/
    interest_rate           fixed interest rate to borrow money /0.07/; //could not find adequate source, Local Bank: from 3.9% to 10.5% with state-mandated example at 7%


Parameters
*    heat_demand(scenario, t)             in-home heat demand for each hour of the year in KWh /
*$ondelim
*$include data_input\hourly_heat_load.csv
*$offdelim
*/
    fuel_price(heat_source)      fuelprices of each heating source in Dollar per KWh
         /       electricity     0.25
                 gas             0.083
                 mining          0.25
                 airconditioning 0.08    /
* Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per KWh as with electric heating
* air conditioners dont heat/cool fully electric but have also some heat-pump effect to them and therefore use electricity for ~1/3rd of the power => fuel price = elec-Price * 1/3
* above prices are some placeholder prices of a german provider as of Aug 2021 //NOTE:GERMAN ELEC: 36ct instead of 10ct
    peak_heat_supply_power(heat_source)      maximum ammount of heat produced by one unit in KW
         /       electricity     0.6
                 gas             8
                 mining          3
                 airconditioning 2.6     /
*8KW is typical throughput of a residential gas pipe, 2.5KW the equivalent of a 4 heater (each 0.6KW) electric heating system for which the above capital cost was given
    peak_heat_drain_power(heat_source)      maximum ammount of heat drained from the system by one unit in KW
         /       electricity     0.0
                 gas             0.0
                 mining          0.0
                 airconditioning 2.5        /
* the only heat_source that can alo cool is the air conditioner... in later implementations also heat pumps.
    capital_cost(heat_source)    capital cost of installing one heating unit in Dollar
         /       electricity     1025
                 gas             7000
                 mining          3500
                 airconditioning 737        /
    lifetime(heat_source)        expected lifetime until repurchase or obsolecence in years
         /       electricity     20
                 gas             15
                 mining          2
                 airconditioning 10        /
* difficult to get acurate for mining but one product-cycle seems to be 1 year and one product should remain competitive two to three generations.
    pay_rate(heat_source)        ammount of Dollars to pay per year for capital expenses on loaned basis
    temperature_T_a(t)           outside air temperature for every hour of the year in °C /
$ondelim
$include data_input\hourly_temp_profile.csv
$offdelim
/
    solar_radiation_P_s(t)       heating power of the sun in KW per m^2 /
$ondelim
$include data_input\hourly_solar_profile.csv
$offdelim
/
    thermal_resistance_R_i_e     thermal resistance betwenn interior air and building envelope in °C per KW / 0.33 /
    thermal_resistance_R_e_a     thermal resistance between building envelope and ambient air in °C per KW / 5.39 /
    thermal_resistance_R_i_a     thermal resistance between interior air and ambient air in °C per KW / 28.29 /
    thermal_capacity_C_i         thermal capacitance of the interior air in KWh per °C / 1.71 /
    thermal_capacity_C_e         thermal capacitance of the building envelope in KWh per °C / 14.21 /
    area_A_i                     effective window area to absorb solar radiation to interior air in m^2 / 2.88 /
    internal_heat_gains          other heat sources in a household / 0.411 /; // values from sperber2020 SFH H Var 2 : AeratedConcreteBrickwork


* calculate how much interest has to be payed annualy in addition to the regulat annual downpayment of the capital investment.
pay_rate(heat_source) = capital_cost(heat_source) * ((1 + interest_rate)**lifetime(heat_source) * interest_rate) / ((1 + interest_rate)**lifetime(heat_source) - 1);


Variables
    cost                                 annual cost of the heating system in Dollars
    heat_cost(heat_source, t)            cost of fuel used up to supply heat in Dollars
    usage_cost(heat_source)              the average cost of using a heat source per Kwh
    temperature_T_i(t)                   interior temperature that we want regulated in °C
    temperature_T_e(t)                   building envelope temperature in °C
    temperature_change_dT_i(t)           change of interior temperature each timestep in °C*h
    temperature_change_dT_e(t)           change of building envelope temperature each timestep in °C*h; //the temperature derivatives are calculated using central differences and periodic boundary conditions.


positive Variables
    heat_supply(heat_source, t)          ammount of heat produced by each source per hour in KWh
    heat_drain(heat_source, t)           ammount of heat removed from the system by each source per hour in KWh
    mining_revenue(t)                    ammount of money in Dollar mined using the energy later used to heat;


integer Variables
    n_heating_units(heat_source)         number of heating units nessecairy to produce the supplied heat
         /       electricity.lo          0
                 electricity.up          20
                 gas.lo                  0
                 gas.up                  20
                 mining.lo               0
                 mining.up               20
                 airconditioning.lo      0
                 airconditioning.up      20      /;


Equations
    costfunction                         the objective function to be minimized
    heating_cost(heat_source, t)         calculates cost of used up fuel
    mining_process(t)                    calculates how much money the mining-rig can earn while heating
    heat_drain_bound(heat_source, t)     sets an upper bound for the overall heat drained from the system every hour via the number of heating units
    heat_supply_bound(heat_source, t)    sets an upper bound for the overall heat supplied every hour via the number of heating units
    calc_usage_cost(heat_source)         calculates the usage cost of a heat source
    temperature_interior(t)              calculates interior temperature
    temperature_envelope(t)              calculates building envelope temperature
    temperature_bounds_upper(t)          gives upper bounds for interior temperature
    temperature_bounds_lower(t)          gives lower bounds for interior temperature;


// model equations:
costfunction ..                          cost =e= sum((heat_source, t), heat_cost(heat_source, t)) - sum(t, mining_revenue(t)) + sum(heat_source, n_heating_units(heat_source) * pay_rate(heat_source));
heating_cost(heat_source, t) ..          heat_cost(heat_source, t) =e= (heat_supply(heat_source, t) + heat_drain(heat_source, t)) * fuel_price(heat_source);
mining_process(t) ..                     mining_revenue(t) =e= heat_supply('mining', t) * miner_hashrate * btc_reward * btc_price / peak_heat_supply_power('mining');
heat_drain_bound(heat_source, t) ..      heat_drain(heat_source, t)  =l= n_heating_units(heat_source) * peak_heat_drain_power(heat_source);
heat_supply_bound(heat_source, t) ..     heat_supply(heat_source, t) =l= n_heating_units(heat_source) * peak_heat_supply_power(heat_source);

temperature_interior(t) ..               (temperature_T_i(t++1) - temperature_T_i(t)) =e= (temperature_T_e(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_a) + (area_A_i * solar_radiation_P_s(t)) / thermal_capacity_C_i + (sum(heat_source, heat_supply(heat_source, t) - heat_drain(heat_source, t)) + internal_heat_gains) / thermal_capacity_C_i;
temperature_envelope(t) ..               (temperature_T_e(t++1) - temperature_T_e(t)) =e= (temperature_T_i(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_e_a);

*temperature_interior(t) ..               (temperature_T_i(t++1) - temperature_T_i(t--1)) / 2 =e= (temperature_T_e(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_i(t)) / (thermal_capacity_C_i * thermal_resistance_R_i_a) + (area_A_i * solar_radiation_P_s(t)) / thermal_capacity_C_i + (sum(heat_source, heat_supply(heat_source, t) - heat_drain(heat_source, t)) + internal_heat_gains) / thermal_capacity_C_i;
*temperature_envelope(t) ..               (temperature_T_e(t++1) - temperature_T_e(t--1)) / 2 =e= (temperature_T_i(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_i_e) + (temperature_T_a(t) - temperature_T_e(t)) / (thermal_capacity_C_e * thermal_resistance_R_e_a);

temperature_bounds_upper(t) ..           temperature_T_i(t) - 20 =g= -0.5; //Temperature deviation has to be less than half a degree from the target temperature of 20°C
temperature_bounds_lower(t) ..           temperature_T_i(t) - 20 =l= 0.5;


// equations usefull for output
calc_usage_cost(heat_source) ..          usage_cost(heat_source) =e= fuel_price(heat_source) + capital_cost(heat_source) / lifetime(heat_source) / peak_heat_supply_power(heat_source) * sum(t, heat_supply(heat_source, t) + heat_drain(heat_source, t)) / 8760.0;


Model optimization_model /all/;
Solve optimization_model using mip minimizing cost;   //earlyer we used mip


Files
         data_scalars     / data_output\data_scalars.csv /
         data_vectors_hourly     / data_output\data_vectors_hourly.csv /
         data_vectors_bysource     / data_output\data_vectors_bysource.csv /
         data_matrix     / data_output\data_matrix.csv /;


*next test of writing to multiple files
*File data_test_next /data_output\test.txt/;

*Set testfilenameset containing some bits that could be file names /filename01*filename04/;

*put data_test_next;
*loop( testfilenameset,
*         put_utilities 'ren' / 'data_output\':0 testfilenameset.tl:0;
*         put 'this should be in file ' testfilenameset.tl;
*);
*putclose;




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


data_vectors_bysource.pc = 5;
data_vectors_bysource.pw = 1000;
put data_vectors_bysource;
put                      'source',       'total_heat_supply_per_source',         'total_heat_drain_per_source',         'total_heating_cost_per_source',        'n_heating_units',               'pay_rate',             'usage_cost' /;
loop (heat_source, put   heat_source.tl, sum(t, heat_supply.l(heat_source, t)),  sum(t, heat_drain.l(heat_source, t)),  sum(t, heat_cost.l(heat_source, t)),    n_heating_units.l(heat_source),  pay_rate(heat_source),  usage_cost.l(heat_source) / );
putclose;


data_vectors_hourly.pc = 5;
data_vectors_hourly.pw = 1000; // make room for very long lines (especially the header)
put data_vectors_hourly;
put           'hour', 'mining_revenue',     'total_heating_cost_per_hour',                  'total_heat_supply_per_hour',                     'total_heat_drain_per_hour',                     'electric_heating_cost_per_hour',  'electric_heat_supply_per_hour',   'gas_heating_cost_per_hour',   'gas_heat_supply_per_hour',  'mining_heating_cost_per_hour',  'mining_heat_supply_per_hour',   'ac_heating_cost_per_hour',         'ac_heat_supply_per_hour',            'ac_heat_drain_per_hour',           'temperature_ambient',  'temperature_interior', 'temperature_envelope' /;
loop (t, put  ord(t), mining_revenue.l(t),  sum(heat_source, heat_cost.l(heat_source, t)),  sum(heat_source, heat_supply.l(heat_source, t)),  sum(heat_source, heat_drain.l(heat_source, t)),  heat_cost.l('electricity', t),     heat_supply.l('electricity', t),   heat_cost.l('gas', t),         heat_supply.l('gas', t),     heat_cost.l('mining', t),        heat_supply.l('mining', t),      heat_cost.l('airconditioning', t),  heat_supply.l('airconditioning', t),  heat_drain.l('airconditioning', t)  temperature_T_a(t),     temperature_T_i.l(t),   temperature_T_e.l(t)     / );
putclose;


data_matrix.pc = 5;
put data_matrix;
put                              'heat_source',  'hour', 'heat_supply',                  'heat_drain'                    /;
loop ((heat_source, t), put      heat_source.tl, ord(t), heat_supply.l(heat_source, t)   heat_drain.l(heat_source, t)    / );
putclose;





