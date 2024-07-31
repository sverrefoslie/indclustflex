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