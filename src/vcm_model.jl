function vcm_preprocess(inp)
    p_h2e = inp["standard_techs"]["pem"]["p_h2e"]
    p_h2soec = inp["standard_techs"]["soec"]["p_h2_soec"]

    inp["standard_techs"]["pem"]["ρ_h2e"] = PropsSI("D", "T", 298, "P", p_h2e*1e6, "Hydrogen")
    inp["standard_techs"]["soec"]["ρ_h2_soec"] = PropsSI("D", "T", 298, "P", p_h2soec*1e6, "Hydrogen")
    
    inp["vcm"]["pem"]["ρ_h2e"] = PropsSI("D", "T", 298, "P", p_h2e*1e6, "Hydrogen")
    inp["vcm"]["soec"]["ρ_h2_soec"] = PropsSI("D", "T", 298, "P", p_h2soec*1e6, "Hydrogen")

    p_h2s = inp["standard_techs"]["h2stor"]["pressure"]
    p_h2s_in = inp["standard_techs"]["h2stor"]["pressure_in"]
    ρ_h2s_in = PropsSI("D", "T", 298, "P", p_h2s_in*1e6, "Hydrogen")

    inp["standard_techs"]["h2stor"]["θ_h2s"] = p_h2s_in/ρ_h2s_in*log(p_h2s/p_h2s_in) *1e3/3600
    inp["vcm"]["h2stor"]["θ_h2s"] = p_h2s_in/ρ_h2s_in*log(p_h2s/p_h2s_in) *1e3/3600
    return inp
end

