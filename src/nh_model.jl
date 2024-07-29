function nh_preprocess(inp)
    h2_mass_demand = inp["ammonia"]["nh3synthesis"]["nh_prod"]/(inp["global_data"]["properties"]["M_n"] + 3*inp["global_data"]["properties"]["M_h"])*3*inp["global_data"]["properties"]["M_h"]
    n2_mass_demand = inp["ammonia"]["nh3synthesis"]["nh_prod"]/(inp["global_data"]["properties"]["M_n"] + 3*inp["global_data"]["properties"]["M_h"])*inp["global_data"]["properties"]["M_n"]
    h2_energy_demand = h2_mass_demand * inp["global_data"]["properties"]["LHV_h2"]
    nh3_energy_demand = inp["ammonia"]["nh3synthesis"]["nh_prod"] * inp["global_data"]["properties"]["LHV_nh3"]
    ch4_h_demand = h2_energy_demand/nh3_energy_demand * inp["ammonia"]["h2synthesis"]["ch4_demand"] 

    inp["ammonia"]["nh3synthesis"]["h2_mass_demand"] = h2_mass_demand #mass flow of hydrogen required 
    inp["ammonia"]["nh3synthesis"]["n2_mass_demand"] = n2_mass_demand #mass flow of nitrogen required 
    inp["ammonia"]["nh3synthesis"]["h2_energy_demand"] = h2_energy_demand  #equivalent energy flow of hydrogen
    inp["ammonia"]["nh3synthesis"]["nh3_energy_demand"] = nh3_energy_demand #equivalent energy flow of nh3
    inp["ammonia"]["h2synthesis"]["ch4_h_demand"] = ch4_h_demand 
    return inp
end

