include("../src/IndClust.jl")

input=read_data("input/input.yml") #reads the yaml input-file to a dict
input=grid_cap_calc(input, 1, 100, 48) #Calculating a grid capacity. In this case, a 1 hour capacity restriction at 100 MW, starting 48 hours after the first timestep
# input = grid_cap_calc(input, "input/final4weeks_2022_grenland.csv", 2200) #Alternative grid capacity restriction, using the specified file as a load profile, and the number as the available grid capacity


## If the decarbonized specs are to be used:
# input["vcm"]["pem"]["capacity"] = 54.0 #54 MW pem electrolysis covers h2 demand when CAE is flexible
# input["cement"]["other"]["ccs"] = 16.0 #16 MW for ccs
# input["manganese"]["fe_mn"]["capacity"] = 38.0*1.1 #assume 10% increase
# input["manganese"]["si_mn"]["capacity"] = 32.0*1.1 #assume 10% increase
# input["ammonia"]["h2synthesis"]["h2_cap"] = 0.0
# input["ammonia"]["pem"]["capacity"] = 550.0 
# input["ammonia"]["nh3synthesis"]["cap_min"] = 0.6 


m=create_model(input) #Creates the JuMP model

@constraint(m, [t=1:input["T"]], m[:grid_capacity][t] == input["global_data"]["demand"]["grid_capacity"][t]) #Adds a grid capacity limitation

optimize!(m) #Optimizes the model

df_main_results = main_output(m,input) #Extracts some main results to a dataframe