* This file is included in the optmization_model.gms code during compilation. It contains the values for all parameters of the model and thereby allows for scenario depending parameters. Also further heat sources can be added to the model if wanted.




* Here additional heat sources can be added. Keep in mind that in this case all heat source dependent parameters have to be updated

* the onmulti control option allows for expansion of predefined sets
$onmulti
Set heat_source additional heat sources / gas /;




* parameters for mining rig and economical calculations:

* the constant bitcoin price in Dollars
btc_price       = 40000; //37500; //47K is year long average from December on

* expected bitcoin reward per 1 Terrahash of computing power in BTC
btc_reward      = 0.0000003649;

* constant mining rig hash rate in TH per hour
miner_hashrate  = 73;

* constant private interest rate to borrow money
interest_rate   = 0.07;
* could not find adequate source, Local Bank: from 3.9% to 10.5% with state-mandated example at 7%.




* parameters for thermal model according to and using parameters of Sperber2020 category SFH H Var 2 : AeratedConcreteBrickwork

* interior target temperature througout the year in °C
target_temperature              = 20;

* thermal resistance betwenn interior air and building envelope in °C per kW
thermal_resistance_R_i_e        = 0.33;

* thermal resistance between building envelope and ambient air in °C per kW
thermal_resistance_R_e_a        = 5.39;

* thermal resistance between interior air and ambient air in °C per kW
thermal_resistance_R_i_a        = 28.29;

* thermal capacitance of the interior air in kWh per °C
thermal_capacity_C_i            = 1.71;

* thermal capacitance of the building envelope in kWh per °C
thermal_capacity_C_e            = 14.21;

* effective window area to absorb solar radiation to interior air in m^2
area_A_i                        = 2.88;

* other heat sources in a household in kWh
internal_heat_gains             = 0.411;




* parameters for the PV model
* Using Data and model provided by HuldEtAl2010

* if pv modules should be used in the simulation (1=true 0=false)
USE_PV_MODULES = 0;
* capital cost of installing one pv module in Dollar
* to be adjusted to reasonable(average) panel price... also still doesnt include installation cost or the cost of the converter
capital_cost_pv = 258;

* lifetime of the pv modules in years
lifetime_pv = 30;

* surface area of the used pv module in m^2
pv_module_area = 1.65 * 0.992;

* power supply of single pv module under standard test conditions in one hour in kWh
* to be adjusted to reasonable(average) size
power_supply_P_STC = 0.315;

* radiation under standard test conditions in kW per m^2
solar_radiation_P_STC = 1;

* pv module temperature under standard test conditions in °C
pv_temperature_T_STC = 25;

* factor describing how much the pv module is heated up by radiation in °C m^2 / kW
radiation_heatup_factor_c_T = 35.0;

* constand factors used to fit pv efficiency model to real world data
rel_eff_factor_k_1 = -0.017162;
rel_eff_factor_k_2 = -0.040289;
rel_eff_factor_k_3 = -0.004681;
rel_eff_factor_k_4 = 0.000148;
rel_eff_factor_k_5 = 0.0000169;
rel_eff_factor_k_6 = 0.000005;




* heat source dependent parameters:

* set the price of electricity, which is used in many locations
$set ELECTRICITY_PRICE 0.36

* fuelprices of each heating source in Dollar per kWh
fuel_price('electricity')         = %ELECTRICITY_PRICE%;
fuel_price('gas')                 = 0.083;
fuel_price('mining')              = %ELECTRICITY_PRICE%;
fuel_price('airconditioning')     = %ELECTRICITY_PRICE% * (1/3);
* Mining uses electricity and since all electric heating is 100% efficient we can assume the same price per kWh as with electric heating
* air conditioners dont heat/cool fully electric but have also some heat-pump effect to them and therefore only use electricity for ~1/3rd of the power => fuel price = elec-price * 1/3
* NOTE: German electricity price in Dollars: 36ct per kWh

* how much electricity is needed to heat one kWh
* so far it is assumed, that heating and cooling from the same device need the same ammount of electricity, which is only a bad approx.
electricity_consumption('electricity')      = 1;
electricity_consumption('gas')              = 0;
electricity_consumption('mining')           = 1;
electricity_consumption('airconditioning')  = 0.33;
* air conditioners dont heat/cool fully electric but have also some heat-pump effect to them and therefore only use electricity for ~1/3rd of the power

* maximum ammount of heat produced by one unit in kW
peak_heat_supply_power('electricity')     = 0.6;
peak_heat_supply_power('gas')             = 8;
peak_heat_supply_power('mining')          = 3;
peak_heat_supply_power('airconditioning') = 2.6;
* 8kW is typical throughput of a residential gas pipe, 2.5kW the equivalent of a 4 heater (each 0.6kW) electric heating system for which the above capital cost was given

* maximum ammount of heat drained from the system by one unit in kW
peak_heat_drain_power('electricity')      = 0.0;
peak_heat_drain_power('gas')              = 0.0;
peak_heat_drain_power('mining')           = 0.0;
peak_heat_drain_power('airconditioning')  = 2.5;
* the only heat_source that can also cool is the air conditioner... in later implementations maybe different heat pumps

* capital cost of installing one heating unit in Dollar
capital_cost('electricity')       = 1025;
capital_cost('gas')               = 7000;
capital_cost('mining')            = 3500;
capital_cost('airconditioning')   = 737;

* expected lifetime until repurchase or obsolecence in years
lifetime('electricity')           = 20;
lifetime('gas')                   = 15;
lifetime('mining')                = 2;
lifetime('airconditioning')       = 10;
* difficult to get acurate for mining but one product-cycle seems to be 1 year and one product should remain competitive two to three generations.




* bounds of number of heating units nessecairy to produce the supplied heat
* lower and upper bounds given to make sure the solution doesnt run off
n_heating_units.lo('electricity') = 0;
n_heating_units.up('electricity') = 20;
n_heating_units.lo('gas') = 0;
n_heating_units.up('gas') = 20;
n_heating_units.lo('mining') = 0;
n_heating_units.up('mining') = 20;
n_heating_units.lo('airconditioning') = 0;
n_heating_units.up('airconditioning') = 20;
n_pv_modules.lo = 0;
n_pv_modules.up = 60;
* the SFM with 137m^2 which is simulated here could have a usable roof surface of around ~34m^2 which would fit ~20 panels of size 1.65m*0.992m
