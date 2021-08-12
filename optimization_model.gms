
*enable end of line comments:
$eolcom //

$title mining heat utilization optimization model


Sets
    t all hours of a year /t0*t8760/    // 24h per 365 days
    heat_source heat Sources / electricity, gas, mining /;


Scalars
    total_heat_demand       sum of the heat demand throughout the year in KWh /12000/
    btc_price               fixed bitcoin price in Dollars /36000/ // very volatile so fixed price maybe not best modeling approach but good enough starting point
    btc_reward              expected bitcoin reward per 1 Terrahash of computing power in BTC /0.0000003649/ // very dependent on current mining difficulty which is highly volatile
    miner_hashrate          fixed mining rig hash rate in TH /73/
    miner_power_usage       fixed mining rig power usage in KW /3/;


Parameters
    hour(t) number of the hour needed to do computation based on it
    heat_demand(t)     in-home heat demand for each hour of the year in KWh
    fuel_price(heat_source)         fuelprices of each heating source in Dollar per KWh
         /       electricity     0.36
                 gas             0.083
                 mining          0.36    /; //Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per KWh as with electric heating

*above prices are some placeholder prices of a german provider as of Aug 2021

    hour(t) = ord(t) - 1;
    heat_demand(t) = 12000.0 / 8760.0 * (cos(2.0 * Pi * hour(t) / 8760.0) + 1.0); // results in a total of 12.000 kwh over the year, which is an ok value for the average size german house of 100m^2 (CAREFUL: far from accurate but ok to start coding)
    display heat_demand;

Variables
    cost                            annual cost of the heating system in Dollars
    heat_supply(heat_source, t)     ammount of heat produced by each source in each hour in KWh
    heat_cost(heat_source)          cost of fuel used up to supply heat in Dollars
    mining_revenue(t)               ammount of money in Dollar mined using the energy later used to heat;


Equations
    costfunction                 the objective function to be minimized
    heat_balance(t)              balances the ammount of heat produced to meet the demand
    heating_cost(heat_source)    calculates cost of used up fuel
    mining_process(t)            calculates how much money the mining-rig can earn while heating
    heat_lowerbound(heat_source, t)           installs an lower bound for the overall heat supplied every hour which is zero;


mining_process(t) ..                mining_revenue(t) =e= heat_supply('mining', t) * miner_hashrate / miner_power_usage * btc_reward * btc_price;
heating_cost(heat_source) ..        heat_cost(heat_source) =e= sum(t, heat_supply(heat_source, t) * fuel_price(heat_source));
costfunction ..                     cost =e= sum(heat_source, heat_cost(heat_source)) - sum(t, mining_revenue(t));
heat_balance(t) ..                  heat_demand(t) =e= sum(heat_source, heat_supply(heat_source, t));
heat_lowerbound(heat_source, t) ..  heat_supply(heat_source, t) =g= 0.0;


Model optimization_model /all/;
Solve optimization_model using lp minimizing cost;