function nh_model(m, T::Integer, global_data::Dict, nh::Dict)

    h2synthesis = nh["h2synthesis"]
    pem = nh["pem"]
    nh3synthesis = nh["nh3synthesis"]
    nitric = nh["nitric"]
    fixed = nh["fixed"]
    eb = nh["el_boiler"]
    asu = nh["asu"]

    prices      = global_data["prices"]
    properties  = global_data["properties"]


    ### Variables ###
    @variable(m, 0 <= c_en_nh)
    @variable(m, 0 <= c_ll_nh)
    @variable(m, 0 <= c_em_nh)
    @variable(m, 0 <= em_nh[1:T])
    @variable(m, 0 <= p_nh[1:T])
    @variable(m, 0 <= g_nh[1:T])
    @variable(m, 0 <= p_nh_fix)
    @variable(m, 0 <= rat_h_nh_pem[1:T] <= 1)
    @variable(m, 0 <= rat_h_nh_syn[1:T] <= 1)
    
    @variable(m, 0 <= p_nh_pem[1:T])
    @variable(m, 0 <= p_nh_asu[1:T])
    @variable(m, 0 <= h_nh_pem[1:T])
    @variable(m, 0 <= p_nh_pemstack[1:T])
    @variable(m, b_nh_pem[1:T], Bin)
    
    @variable(m, 0 <= h_nh_syn[1:T])
    @variable(m, 0 <= g_nh_syn[1:T])
    # @variable(m, 0 <= h_nh_syn_nom)
    
    @variable(m, 0 <= p_nh_nh[1:T])
    @variable(m, 0 <= ṁ_nh_nh_nh[1:T])
    @variable(m, 0 <= m_nh_nh_tot)
    @variable(m, 0 <= ṁ_h2_nh_nh[1:T])
    # @variable(m, 0 <= ṁ_n2_nh_nh[1:T])
    @variable(m, 0 <= h_nh_nh[1:T])
    @variable(m, x_up_nh_nh[1:T], Bin)
    @variable(m, x_dn_nh_nh[1:T], Bin)
    @variable(m, z_up_nh_nh[1:T], Bin)
    @variable(m, z_dn_nh_nh[1:T], Bin)
    
    @variable(m, 0 <= p_nh_hno[1:T])
    @variable(m, 0 <= p_nh_hno_comp[keys(nitric), 1:T])
    @variable(m, y_nh_hno_comp[keys(nitric), 1:T], Bin)
    @variable(m, z_nh_hno_comp[keys(nitric), 1:T], Bin)

    @variable(m, 0 <= p_nh_eb[1:T])

    #Initial values
    fix(z_up_nh_nh[1], 0, force=true)
    fix(z_dn_nh_nh[1], 0, force=true)
    fix(ṁ_nh_nh_nh[1], nh3synthesis["nh_prod"], force=true)
    for c in keys(nitric)
        fix(y_nh_hno_comp[c,1], 1, force=true)
    end
    

    #Cost functions
    @constraint(m, c_en_nh == sum(prices["electricity"] * p_nh[t] + prices["natural_gas"] * g_nh[t] for t=1:T)) #+ prices["natural_gas"] * g_nh[t] 
    @constraint(m, c_em_nh == sum(prices["emissions"] * em_nh[t] for t=1:T)) #emission costs
    @constraint(m, c_ll_nh == nh3synthesis["product_price"] * (nh3synthesis["nh_prod"]*T-m_nh_nh_tot))

    #Stream and energy connections
    @constraint(m, [t=1:T], p_nh[t] == p_nh_pem[t]  + p_nh_asu[t] + p_nh_nh[t] + p_nh_hno[t] + p_nh_fix + p_nh_eb[t] ) #total power demand - elboiler 
    @constraint(m, [t=1:T], g_nh[t] == g_nh_syn[t] ) #total gas demand
    # @constraint(m, h_nh_syn_nom == h_nh_nh) #nominal load of h2 synthesis equals full hydrogen demand of NH3 synthesis
    @constraint(m, [t=1:T], h_nh_nh[t] == h_nh_syn[t] + h_nh_pem[t])
    @constraint(m, [t=1:T], em_nh[t] == g_nh[t] * properties["ϕ_ng"])
    @constraint(m, m_nh_nh_tot == sum(ṁ_nh_nh_nh[t] for t=1:T)) #Total production of NH3


    #PEM electrolyzer + ASU
    @constraint(m, [t=1:T], h_nh_pem[t] == p_nh_pemstack[t] * pem["efficiency"]) #Produced hydrogen as product of el demand at stack and efficiency
    @constraint(m, [t=1:T], p_nh_pem[t] * pem["η_h2e_power"] == p_nh_pemstack[t]) #power demand at stack as product of power from grid and efficiency
    @constraint(m, [t=1:T], p_nh_pem[t] <= pem["capacity"] * b_nh_pem[t])#
    @constraint(m, [t=1:T], pem["Cmin_h2e"] * pem["capacity"] * b_nh_pem[t] <= p_nh_pem[t] )
    @constraint(m, [t=1:T], p_nh_asu[t] == p_nh_pem[t] * asu["power_demand"]) #Air separation unit power demand as a fraction of the PEM demand

    

    #H2 synthesis
    @constraint(m, [t=1:T], h_nh_syn[t] <= h2synthesis["h2_cap"])
    @constraint(m, [t=1:T], h_nh_syn[t] >= h2synthesis["cap_min"] * h2synthesis["h2_cap"])
    @constraint(m, [t=1:T], g_nh_syn[t] >= h_nh_syn[t]/h2synthesis["ch4_h_demand"]) #calculating natural gas demand as a function of ch4 to hydrogen efficiency
    

    #NH3 synthesis
    @constraint(m, [t=1:T], p_nh_nh[t] == nh3synthesis["power_demand"]*ṁ_nh_nh_nh[t]*0.8 + nh3synthesis["power_demand"]*nh3synthesis["nh_prod"]*0.2) #20% of power demand fixed, 80% related to production (10.1016/j.ijhydene.2019.11.028)
    @constraint(m, [t=1:T], ṁ_nh_nh_nh[t] <= nh3synthesis["nh_prod"])
    @constraint(m, [t=1:T], ṁ_nh_nh_nh[t] >= nh3synthesis["nh_prod"]*nh3synthesis["cap_min"])
    @constraint(m, [t=2:T], ṁ_nh_nh_nh[t] - ṁ_nh_nh_nh[t-1] <= nh3synthesis["ramp"] * nh3synthesis["nh_prod"]) #ramping constraints 
    @constraint(m, [t=2:T], ṁ_nh_nh_nh[t] - ṁ_nh_nh_nh[t-1] >= - nh3synthesis["ramp"] * nh3synthesis["nh_prod"]) #ramping constraints 
    @constraint(m,  [t=1:T], ṁ_h2_nh_nh[t] == ṁ_nh_nh_nh[t]/(properties["M_n"] + 3*properties["M_h"])*3*properties["M_h"]) #mass flow of hydrogen required
    # @constraint(m,  ṁ_n2_nh_nh[t] == ṁ_nh_nh_nh[t]/(properties["M_n"] + 3*properties["M_h"])*properties["M_n"]) #mass flow of nitrogen required
    @constraint(m,  [t=1:T], h_nh_nh[t] == ṁ_h2_nh_nh[t] * properties["LHV_h2"]) #equivalent energy flow of hydrogen
    # @constraint(m,  e_nh3_nh_nh == nh3synthesis["nh_prod"]*properties["LHV_nh3"]) #equivalent energy flow of hydrogen
    
    @constraint(m, [t=2:T], ṁ_nh_nh_nh[t] - ṁ_nh_nh_nh[t-1] <= x_up_nh_nh[t] * nh3synthesis["nh_prod"]) #binary x_up is 1 if increase in production 
    # @constraint(m, [t=2:T], -(ṁ_nh_nh_nh[t] - ṁ_nh_nh_nh[t-1]) <= (1-x_up_nh_nh[t]) * nh3synthesis["nh_prod"]) #binary x_up is 1 if increase in production 
    
    
    @constraint(m, [t=2:T], ṁ_nh_nh_nh[t-1] - ṁ_nh_nh_nh[t] <= x_dn_nh_nh[t] * nh3synthesis["nh_prod"]) #binary x_dn is 1 if decrease in production 
    # @constraint(m, [t=2:T], -(ṁ_nh_nh_nh[t-1] - ṁ_nh_nh_nh[t]) <= (1-x_dn_nh_nh[t]) * nh3synthesis["nh_prod"]) #binary x_dn is 1 if decrease in production 
    
    @constraint(m, [t=2:T], x_up_nh_nh[t-1] + x_up_nh_nh[t] - 1.5 <= z_up_nh_nh[t] * 10) #binary z_up is 1 if two consecutive load increases, otherwise 0 
    @constraint(m, [t=2:T], 1.5 - (x_up_nh_nh[t-1] + x_up_nh_nh[t])  <= (1 - z_up_nh_nh[t]) * 10) #binary z_up is 1 if two consecutive load increases, otherwise 0 
    
    @constraint(m, [t=2:T], x_dn_nh_nh[t-1] + x_dn_nh_nh[t] - 1.5 <= z_dn_nh_nh[t] * 10) #binary z_dn is 1 if two consecutive load increases, otherwise 0 
    @constraint(m, [t=2:T], 1.5 - (x_dn_nh_nh[t-1] + x_dn_nh_nh[t])  <= (1 - z_dn_nh_nh[t]) * 10) #binary z_dn is 1 if two consecutive load increases, otherwise 0 

    @constraint(m, [t=1:T-nh3synthesis["delay"]], sum(x_up_nh_nh[t+i] - z_up_nh_nh[t+i] for i=0:nh3synthesis["delay"]) <= 1) # minimum time between two load increases
    @constraint(m, [t=1:T-nh3synthesis["delay"]], sum(x_dn_nh_nh[t+i] - z_dn_nh_nh[t+i] for i=0:nh3synthesis["delay"]) <= 1) # minimum time between two load reductions

    @constraint(m, [t=1:T-nh3synthesis["constant"]], x_up_nh_nh[t] + sum(x_dn_nh_nh[t+i] - z_dn_nh_nh[t+i] for i=0:nh3synthesis["constant"]) <= 1) # minimum time in constant load
    @constraint(m, [t=1:T-nh3synthesis["constant"]], x_dn_nh_nh[t] + sum(x_up_nh_nh[t+i] - z_up_nh_nh[t+i] for i=0:nh3synthesis["constant"]) <= 1) # minimum time in constant load

    @constraint(m, [t=1:T-nh3synthesis["change_duration"]], sum(x_up_nh_nh[t+i] for i=0:nh3synthesis["change_duration"]) <= nh3synthesis["change_duration"]) #maximum number of load increases in a row
    @constraint(m, [t=1:T-nh3synthesis["change_duration"]], sum(x_dn_nh_nh[t+i] for i=0:nh3synthesis["change_duration"]) <= nh3synthesis["change_duration"]) #maximum number of load decreases in a row
    
    


    #Nitric acid
    @constraint(m, [t=1:T], p_nh_hno[t] == sum(p_nh_hno_comp[c,t] for c in keys(nitric)))
    for c in keys(nitric)
        @constraint(m, [t=1:T], p_nh_hno_comp[c,t] == nitric[c]["capacity"] * y_nh_hno_comp[c,t])
        @constraint(m, sum(y_nh_hno_comp[c,t] for t=1:T) >= nitric[c]["on"] * T)
        @constraint(m, [t=1:T-1], (y_nh_hno_comp[c,t]-y_nh_hno_comp[c,t+1]) - 0.5 <= 10 * z_nh_hno_comp[c,t+1]) #Determining binary for reduced load activation(y)
        @constraint(m, [t=1:T-1], 0.5 - (y_nh_hno_comp[c,t]-y_nh_hno_comp[c,t+1]) <= 10 * (1-z_nh_hno_comp[c,t+1]))
        @constraint(m, [t=1:T-nitric[c]["delay"]], sum(z_nh_hno_comp[c,t+i] for i=0:nitric[c]["delay"]) <= 1) #Minimum period between two load reductions
        if nitric[c]["on"] == 1.0
            fix.(y_nh_hno_comp[c,1:T], 1, force=true)
            fix.(z_nh_hno_comp[c,1:T], 0, force=true)
        end
    end

    #El-boiler
    @constraint(m, [t=1:T], p_nh_eb[t] <= eb["capacity"]) #maximum capacity
    @constraint(m, sum(p_nh_eb[t] for t=1:T) >= eb["capacity"]*eb["on"] * T) #minimum 10% average operation, 

    #Fixed demands
    fix.(p_nh_fix, fixed["nominal_prod"], force=true)

        



    println("NH3 model created")

end