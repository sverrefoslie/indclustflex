function mn_preprocess(inp)
    for i in keys(inp["manganese"])
        inp["manganese"][i]["nominal_prod"] = inp["T"]*inp["manganese"][i]["capacity"]/inp["manganese"][i]["power_demand"]
    end
    return inp
end

function mn_model(m, T::Integer, global_data::Dict, mn::Dict)

    femn         = mn["fe_mn"]
    simn         = mn["si_mn"]

    prices      = global_data["prices"]
    properties  = global_data["properties"]


    ### Variables ###
    @variable(m, 0 <= c_en_mn)
    @variable(m, 0 <= c_ll_mn)
    @variable(m, 0 <= p_mn[1:T])
    @variable(m, 0 <= p_mn_femn[1:T])
    @variable(m, 0 <= p_mn_simn[1:T])
    @variable(m, 0 <= ṁ_mn_femn[1:T])
    @variable(m, 0 <= ṁ_mn_simn[1:T])
    @variable(m, 0 <= m_mn_femn_tot)
    @variable(m, 0 <= m_mn_simn_tot)
    @variable(m, z_mn_femn[1:T], Bin) #Binary "run" variable, equal to 1 if full load, and equal to 0 at reduced load
    @variable(m, y_mn_femn[1:T], Bin) #Binary "stop" variable equal to 1 if operation is reduced in period t
    @variable(m, x_mn_femn[1:T], Bin) #Binary "start" variable equal to 1 if operation is increased in period t
    @variable(m, z_mn_simn[1:T], Bin) #Binary "run" variable, equal to 1 if full load, and equal to 0 at reduced load
    @variable(m, y_mn_simn[1:T], Bin) #Binary "stop" variable equal to 1 if operation is reduced in period t
    @variable(m, x_mn_simn[1:T], Bin) #Binary "start" variable equal to 1 if operation is increased in period t



    #Cost functions
    @constraint(m, c_en_mn == sum(prices["electricity"] * p_mn[t] for t=1:T))
    @constraint(m, c_ll_mn == femn["product_price"] * (femn["nominal_prod"]-m_mn_femn_tot) + simn["product_price"] * (simn["nominal_prod"]-m_mn_simn_tot))

    #Stream and energy connections
    @constraint(m, [t=1:T], p_mn[t] == p_mn_femn[t] + p_mn_simn[t]) #total power demand

    #FeMn production
    @constraint(m, [t=1:T], p_mn_femn[t] == ṁ_mn_femn[t]*femn["power_demand"]) #mass produced FeMn times power demand
    @constraint(m, [t=1:T], p_mn_femn[t] <= femn["capacity"]) #maximum capacity of oven
    @constraint(m, [t=1:T], p_mn_femn[t] >= femn["capacity"]*femn["cap_min"]) #minimum operation limit of oven
    @constraint(m, m_mn_femn_tot == sum(ṁ_mn_femn[t] for t=1:T)) #Total production of FeMn
    @constraint(m, m_mn_femn_tot <= femn["nominal_prod"]) #Total production of FeMn less than nominal production

    @constraint(m, [t=1:T], p_mn_femn[t] - femn["capacity"]*(1-femn["eps"]) <= 100 * z_mn_femn[t]) # Binary determining whether operation is below nominal capacity
    @constraint(m, [t=1:T], femn["capacity"]*(1-femn["eps"]) - p_mn_femn[t] <= 100 * (1 - z_mn_femn[t])) # Binary determining whether operation is below nominal capacity
    
    @constraint(m, [t=1:T-femn["max_red"]], sum(z_mn_femn[t+i] for i=0:femn["max_red"]) >= 1) #maximum four in a row below full operation


    @constraint(m, [t=1:T-1], (z_mn_femn[t]-z_mn_femn[t+1]) - 0.5 <= 10 * y_mn_femn[t+1]) #Determining binary for reduced load activation
    @constraint(m, [t=1:T-1], 0.5 - (z_mn_femn[t]-z_mn_femn[t+1]) <= 10 * (1-y_mn_femn[t+1]))

    @constraint(m, [t=1:T-1], (z_mn_femn[t+1]-z_mn_femn[t]) - 0.5 <= 10 * x_mn_femn[t+1]) #Determining binary for reduced load deactivation
    @constraint(m, [t=1:T-1], 0.5 - (z_mn_femn[t+1]-z_mn_femn[t]) <= 10 * (1-x_mn_femn[t+1]))

    @constraint(m, [t=1:T-femn["delay"]], x_mn_femn[t] + sum(y_mn_femn[t+i] for i=0:femn["delay"]) <= 1) #Minimum period between two load reductions


    #SiMn production
    @constraint(m, [t=1:T], p_mn_simn[t] == ṁ_mn_simn[t]*simn["power_demand"]) #mass produced FeMn times power demand
    @constraint(m, [t=1:T], p_mn_simn[t] <= simn["capacity"]) #maximum capacity of oven
    @constraint(m, [t=1:T], p_mn_simn[t] >= simn["capacity"]*simn["cap_min"]) #minimum operation limit of oven
    @constraint(m, m_mn_simn_tot == sum(ṁ_mn_simn[t] for t=1:T)) #Total production of FeMn
    @constraint(m, m_mn_simn_tot <= simn["nominal_prod"]) #Total production of FeMn less than nominal production

    @constraint(m, [t=1:T], p_mn_simn[t] - simn["capacity"]*(1-simn["eps"])<= 2*simn["capacity"] * z_mn_simn[t]) # Binary determining whether operation is below nominal capacity
    @constraint(m, [t=1:T], simn["capacity"]*(1-simn["eps"]) - p_mn_simn[t] <= 2*simn["capacity"] * (1 - z_mn_simn[t])) # Binary determining whether operation is below nominal capacity
    
    @constraint(m, [t=1:T-simn["max_red"]], sum(z_mn_simn[t+i] for i=0:simn["max_red"]) >= 1) #maximum four in a row below full operation

    @constraint(m, [t=1:T-1], (z_mn_simn[t]-z_mn_simn[t+1]) - 0.5 <= 10 * y_mn_simn[t+1]) #Determining binary for reduced load activation(y)
    @constraint(m, [t=1:T-1], 0.5 - (z_mn_simn[t]-z_mn_simn[t+1]) <= 10 * (1-y_mn_simn[t+1]))

    @constraint(m, [t=1:T-1], (z_mn_simn[t+1]-z_mn_simn[t]) - 0.5 <= 10 * x_mn_simn[t+1]) #Determining binary for reduced load deactivation (x)
    @constraint(m, [t=1:T-1], 0.5 - (z_mn_simn[t+1]-z_mn_simn[t]) <= 10 * (1-x_mn_simn[t+1]))

    @constraint(m, [t=1:T-simn["delay"]], x_mn_simn[t] + sum(y_mn_simn[t+i] for i=0:simn["delay"]) <= 1) #Minimum period between two load reductions

    

    println("Mn model created")

end