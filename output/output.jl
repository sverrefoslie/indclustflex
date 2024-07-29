using Statistics
using DataFrames
using XLSX

function main_output(m, inp)
    df=DataFrame()
    df."T" = [inp["T"]]
    df."el_price" = [inp["global_data"]["prices"]["electricity"]]
    df."ng_price" = [inp["global_data"]["prices"]["natural_gas"]]
    df."em_price" = [inp["global_data"]["prices"]["emissions"]]

    df."obj" = [objective_value(m)]

    df."c_en_tot" = [value(m[:c_en_tot])]
    df."c_em_tot" = [value(m[:c_em_tot])]
    df."c_ll_tot" = [value(m[:c_ll_tot])]
    df."c_lc_tot" = [value(m[:c_lc_tot])]
    df."c_gd_tot" = [value(m[:c_gd_tot])]

    df."c_en_vcm" = [value(m[:c_en_vcm])]
    df."c_en_mn" = [value(m[:c_en_mn])]
    df."c_en_nh" = [value(m[:c_en_nh])]
    df."c_en_cem" = [value(m[:c_en_cem])]
    
    df."c_em_vcm" = [value(m[:c_em_vcm])]
    df."c_em_nh" = [value(m[:c_em_nh])]

    df."c_ll_mn" = [value(m[:c_ll_mn])]
    df."c_ll_cem" = [value(m[:c_ll_cem])]
    df."c_ll_nh" = [value(m[:c_ll_nh])]

    df."c_lc_vcm" = [value(m[:c_lc_vcm])]
    df."c_lc_cem" = [value(m[:c_lc_cem])]
    
    df."c_lc_cem_lcc" = [value(m[:c_lc_cem_lcc])]
    df."c_lc_cem_dev" = [value(m[:c_lc_cem_dev])]
    df."c_lc_cem_disc" = [value(m[:c_lc_cem_disc])]

    T = inp["T"]

    df."gd_tot" = [sum(value.(m[:p_gd][t] for t=1:T))]
    df."gd_max" = [maximum(value.(m[:p_gd]))]

    df."Total electricity" = [sum(value.(m[:p_tot][t] for t=1:T))]
    df."Maximum electricity" = [maximum(value.(m[:p_tot]))]
    df."el_tot_nh" = [sum(value.(m[:p_nh][t] for t=1:T))]
    df."el_tot_cem" = [sum(value.(m[:p_cem][t] for t=1:T))]
    df."el_tot_mn" = [sum(value.(m[:p_mn][t] for t=1:T))]
    df."el_tot_vcm" = [sum(value.(m[:p_vcm][t] for t=1:T))]

    df."Total gas" = [sum(value.((m[:g_nh][t] + m[:g_vcm][t]) for t=1:T))]
    df."NH gas" = [sum(value.((m[:g_nh][t]) for t=1:T))]
    df."VCM gas" = [sum(value.((m[:g_vcm][t]) for t=1:T))]

    df."NH pem" = [sum(value.((m[:p_nh_pem][t]) for t=1:T))]
    df."VCM pem" = [sum(value.((m[:p_vcm_pem][t]) for t=1:T))]

    println("Results added to dataframe")

    return df
end



