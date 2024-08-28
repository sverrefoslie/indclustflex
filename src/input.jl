function read_data(input_file="input/input.yml")
    inp    = YAML.load_file(input_file)



    duration = inp["global_data"]["flex_activation"]["duration"]
    activation_time = inp["global_data"]["flex_activation"]["activation_time"]
    capacity = inp["global_data"]["flex_activation"]["capacity"]

    inp = grid_cap_calc(inp, duration, capacity, activation_time)
    
    return inp
end


function grid_cap_calc(inp::Dict, dur::Real, cap::Real, act::Real) #act=activation time, dur=duration of reduction, cap=grid capacity in restricted period, rec=recovery time before normal operation
    
    T = inp["T"]
    grid_capacity = zeros(T)
    grid_capacity[1:act-1] .= inp["global_data"]["demand"]["high_capacity"]
    grid_capacity[act:act+dur-1] .= cap
    grid_capacity[act+dur:T] .= inp["global_data"]["demand"]["high_capacity"]

    inp["global_data"]["demand"]["grid_capacity"] = grid_capacity[1:T]

    return inp
end


function load_calc(inp::Dict, m, file::String, grid_limit::Real, start_hour::Int64=721, duration::Int64=168, peak_hour::Int64=45) #calculation of grid capacity in grenland_transmission
    df = dropmissing(CSV.read(file, DataFrame, header=1))
    df = df[start_hour:start_hour+duration-1,:]
    case=inp["global_data"]["demand"]["case_grid"]

    no2_no1 = df."NO2-NO1"
    no2_hydro_river = df."NO2_hydro_river"
    no2_hydro_storage = df."NO2_hydro_storage"
    no1_load = df."NO1_actual_load"
    T=length(no2_no1)

    case["hasle_tveiten"]["other_demand"] = no2_no1 * case["hasle_tveiten"]["fraction"]
    case["grenland"]["generation"] = case["grenland"]["hydro_river"] * no2_hydro_river / case["NO2"]["hydro_river"] + case["grenland"]["hydro_storage"] * no2_hydro_storage / case["NO2"]["hydro_storage"]
    case["roed"]["generation"] = case["roed"]["hydro_river"] * no2_hydro_river / case["NO2"]["hydro_river"] + case["roed"]["hydro_storage"] * no2_hydro_storage / case["NO2"]["hydro_storage"]

    p_ind_grenland=value.(m[:p_vcm])+value.(m[:p_mn])
    p_ind_porsgrunn_heroya=value.(m[:p_nh])+value.(m[:p_cem])

    roed_other_peak = case["roed"]["peak"] + case["roed"]["generation"][peak_hour]
    case["roed"]["other_demand"] = roed_other_peak/no1_load[peak_hour]*no1_load

    porsgrunn_heroya_other_peak = case["porsgrunn_heroya"]["peak"] - p_ind_porsgrunn_heroya[peak_hour]
    case["porsgrunn_heroya"]["other_demand"] = porsgrunn_heroya_other_peak/no1_load[peak_hour]*no1_load

    grenland_other_peak = case["grenland"]["peak"] - p_ind_grenland[peak_hour] + case["grenland"]["generation"][peak_hour]
    case["grenland"]["other_demand"] = grenland_other_peak/no1_load[peak_hour]*no1_load

    total_demand = case["hasle_tveiten"]["other_demand"] + case["roed"]["other_demand"] + case["grenland"]["other_demand"] + p_ind_grenland + case["porsgrunn_heroya"]["other_demand"] + p_ind_porsgrunn_heroya
    total_generation = case["grenland"]["generation"] + case["roed"]["generation"] 

    grid_capacity=zeros(T)
    grid_capacity = grid_limit .- total_demand .+ total_generation


    inp["global_data"]["demand"]["case_grid"]=case
    inp["global_data"]["demand"]["grid_capacity"] = grid_capacity[1:T]
    inp["T"] = T

    return inp
end