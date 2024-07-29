include("../src/IndClust.jl")

input=read_data()
input=grid_cap_calc(input, 1, 100, 48)
# input = grid_cap_calc(input, "input/final4weeks_2022_grenland.csv", 2200)





m_base=create_model()
optimize!(m_base)
ptot_base = value.(m_base[:p_tot])


m_base_opt=create_model()
@constraint(m_base_opt, [t=1:input["T"]], m_base_opt[:grid_capacity][t] == input["global_data"]["demand"]["grid_capacity"][t])
optimize!(m_base_opt)
ptot_base_opt = value.(m_base_opt[:p_tot])

# df = dropmissing(CSV.read("input/february_2022_firstweek_grenland.csv", DataFrame, header=1))
# existing_load = df."2022"


input["vcm"]["pem"]["capacity"] = 54.0 #54 MW pem electrolysis covers h2 demand when CAE is flexible
input["cement"]["other"]["ccs"] = 16.0 #16 MW for ccs
input["manganese"]["fe_mn"]["capacity"] = 38.0*1.1 #assume 10% increase
input["manganese"]["si_mn"]["capacity"] = 32.0*1.1 #assume 10% increase
input["ammonia"]["h2synthesis"]["h2_cap"] = 0.0
input["ammonia"]["pem"]["capacity"] = 550.0 
input["ammonia"]["nh3synthesis"]["cap_min"] = 0.6 


m_dec=create_model()
optimize!(m_dec)
ptot_dec = value.(m_dec[:p_tot])


m_dec_opt=create_model()
@constraint(m_dec_opt, [t=1:input["T"]], m_dec_opt[:grid_capacity][t] == input["global_data"]["demand"]["grid_capacity"][t])
optimize!(m_dec_opt)
ptot_dec_opt = value.(m_dec_opt[:p_tot])