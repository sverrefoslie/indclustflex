function cem_preprocess(inp)
    T=inp["T"]
    days=ceil(Int64, T/24)
    weeks=ceil(Int64, T/168)

    inp["cement"]["production"]["cement_production"] = (inp["cement"]["kiln"]["mass_flow"]/inp["cement"]["production"]["rawmeal_klinker_ratio"])/inp["cement"]["production"]["klinker_fraction"]
    inp["cement"]["production"]["nominal_prod"] = inp["T"]*inp["cement"]["production"]["cement_production"]
    op1 = inp["cement"]["machinery"]["crusher1"]["op"]
    off1 = []
    off1 = 1 .- op1
    off1_tot = repeat(off1, days)
    inp["cement"]["machinery"]["crusher1"]["off"] = off1_tot


    op2 = inp["cement"]["machinery"]["crusher2"]["op"]
    off2 = []
    off2 = 1 .- op2
    off2_tot = repeat(off2, days)
    inp["cement"]["machinery"]["crusher2"]["off"] = off2_tot

    inp["weeks"] = weeks


    return inp
end

function cem_model(m, T::Integer, global_data::Dict, cem::Dict)

    production =    cem["production"]
    machinery =     cem["machinery"]
    kiln =          cem["kiln"]
    storages =      cem["storages"]
    other =         cem["other"]
    

    prices      = global_data["prices"]
    properties  = global_data["properties"]


    ### Variables ###
    @variable(m, 0 <= c_en_cem)
    @variable(m, 0 <= c_ll_cem)
    @variable(m, 0 <= c_lc_cem)
    @variable(m, 0 <= c_lc_cem_lcc)
    @variable(m, 0 <= c_lc_cem_dev)
    @variable(m, 0 <= c_lc_cem_disc)

    # @variable(m, 0 <= m_cem_tot)
    @variable(m, 0 <= m_cem_prod[1:T])
    @variable(m, 0 <= m_cem_lost[1:T])

    @variable(m, 0 <= p_cem[1:T])

    @variable(m, 0 <= p_cem_mach_tot[1:T])
    @variable(m, 0 <= p_cem_mach[keys(machinery), 1:T])
    @variable(m, 0 <= m_cem_mach[keys(machinery), 1:T])
    @variable(m, y_cem_mach[keys(machinery), 1:T], Bin)
    @variable(m, 0 <= LC_up_cem_mach[keys(machinery),1:T] <= 1)
    @variable(m, 0 <= LC_down_cem_mach[keys(machinery),1:T] <= 1)
    
    
    @variable(m, 0 <= m_cem_stor_in[keys(storages), 1:T])
    @variable(m, 0 <= m_cem_stor_out[keys(storages), 1:T])
    @variable(m, 0 <= s_cem_stor[keys(storages), 1:T])
    
    @variable(m, 0 <= p_cem_kiln)
    @variable(m, 0 <= m_cem_kiln[1:T])
    @variable(m, 0 <= dev_up_cem_kiln[1:T])
    @variable(m, 0 <= dev_down_cem_kiln[1:T])
    # @variable(m, x_kiln[1:T], Bin)
    # @variable(m, z_kiln[1:T], Bin)
    # @variable(m, y_kiln[1:T], Bin)

    @variable(m, 0 <= p_cem_fix)
    @variable(m, 0 <= p_cem_ccs)

    #Cost functions
    @constraint(m, c_en_cem == sum(prices["electricity"] * p_cem[t] for t=1:T)) #
    @constraint(m, c_ll_cem == production["product_price"] * sum(m_cem_lost[t] for t=1:T) ) #+ production["product_price"]*5*24*sum(z_kiln[t] for t=1:T)
    @constraint(m, c_lc_cem == c_lc_cem_lcc + c_lc_cem_dev + c_lc_cem_disc) #load change costs


    @constraint(m, c_lc_cem_lcc == production["c_LCC"]*sum((LC_up_cem_mach[c,t] + LC_down_cem_mach[c,t]) for t=1:T,c in keys(machinery))) #machine load change cost
    @constraint(m, c_lc_cem_dev == production["c_dev"]*sum(dev_up_cem_kiln[t] + dev_down_cem_kiln[t] for t=1:T)) #kiln offset cost
    @constraint(m, c_lc_cem_disc == sum(y_cem_mach[c,t]*machinery[c]["off"][t]*production["c_dev_mach"] for c = ["crusher1", "crusher2"],t=1:T))

    #Initial values
    @constraint(m, m_cem_kiln[1] == kiln["mass_flow"])
    # @constraint(m, p_cem_mach["crusher1",1] == machinery["crusher1"]["power_demand"])
    @constraint(m, p_cem_mach["crusher2",1] == 0)
    @constraint(m, p_cem_mach["raw_mill",1] == machinery["raw_mill"]["power_demand"])
    @constraint(m, p_cem_mach["cement_mill1",1] == machinery["cement_mill1"]["power_demand"])
    @constraint(m, p_cem_mach["cement_mill2",1] == machinery["cement_mill2"]["power_demand"])
    @constraint(m, p_cem_mach["cement_mill3",1] == machinery["cement_mill3"]["power_demand"])

    for s in keys(storages)
        @constraint(m, s_cem_stor[s,1] == storages[s]["capacity"]*0.5)  #storage level at start is half full
    end


    #Stream and energy connections
    @constraint(m, [t=1:T], p_cem[t] == p_cem_mach_tot[t]  + p_cem_kiln + p_cem_fix + p_cem_ccs) #total power demand - elboiler + p_nh_eb[t]

    # @constraint(m, m_cem_tot == sum(m_cem_prod[t] for t=1:T)) #Total production of Cement
    @constraint(m, [t=1:T], m_cem_prod[t] + m_cem_lost[t] == production["cement_production"]) ##Production of Cement less than nominal production

    @constraint(m, [t=1:T], m_cem_mach["crusher1",t] + m_cem_mach["crusher2",t] == m_cem_stor_in["silo1",t])
    @constraint(m, [t=1:T], m_cem_stor_out["silo1",t] == m_cem_mach["raw_mill",t])
    @constraint(m, [t=1:T], m_cem_mach["raw_mill",t] == m_cem_stor_in["silo2",t])
    @constraint(m, [t=1:T], m_cem_stor_out["silo2",t] == m_cem_kiln[t])
    @constraint(m, [t=1:T], m_cem_kiln[t] == m_cem_stor_in["silo3",t] * production["rawmeal_klinker_ratio"])
    @constraint(m, [t=1:T], m_cem_stor_out["silo3",t]  == production["klinker_fraction"] * (m_cem_mach["cement_mill1",t] + m_cem_mach["cement_mill2",t] + m_cem_mach["cement_mill3",t]))
    @constraint(m, [t=1:T], (m_cem_mach["cement_mill1",t] + m_cem_mach["cement_mill2",t] + m_cem_mach["cement_mill3",t]) == m_cem_stor_in["silo4",t])
    @constraint(m, [t=1:T], m_cem_stor_out["silo4",t] == m_cem_prod[t])



    #Crushers and mills
    @constraint(m, [t=1:T], p_cem_mach_tot[t] == sum(p_cem_mach[c,t] for c in keys(machinery)))

    for c in keys(machinery)
        @constraint(m, [t=1:T], p_cem_mach[c,t] == machinery[c]["power_demand"] * y_cem_mach[c,t])
        @constraint(m, [t=1:T], m_cem_mach[c,t] <= machinery[c]["mass_flow"] * y_cem_mach[c,t])
        @constraint(m, [t=2:T], y_cem_mach[c,t]-y_cem_mach[c,t-1] == LC_up_cem_mach[c,t]-LC_down_cem_mach[c,t])
    end

    #Storages
    for s in keys(storages)
        @constraint(m, [t=2:T], s_cem_stor[s,t] == s_cem_stor[s,t-1] + m_cem_stor_in[s,t] - m_cem_stor_out[s,t]) #change in storage level
        @constraint(m, s_cem_stor[s,1] <= s_cem_stor[s,T])  #storage level at start is equal or less than final level
        @constraint(m, s_cem_stor[s,1] == storages[s]["capacity"]*0.5)  #storage level at start is half full
        @constraint(m, [t=1:T], s_cem_stor[s,t] <= storages[s]["capacity"])  #storage charge level is less than or equal to maximum storage capacity
    end

    #Kiln
    fix.(p_cem_kiln, kiln["power_demand"], force=true)
    # fix.(m_cem_kiln, kiln["mass_flow"], force=true)
    @constraint(m, [t=1:T], m_cem_kiln[t] - kiln["mass_flow"] == dev_up_cem_kiln[t] - dev_down_cem_kiln[t])
    @constraint(m, [t=1:T], m_cem_kiln[t] <= kiln["mass_flow"]*kiln["cap_max"])
    @constraint(m, [t=1:T], m_cem_kiln[t] >= kiln["mass_flow"]*kiln["cap_min"])

    #Kiln with binary terms
    
    # @constraint(m, [t=1:T], m_cem_kiln[t] <= kiln["mass_flow"]*kiln["cap_max"]*y_kiln[t])
    # @constraint(m, [t=1:T], m_cem_kiln[t] >= kiln["mass_flow"]*kiln["cap_min"]*y_kiln[t])
    # @constraint(m, [t=1:T], p_cem_kiln[t] == kiln["power_demand"]*y_kiln[t])

    # @constraint(m, [t=1:T-1], (y_kiln[t]-y_kiln[t+1]) - 0.5 <= 10 * z_kiln[t+1]) #Determining binary for reduced load
    # @constraint(m, [t=1:T-1], 0.5 - (y_kiln[t]-y_kiln[t+1]) <= 10 * (1-z_kiln[t+1]))

    # @constraint(m, [t=1:T-1], (y_kiln[t+1]-y_kiln[t]) - 0.5 <= 10 * x_kiln[t+1]) #Determining binary for increased load
    # @constraint(m, [t=1:T-1], 0.5 - (y_kiln[t+1]-y_kiln[t]) <= 10 * (1-x_kiln[t+1]))

    # @constraint(m, [t=1:T], sum(x_kiln[t] + z_kiln[t] for t=1:T) <= 1) #When the kiln turns off, it can not turn on again in the analysis period


    #Fixed demands
    fix.(p_cem_fix, other["power_demand"], force=true)
    fix.(p_cem_ccs, other["ccs"], force=true)


    # @constraint(m, [t=1:T], p_cem_ccs[t] == other["ccs"]*y_kiln[t])

        



    println("Cement model created")

end