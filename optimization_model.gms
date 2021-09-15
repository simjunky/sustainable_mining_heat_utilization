
*enable end of line comments:
$eolcom //

$title mining heat utilization optimization model


Sets
    scenario scenario determining location / Germany_Stuttgart /
    t all hours of a year /1*8760/    // 24h per 365 days
    heat_source heat Sources / electricity, gas, mining /;


Scalars
    total_heat_demand       sum of the heat demand throughout the year in KWh /12000/
    btc_price               fixed bitcoin price in Dollars /41000/ // very volatile so fixed price maybe not best modeling approach but good enough starting point
    btc_reward              expected bitcoin reward per 1 Terrahash of computing power in BTC /0.0000003649/ // very dependent on current mining difficulty which is highly volatile
    miner_hashrate          fixed mining rig hash rate in TH /73/
    interest_rate           fixed interest rate to borrow money /0.07/; //could not find adequate source, Local Bank: from 3.9% to 10.5% with state-mandated example at 7%


Parameters
    heat_demand(scenario, t)     in-home heat demand for each hour of the year in KWh /
$ondelim
$include data_input\hourly_heat_load.csv
$offdelim
/
    fuel_price(heat_source)      fuelprices of each heating source in Dollar per KWh
         /       electricity     0.10
                 gas             0.083
                 mining          0.10    / // Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per KWh as with electric heating
*above prices are some placeholder prices of a german provider as of Aug 2021 //NOTE:GERMAN ELEC: 36ct
    capital_cost(heat_source)    capital cost of installing one heating unit in Dollar
         /       electricity     1025
                 gas             7000
                 mining          3500    /
    lifetime(heat_source)        expected lifetime until repurchase or obsolecence in years
         /       electricity     20
                 gas             15
                 mining          2       / // difficult to get acurate but one product-cycle seems to be 1 year and one product should remain competitive two to three generations.
    peak_power(heat_source)      maximum ammount of heat produced by one unit in Kw
         /       electricity     0.6
                 gas             8
                 mining          3       / // 8 is typical throughput of a residential gas pipe, 2.5 the equivalent of a 4 heater (each 0.6Kw) electric heating system for which the above capital cost was given
    pay_rate(heat_source)        ammount of Dollars to pay per year for capital expenses on loaned basis;


* calculate how much interest has to be payed annualy in addition to the regulat annual downpayment of the capital investment.
pay_rate(heat_source) = capital_cost(heat_source) * (1 + sum(t$(ord(t) < lifetime(heat_source)+1), interest_rate**ord(t))) / (lifetime(heat_source) + sum(t$(ord(t) < lifetime(heat_source)+1), ord(t) * interest_rate**ord(t)));


Variables
    cost                                 annual cost of the heating system in Dollars
    heat_cost(heat_source, t)            cost of fuel used up to supply heat in Dollars
    usage_cost(heat_source)              the average cost of using a heat source per Kwh;


positive Variables
    heat_supply(heat_source, t)          ammount of heat produced by each source in each hour in KWh
    mining_revenue(t)                    ammount of money in Dollar mined using the energy later used to heat;

integer Variables
    n_heating_units(heat_source)         number of heating units nessecairy to produce the supplied heat;


Equations
    costfunction                         the objective function to be minimized
    heat_balance(t)                      balances the ammount of heat produced to meet the demand
    heating_cost(heat_source, t)         calculates cost of used up fuel
    mining_process(t)                    calculates how much money the mining-rig can earn while heating
    heat_upperbound(heat_source, t)      installs an upper bound for the overall heat supplied every hour via the number of heating units
    calc_usage_cost(heat_source)         calculates the usage cost of a heat source;


// model equations:
costfunction ..                          cost =e= sum((heat_source, t), heat_cost(heat_source, t)) - sum(t, mining_revenue(t)) + sum(heat_source, n_heating_units(heat_source) * pay_rate(heat_source)); //capital_cost(heat_source) / lifetime(heat_source));
heating_cost(heat_source, t) ..          heat_cost(heat_source, t) =e= heat_supply(heat_source, t) * fuel_price(heat_source);
mining_process(t) ..                     mining_revenue(t) =e= heat_supply('mining', t) * miner_hashrate * btc_reward * btc_price / peak_power('mining');
heat_balance(t) ..                       heat_demand('Germany_Stuttgart', t) =e= sum(heat_source, heat_supply(heat_source, t));
heat_upperbound(heat_source, t) ..       heat_supply(heat_source, t) =l= n_heating_units(heat_source) * peak_power(heat_source);


// equations usefull for output
calc_usage_cost(heat_source) ..          usage_cost(heat_source) =e= fuel_price(heat_source) + capital_cost(heat_source) / lifetime(heat_source) / peak_power(heat_source) * sum(t, heat_supply(heat_source, t)) / 8760.0;


Model optimization_model /all/;
Solve optimization_model using mip minimizing cost;


Files
         data_scalars     / data_output\data_scalars.csv /
         data_vectors_hourly     / data_output\data_vectors_hourly.csv /
         data_vectors_bysource     / data_output\data_vectors_bysource.csv /
         data_matrix     / data_output\data_matrix.csv /;


data_scalars.pc = 5;
put data_scalars;
put 'found minimum of total cost(lower,level,upper,marginal)', cost.lo, cost.l, cost.up, cost.m /;
put 'sum_of_heat_demand', sum(t, heat_demand('Germany_Stuttgart', t)) /;
put 'sum_of_mining_revenue', sum(t, mining_revenue.l(t)) /;
put 'sum_of_heating_cost', sum((heat_source, t), heat_cost.l(heat_source, t)) /;
put 'sum_of_capital_investment', sum(heat_source, capital_cost(heat_source) * n_heating_units.l(heat_source)) /;
put 'sum_of_capital_cost', sum(heat_source, pay_rate(heat_source) * lifetime(heat_source)) /;
put 'mining_revenue_per_kwh', (miner_hashrate * btc_reward * btc_price / peak_power('mining')) /;
putclose;


data_vectors_bysource.pc = 5;
put data_vectors_bysource;
put                      'source',       'total_heat_supply_per_source',         'total_heating_cost_per_source',        'n_heating_units',               'pay_rate',             'usage_cost' /;
loop (heat_source, put   heat_source.tl, sum(t, heat_supply.l(heat_source, t)),  sum(t, heat_cost.l(heat_source, t)),    n_heating_units.l(heat_source),  pay_rate(heat_source),  usage_cost.l(heat_source) / );
putclose;


data_vectors_hourly.pc = 5;
put data_vectors_hourly;
put              'hour', 'heat_demand',                          'mining_revenue',     'total_heating_cost_per_hour',                  'electric_heating_cost_per_hour',  'electric_heat_supply_per_hour',    'gas_heating_cost_per_hour',    'gas_heat_supply_per_hour',    'mining_heating_cost_per_hour',    'mining_heat_supply_per_hour' /;
loop (t, put     ord(t),  heat_demand('Germany_Stuttgart', t),   mining_revenue.l(t),  sum(heat_source, heat_cost.l(heat_source, t)),  heat_cost.l('electricity', t),     heat_supply.l('electricity', t),    heat_cost.l('gas', t),          heat_supply.l('gas', t),       heat_cost.l('mining', t),          heat_supply.l('mining', t)    / );
putclose;


data_matrix.pc = 5;
put data_matrix;
put 'heat_source', 'hour', 'heat_supply' /;
loop ((heat_source, t), put heat_source.tl, ord(t), heat_supply.l(heat_source, t) / );
putclose;