function vcm_model(m, T::Integer, global_data::Dict, vcm::Dict)

    CAE         = vcm["cae"]
    DC          = vcm["dc"]
    EDC_stor    = vcm["edc_stor"]
    Cracker     = vcm["cracker"]
    PEM         = vcm["pem"]
    SOEC        = vcm["soec"]
    H2stor      = vcm["h2stor"]
    H2imp       = vcm["h2imp"]

    prices      = global_data["prices"]
    properties      = global_data["properties"]


    ### Variables ###
    @variable(m, 0 <= c_en_vcm)
    @variable(m, 0 <= c_lc_vcm)
    @variable(m, 0 <= c_em_vcm)
    @variable(m, 0 <= p_vcm_cae[1:T])
    @variable(m, 0 <= p_vcm_pem[1:T])
    @variable(m, 0 <= p_vcm[1:T])
    @variable(m, 0 <= em_vcm[1:T])
    @variable(m, 0 <= h_vcm_imp[1:T])
    @variable(m, b_vcm_pem[1:T], Bin)
    @variable(m, 0 <= ṁ_cl2_vcm_CAE[1:T]) 
    @variable(m, 0 <= ṅ_cl2_vcm_CAE[1:T])
    @variable(m, 0 <= ṁ_h2_vcm_CAE[1:T])
    @variable(m, 0 <= h_vcm_CAE[1:T])
    @variable(m, 0 <= ṅ_h2_vcm_CAE[1:T])
    @variable(m, 0 <= LC_up_vcm_CAE[1:T] <= 1)
    @variable(m, 0 <= LC_down_vcm_CAE[1:T] <= 1)
    @variable(m, 0 <= ṅ_EDC_vcm_DC[1:T])
    @variable(m, 0 <= ṅ_cl2_vcm_DC[1:T])
    @variable(m, 0 <= ṅ_EDC_vcm_OXC[1:T])
    @variable(m, 0 <= ṅ_hcl_vcm_OXC[1:T])
    @variable(m, 0 <= ṅ_EDC_vcm_stor_in[1:T])
    @variable(m, 0 <= ṅ_EDC_vcm_stor_out[1:T])
    @variable(m, 0 <= n_EDC_vcm_stor[1:T])
    @variable(m, 0 <= m_EDC_vcm_stor[1:T])
    @variable(m, 0 <= ṅ_EDC_vcm_cr[1:T])
    @variable(m, 0 <= ṁ_EDC_vcm_cr[1:T])
    @variable(m, 0 <= ṅ_hcl_vcm_cr[1:T])
    @variable(m, 0 <= q_vcm_cr[1:T])
    @variable(m, 0 <= ṅ_VCM_vcm_cr[1:T])
    @variable(m, 0 <= ṁ_VCM_vcm_cr[1:T])
    @variable(m, 0 <= ṁ_h2_vcm_cr_in[1:T])
    @variable(m, 0 <= g_vcm[1:T])
    @variable(m, 0 <= g_vcm_cr[1:T])
    @variable(m, 0 <= h_vcm_cr[1:T])
    @variable(m, 0 <= em_vcm_cr[1:T])
    @variable(m, 0 <= p_vcm_cr[1:T])
    @variable(m, 0 <= h_vcm_stor_out[1:T])
    @variable(m, 0 <= h_vcm_stor_in[1:T])
    @variable(m, 0 <= s_vcm_h2_stor[1:T])
    @variable(m, 0 <= h_vcm_stor_bypass[1:T])
    @variable(m, 0 <= p_vcm_h2_stor[1:T])
    @variable(m, 0 <= h_vcm_pem[1:T])
    @variable(m, 0 <= p_vcm_pemstack[1:T])
    @variable(m, 0 <= q_vcm_OXC[1:T])
    @variable(m, 0 <= h_vcm_soec[1:T])
    @variable(m, 0 <= p_vcm_soecstack[1:T])
    @variable(m, 0 <= p_vcm_soec[1:T])
    @variable(m, 0 <= h_vcm_exp[1:T])
    @variable(m, 0 <= q_vcm_soec[1:T])
    @variable(m, b_vcm_soec[1:T], Bin)


    # ### Objective function ###


    # @objective(m, Min, c_en_vcm + c_lc_vcm + c_em_vcm) # 


    ### Constraints ###

    ###Can be added in the input.yml file?

    # ###decarbonized
    # if decarbonized
        # fix.(em_vcm[1:T], 0, force=true)
    # end

    # if pure_green
    #     fix.(h_vcm_imp[1:T], 0, force=true)
    # end

    if H2imp
    else
        fix.(h_vcm_imp[1:T], 0, force=true)
    end

    #Initial value
    @constraint(m, p_vcm_cae[1] == CAE["P0_CAE"]) 


    #Cost functions
    
    @constraint(m, c_lc_vcm == sum(CAE["c_LCC"]*(LC_up_vcm_CAE[t] + LC_down_vcm_CAE[t]) for t=1:T))
    @constraint(m, c_em_vcm == sum(em_vcm[t] * prices["emissions"] for t=1:T))
    @constraint(m, c_en_vcm == sum(prices["electricity"] * p_vcm[t] +  prices["natural_gas"] * g_vcm[t] + prices["hydrogen"] * h_vcm_imp[t] for t=1:T))

    #Stream and energy connections
    @constraint(m, [t=1:T], p_vcm[t] == p_vcm_cae[t] + p_vcm_pem[t] + p_vcm_h2_stor[t] + p_vcm_soec[t] + p_vcm_cr[t])
    @constraint(m, [t=1:T], ṅ_cl2_vcm_CAE[t] == ṅ_cl2_vcm_DC[t])
    @constraint(m, [t=1:T], ṅ_hcl_vcm_OXC[t] == ṅ_hcl_vcm_cr[t])
    @constraint(m, [t=1:T], ṅ_EDC_vcm_stor_in[t] == ṅ_EDC_vcm_OXC[t] + ṅ_EDC_vcm_DC[t]) #storage inflow
    @constraint(m, [t=1:T], ṅ_EDC_vcm_stor_out[t] == ṅ_EDC_vcm_cr[t])
    @constraint(m, [t=1:T], h_vcm_cr[t] == h_vcm_stor_out[t] + h_vcm_stor_bypass[t] + h_vcm_CAE[t] + h_vcm_imp[t] + h_vcm_soec[t] - h_vcm_exp[t])
    @constraint(m, [t=1:T], h_vcm_stor_in[t] + h_vcm_stor_bypass[t] == h_vcm_pem[t]) #storage inflow
    @constraint(m, [t=1:T], ṁ_VCM_vcm_cr[t] == Cracker["prod_rate"]) 
    @constraint(m, [t=1:T], g_vcm[t] == g_vcm_cr[t]) 
    @constraint(m, [t=1:T], em_vcm[t] == em_vcm_cr[t]) 
    @constraint(m, [t=1:T], q_vcm_soec[t] <= q_vcm_OXC[t]) 



    #CAE
    @constraint(m, [t=1:T], p_vcm_cae[t] == ṁ_cl2_vcm_CAE[t] * CAE["θ_cae"])    #power demand of CAE as product of mass of CL and energy intensity
    @constraint(m, [t=1:T], ṁ_cl2_vcm_CAE[t] == ṅ_cl2_vcm_CAE[t] * properties["M_cl2"])     #mass to mole conversion of Cl
    @constraint(m, [t=1:T], ṅ_cl2_vcm_CAE[t] == ṅ_h2_vcm_CAE[t])            #moles of chlorine equals moles of H2
    @constraint(m, [t=1:T], ṁ_h2_vcm_CAE[t] == ṅ_h2_vcm_CAE[t] * properties["M_h2"])      #mole to mass of h2
    @constraint(m, [t=1:T], h_vcm_CAE[t] == ṁ_h2_vcm_CAE[t] * properties["LHV_h2"])      #mass to energy of h2
    @constraint(m, [t=1:T], p_vcm_cae[t] <= CAE["Cmax_CAE"] * CAE["P0_CAE"]) #maximum operation CAE
    @constraint(m, [t=1:T], CAE["Cmin_CAE"] * CAE["P0_CAE"] <= p_vcm_cae[t]) #minimum operation CAE
    @constraint(m, [t=2:T], p_vcm_cae[t] - p_vcm_cae[t-1] <= CAE["δ_CAE"] * CAE["P0_CAE"]) #ramping constraint upwards
    @constraint(m, [t=2:T], p_vcm_cae[t] - p_vcm_cae[t-1] >= - CAE["δ_CAE"] * CAE["P0_CAE"]) #ramping constraint upwards
    # @constraint(m, [t=2:T], p_vcm_cae[t-1] - p_vcm_cae[t] <= CAE["δ_CAE"] * CAE["P0_CAE"])  #ramping constraint downwards
    @constraint(m, [t=2:T], p_vcm_cae[t] - p_vcm_cae[t-1] == (LC_up_vcm_CAE[t] - LC_down_vcm_CAE[t]) * (CAE["P0_CAE"]*(1-CAE["Cmin_CAE"]))) #Load change, CAE

    #DC
    @constraint(m, [t=1:T], ṅ_EDC_vcm_DC[t] == ṅ_cl2_vcm_DC[t])            #mole of EDC equals mole of cl2
    @constraint(m, [t=2:T], ṅ_EDC_vcm_DC[t] - ṅ_EDC_vcm_DC[t-1] <= DC["δ_DC"] * ((CAE["P0_CAE"]/CAE["θ_cae"])/properties["M_cl2"])  ) #ramping constraint upwards
    @constraint(m, [t=2:T], ṅ_EDC_vcm_DC[t] - ṅ_EDC_vcm_DC[t-1] >= - DC["δ_DC"] * ((CAE["P0_CAE"]/CAE["θ_cae"])/properties["M_cl2"])) #ramping constraint downwards
    @constraint(m, [t=1:T], ṅ_cl2_vcm_DC[t] <= DC["Cmax_DC"] * ((CAE["P0_CAE"]/CAE["θ_cae"])/properties["M_cl2"])) #maximum operation DC
    @constraint(m, [t=1:T], DC["Cmin_DC"] * ((CAE["P0_CAE"]/CAE["θ_cae"])/properties["M_cl2"]) <= ṅ_cl2_vcm_DC[t]) #minimum operation DC

    #OXC
    @constraint(m, [t=1:T], ṅ_EDC_vcm_OXC[t] == ṅ_hcl_vcm_OXC[t]/2)
    @constraint(m, [t=1:T], q_vcm_OXC[t] == ṅ_EDC_vcm_OXC[t] * properties["M_EDC"] * properties["h_evap_EDC"]) #heat of evaporation available when condensing EDC

    #EDC Storage
    @constraint(m, [t=2:T], n_EDC_vcm_stor[t] == n_EDC_vcm_stor[t-1] + ṅ_EDC_vcm_stor_in[t] - ṅ_EDC_vcm_stor_out[t]) #change in storage level
    @constraint(m, n_EDC_vcm_stor[1] == n_EDC_vcm_stor[T])  #storage level at start is equal or less than final level
    @constraint(m, [t=1:T], m_EDC_vcm_stor[t] == n_EDC_vcm_stor[t] * properties["M_EDC"])  
    @constraint(m, [t=1:T], m_EDC_vcm_stor[t] <= EDC_stor["capacity"])  #storage charge level is less than or equal to maximum storage capacity

    #Cracker
    @constraint(m, [t=1:T], ṅ_EDC_vcm_cr[t] == ṅ_hcl_vcm_cr[t])          #moles of EDC to cracker equals moles of HCl to OXC
    @constraint(m, [t=1:T], ṁ_EDC_vcm_cr[t] == ṅ_EDC_vcm_cr[t] * properties["M_EDC"])
    @constraint(m, [t=1:T], q_vcm_cr[t] == ṁ_VCM_vcm_cr[t] * Cracker["θ_cr"])   #heating demand of cracker as product of EDC input and thermal demand per ton 
    @constraint(m, [t=1:T], ṅ_EDC_vcm_cr[t] == ṅ_VCM_vcm_cr[t])
    @constraint(m, [t=1:T], ṁ_VCM_vcm_cr[t] == ṅ_VCM_vcm_cr[t] * properties["M_VCM"])
    @constraint(m, [t=1:T], em_vcm_cr[t] >= g_vcm_cr[t] * properties["ϕ_ng"])  #emissions from cracker [ton]
    @constraint(m, [t=1:T], q_vcm_cr[t] == Cracker["η_cr_g"] * (h_vcm_cr[t] + g_vcm_cr[t]))

    #H2 storage
    @constraint(m, [t=2:T], s_vcm_h2_stor[t] == s_vcm_h2_stor[t-1] + h_vcm_stor_in[t] - h_vcm_stor_out[t]) #change in storage level
    @constraint(m, s_vcm_h2_stor[1] <= s_vcm_h2_stor[T])  #storage level at start is equal or less than final level
    @constraint(m, [t=1:T], s_vcm_h2_stor[t] <= H2stor["capacity"])  #storage charge level is less than or equal to maximum storage capacity
    @constraint(m, [t=1:T], p_vcm_h2_stor[t] == h_vcm_stor_in[t]/properties["LHV_h2"]*H2stor["θ_h2s"]) #Power demand for h2 compressors
    @constraint(m, [t=1:T], h_vcm_stor_in[t] <= H2stor["capacity"]*100)  #ensuring no use of the storage in case of zero capacity (to avoid utilization in case of negative electricity prices)
    @constraint(m, [t=1:T], h_vcm_stor_out[t] <= H2stor["capacity"]*100)  #ensuring no use of the storage in case of zero capacity (to avoid utilization in case of negative electricity prices)

    #PEM electrolyzer
    @constraint(m, [t=1:T], h_vcm_pem[t] == p_vcm_pemstack[t] * PEM["efficiency"]) #Produced hydrogen as product of el demand at stack and efficiency
    @constraint(m, [t=1:T], p_vcm_pem[t] * PEM["η_h2e_power"] == p_vcm_pemstack[t]) #power demand at stack as product of power from grid and efficiency
    @constraint(m, [t=1:T], p_vcm_pem[t] <= PEM["capacity"] * b_vcm_pem[t])#
    @constraint(m, [t=1:T], PEM["Cmin_h2e"] * PEM["capacity"] * b_vcm_pem[t] <= p_vcm_pem[t] )


    #SOEC electrolyzer
    @constraint(m, [t=1:T], h_vcm_soec[t] == p_vcm_soecstack[t] * SOEC["efficiency"]) #Produced hydrogen as product of el demand at stack and efficiency
    @constraint(m, [t=1:T], p_vcm_soec[t] * SOEC["η_h2soec_power"] == p_vcm_soecstack[t]) #power demand at stack as product of power from grid and efficiency
    @constraint(m, [t=1:T], p_vcm_soec[t] <= SOEC["capacity"] * b_vcm_soec[t]) # 
    @constraint(m, [t=1:T], SOEC["Cmin_h2_soec"]  * SOEC["capacity"] * b_vcm_soec[t] <= p_vcm_soec[t])
    @constraint(m, [t=1:T], h_vcm_soec[t] *  SOEC["θ_q_h2_soec"] == q_vcm_soec[t]) #Heat demand is a product of H2-production and heat energy demand



    println("VCM model created")

end