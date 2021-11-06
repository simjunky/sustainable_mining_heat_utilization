
*
$onmulti
Set heat_source additional heat sources / gas /;


* parameters for mining rig and economical calculations:
btc_price       = 37500;
btc_reward      = 0.0000003649;
miner_hashrate  = 73;
interest_rate   = 0.07;

* parameters for thermal model according to and using parameters of Sperber2020 category SFH H Var 2 : AeratedConcreteBrickwork
target_temperature              = 20;
thermal_resistance_R_i_e        = 0.33;
thermal_resistance_R_e_a        = 5.39;
thermal_resistance_R_i_a        = 28.29;
thermal_capacity_C_i            = 1.71;
thermal_capacity_C_e            = 14.21;
area_A_i                        = 2.88;
internal_heat_gains             = 0.411;


*Parameters
fuel_price('electricity')         = 0.25;
fuel_price('gas')                 = 0.083;
fuel_price('mining')              = 0.25;
fuel_price('airconditioning')     = 0.08;

* Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per kWh as with electric heating
* air conditioners dont heat/cool fully electric but have also some heat-pump effect to them and therefore only use electricity for ~1/3rd of the power => fuel price = elec-Price * 1/3
* NOTE: German electricity price in Dollars: 36ct per kWh


peak_heat_supply_power('electricity')     = 0.6;
peak_heat_supply_power('gas')             = 8;
peak_heat_supply_power('mining')          = 3;
peak_heat_supply_power('airconditioning') = 2.6;

*8kW is typical throughput of a residential gas pipe, 2.5kW the equivalent of a 4 heater (each 0.6kW) electric heating system for which the above capital cost was given


peak_heat_drain_power('electricity')      = 0.0;
peak_heat_drain_power('gas')              = 0.0;
peak_heat_drain_power('mining')           = 0.0;
peak_heat_drain_power('airconditioning')  = 2.5;

* the only heat_source that can also cool is the air conditioner... in later implementations maybe different heat pumps


capital_cost('electricity')       = 1025;
capital_cost('gas')               = 7000;
capital_cost('mining')            = 3500;
capital_cost('airconditioning')   = 737;


lifetime('electricity')           = 20;
lifetime('gas')                   = 15;
lifetime('mining')                = 2;
lifetime('airconditioning')       = 10;

* difficult to get acurate for mining but one product-cycle seems to be 1 year and one product should remain competitive two to three generations.


*integer Variables
*         n_heating_units(heat_source)            number of heating units nessecairy to produce the supplied heat
*         /       electricity.lo          0
*                 electricity.up          20
*                 gas.lo                  0
*                 gas.up                  20
*                 mining.lo               0
*                 mining.up               20
*                 airconditioning.lo      0
*                 airconditioning.up      20      /;
* lower and upper bounds given to make sure a solution exists
