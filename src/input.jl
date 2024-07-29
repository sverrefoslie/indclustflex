function read_data(input_file="input/input.yml")
    inp    = YAML.load_file(input_file)



    ### Loading demand data for area


    # inp = limit_calc_loadcurve(inp)
    duration = inp["global_data"]["flex_activation"]["duration"]
    activation_time = inp["global_data"]["flex_activation"]["activation_time"]
    capacity = inp["global_data"]["flex_activation"]["capacity"]

    inp = grid_cap_calc(inp, duration, capacity, activation_time)
    
    return inp
end


function limit_calc_loadcurve(inp=input, cap=input["global_data"]["demand"]["limit_capacity"]) #calculation of
    T0 = inp["T0"]
    T = inp["T"]
    df = dropmissing(CSV.read(inp["global_data"]["demand"]["file"], DataFrame, header=1))
    actual_load = df."Actual Total Load [MW] - BZN|NO1"
    inp["global_data"]["demand"]["load"] = actual_load[T0:T0+T-1]

    df_wind = dropmissing(CSV.read(inp["global_data"]["wind"]["file"], DataFrame, header=1))
    wind_prod = df_wind."Profile"*inp["global_data"]["wind"]["capacity"]
    inp["global_data"]["wind"]["prod"] = wind_prod[T0:T0+T-1]

    limit = sort(actual_load, rev=true)[Int64(round(inp["global_data"]["demand"]["limit_percent"]*length(actual_load)))]
    inp["global_data"]["demand"]["limit_load"] = limit
    
    
    load_curve = inp["global_data"]["demand"]["load"]
    limit_hours = zeros(length(load_curve))
    limit = inp["global_data"]["demand"]["limit_load"]
    grid_capacity = zeros(length(load_curve))
    for i in eachindex(load_curve)
        if load_curve[i] >= limit
            limit_hours[i] = 1
            grid_capacity[i] = cap
        else
            limit_hours[i] = 0
            grid_capacity[i] = inp["global_data"]["demand"]["high_capacity"]
        end
    end
    T = inp["T"]

    
    inp["global_data"]["demand"]["limit_capacity"] = cap
    inp["global_data"]["demand"]["limit_hours"] = limit_hours[1:T]
    inp["global_data"]["demand"]["grid_capacity"] = grid_capacity[1:T]
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

function grid_cap_calc(inp::Dict, file::String, grid_limit::Real) #calculation of
    df = dropmissing(CSV.read(file, DataFrame, header=1))
    existing_load = df."2022"
    T=length(existing_load)
    grid_capacity=zeros(T)
    grid_capacity = grid_limit .- existing_load

    inp["global_data"]["demand"]["grid_capacity"] = grid_capacity[1:T]
    inp["T"] = T

    return inp
end