


function create_model(input::Dict=input)


    ### Some preprocessing of data for VCM plant

    input = vcm_preprocess(input)

    ### Some preprocessing of data for Mn plant

    input = mn_preprocess(input)

    ### Some preprocessing of data for Cement plant

    input = cem_preprocess(input)
    
    ### Preprocessing for NH3-plant

    input = nh_preprocess(input)

    ### Model building

    m = JuMP.Model(Gurobi.Optimizer)
    set_optimizer_attribute(m, "MIPGap", 1e-3)

    T               =   input["T"]
    global_data     =   input["global_data"]
    vcm             =   input["vcm"]
    mn              =   input["manganese"]
    nh              =   input["ammonia"]
    cem              =   input["cement"]

    ### Variables ###
    @variable(m, 0 <= c_en_tot) #energy cost
    @variable(m, 0 <= c_em_tot) #energy cost
    @variable(m, 0 <= c_ll_tot) #lost load cost
    @variable(m, 0 <= c_lc_tot) #load change cost
    @variable(m, 0 <= c_gd_tot) #grid deficit cost
    # @variable(m, 0 <= c_en_tot_bar) #energy cost
    # @variable(m, 0 <= c_em_tot_bar) #energy cost
    # @variable(m, 0 <= c_ll_tot_bar) #lost load cost
    # @variable(m, 0 <= c_lc_tot_bar) #load change cost
    # @variable(m, 0 <= c_gd_tot_bar) #grid deficit cost
    @variable(m, 0 <= em_tot[1:T]) #total power demand
    @variable(m, 0 <= p_tot[1:T]) #total power demand
    @variable(m, 0 <= p_gd[1:T]) #grid deficit
    @variable(m, grid_capacity[1:T]) #grid limit

    # fact1_variables(m, input)

    ## Objective ##
    @objective(m, Min, c_en_tot + c_em_tot + c_ll_tot + c_lc_tot + c_gd_tot)# 

    
    ## Constraints ##
    # @constraint(m, c_en_tot_bar == c_en_tot * 10^-1)
    # @constraint(m, c_em_tot_bar == c_em_tot * 10^-1)
    # @constraint(m, c_ll_tot_bar == c_ll_tot * 10^1)
    # @constraint(m, c_lc_tot_bar == c_lc_tot * 10^1)
    # @constraint(m, c_gd_tot_bar == c_gd_tot * 10^0)
    
    vcm_model(m, T, global_data, vcm)
    mn_model(m, T, global_data, mn)
    nh_model(m, T, global_data, nh)
    cem_model(m, T, global_data, cem)


    ### Cost contraints
    @constraint(m, c_en_tot == m[:c_en_vcm] + m[:c_en_mn] + m[:c_en_nh] + m[:c_en_cem]) #energy cost # 
    @constraint(m, c_em_tot == m[:c_em_vcm] + m[:c_em_nh]) #emission cost # 
    @constraint(m, c_ll_tot == m[:c_ll_mn] + m[:c_ll_cem] + m[:c_ll_nh]) #cost of lost load (or production)
    @constraint(m, c_lc_tot == m[:c_lc_vcm] + m[:c_lc_cem]) #cost of load change
    @constraint(m, c_gd_tot == sum(p_gd[t] for t=1:T)*global_data["prices"]["grid_deficit"]) #cost of grid deficit


    ### Other constraints
    @constraint(m, [t=1:T], p_tot[t]  == m[:p_vcm][t] + m[:p_mn][t] + m[:p_nh][t] + m[:p_cem][t]) # total power equals total demand minus grid deficit
    @constraint(m, [t=1:T], p_tot[t] - p_gd[t] <= grid_capacity[t] ) #testing for reduced load
    @constraint(m, [t=1:T], em_tot[t]  == m[:em_vcm][t] + m[:em_nh][t]) # emissions for the processes with alternative fuels
    # @constraint(m, [t=1:T], p_tot[t] <= global_data["demand"]["grid_capacity"][t] ) #testing for reduced load

    # @constraint(m, c_en_tot ==  m[:c_en_cem]) #energy cost # 
    # @constraint(m, c_ll_tot ==  m[:c_ll_cem]) #cost of lost load (or production)
    # @constraint(m, [t=1:T], p_tot[t] == m[:p_cem][t]) # 
    # @constraint(m, [t=1:T], p_tot[t] <= global_data["demand"]["grid_capacity"][t]) #testing for reduced load



    println("Model created")

    return m

end
