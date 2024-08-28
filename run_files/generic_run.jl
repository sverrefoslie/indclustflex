include("../src/IndClust.jl")

input=read_data("input/input.yml") #reads the yaml input-file to a dict

####For a single grid capacity reduction
input=grid_cap_calc(input, 1, 100, 48) #Calculating a grid capacity. In this case, a 1 hour capacity restriction at 100 MW, starting 48 hours after the first timestep
#####

####For a capacity limitation based on a grid-limitation with case specific generation and demand profiles
# m_base=create_model(input)
# optimize!(m_base)
# input=load_calc(input, m_base, "input/load_data.csv", 2200)
####


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