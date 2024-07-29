using Plots
using PlotlyJS
using XLSX
using LaTeXStrings

function load()
    y1=plot()
    hours=1:1:168
    load=input["global_data"]["demand"]["load"][hours]

    y1 = plot!(hours, load, label="NO1 consumption")

    plot!([6091], seriestype = "hline", label = "Grid limit")

    y1=plot!(xlabel = "Hour", ylabel = "Electricity demand [MW]", 
        # legend=:bottomright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        # ylims=(50,200),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(10),
        ytickfont=font(10),
        guidefont=font(10),
        legendfont=font(10)
    )

    return y1
end
function demand_year()
    y1=plot()
    df = dropmissing(CSV.read(input["global_data"]["demand"]["file"], DataFrame, header=1))
    actual_load = df."Actual Total Load [MW] - BZN|NO1"
    load=sort(actual_load, rev=true)

    y1 = plot!(load, label="NO1 consumption")

    plot!([6091], seriestype = "hline", label = "Grid limit")
    plot!([175], seriestype = "vline", label = "175 hours")

    y1=plot!(xlabel = "Hours", ylabel = "Electricity demand [MW]", 
        # legend=:bottomright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        # ylims=(50,200),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(18),
        ytickfont=font(18),
        guidefont=font(18),
        legendfont=font(18)
    )

    return y1
end

function demand_year_ind(m)
    y1=plot()
    df = dropmissing(CSV.read(input["global_data"]["demand"]["file"], DataFrame, header=1))
    actual_load = df."Actual Total Load [MW] - BZN|NO1"
    df_wind=dropmissing(CSV.read(input["global_data"]["wind"]["file"], DataFrame, header=1))."Profile"[1:8760]*1400.0
    
    total_load = zeros(length(actual_load))
    total_load .= actual_load + value.(m[:p_tot])
    
    load = sort(total_load, rev=true)
    y1 = plot!(load, label="NO1 consumption + ind.demand")

    plot!([6091], seriestype = "hline", label = "Grid limit")
    # plot!([175], seriestype = "vline", label = "175 hours")

    y1=plot!(xlabel = "Hours", ylabel = "Electricity demand [MW]", 
        # legend=:bottomright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        # ylims=(50,200),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(18),
        ytickfont=font(18),
        guidefont=font(18),
        legendfont=font(18)
    )

    return y1
end

function load_curve(m1=m_base, m2=m_case1, m3=m_case2)

    data = [value.(m1[:p_tot]) value.(m2[:p_tot]) value.(m3[:p_tot])]
    labels = ["Base case, as-is" "Case 1, planned upgrades" "Case 2, planned upgrades and grid limit"]
    plot(
        data,
        label=labels,
        xlabel = "Hours", 
        ylabel = "Electricity demand [MW]", 
        # legend=:bottomright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        ylims=(0,350),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(10),
        ytickfont=font(10),
        guidefont=font(10),
        legendfont=font(10)
    )
end

function flex_provider(m1=m_base, m2=m_case1, m3=m_case2)
    p_diff_mn=zeros(length(value.(m3[:p_mn])))
    p_diff_nh=zeros(length(value.(m3[:p_nh])))
    p_diff_vcm=zeros(length(value.(m3[:p_vcm])))
    p_diff_mn .= value.(m3[:p_mn]) - value.(m2[:p_mn])
    p_diff_nh .= value.(m3[:p_nh]) - value.(m2[:p_nh])
    p_diff_vcm .= value.(m3[:p_vcm]) - value.(m2[:p_vcm])

    data = [p_diff_mn p_diff_nh p_diff_vcm]
    plot(data)
end

function flex_provider_stack(m1=m_base, m2=m_case1) #for comparing two cases, m2 is compared to mean values of m1
    p_diff_mn=zeros(length(value.(m2[:p_mn])))
    p_diff_nh=zeros(length(value.(m2[:p_nh])))
    p_diff_vcm=zeros(length(value.(m2[:p_vcm])))
    p_diff_cem=zeros(length(value.(m2[:p_cem])))

    p_diff_mn .= value.(m2[:p_mn]) .- mean(value.(m1[:p_mn]))
    p_diff_nh .= value.(m2[:p_nh]) .- mean(value.(m1[:p_nh]))
    p_diff_vcm .= value.(m2[:p_vcm]) .- mean(value.(m1[:p_vcm]))
    p_diff_cem .= value.(m2[:p_cem]) .- mean(value.(m1[:p_cem]))
    x=1:1:168
    # PlotlyJS.plot(x=1:168, y=data)

    layout = Layout(
        barmode="relative",
        xaxis_title="Hour",
        yaxis_title="Deviation from non-restricted operation [MW]",
        font=attr(
            family="Times New Roman",
            size=16
        ),
        legend=attr(x=0.65, y=0.1),
        width=400, height=400,
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr(zeroline=true, zerolinewidth=1, zerolinecolor="black",
                    showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        yaxis_range=[-70, 10]
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink")
        
    )

    PlotlyJS.plot([
        PlotlyJS.bar(name="Ammonia", x=x, y=p_diff_nh),
        PlotlyJS.bar(name="Ferroalloy", x=x, y=p_diff_mn),
        PlotlyJS.bar(name="VCM", x=x, y=p_diff_vcm),
        PlotlyJS.bar(name="Cement", x=x, y=p_diff_cem)
    ], layout)
end

function flex_provider_stackarea(m1=m_base, m2=m_case1) #for comparing two cases, m2 is compared to mean values of m1
    p_diff_mn=zeros(length(value.(m2[:p_mn])))
    p_diff_nh=zeros(length(value.(m2[:p_nh])))
    p_diff_vcm=zeros(length(value.(m2[:p_vcm])))
    p_diff_cem=zeros(length(value.(m2[:p_cem])))
    p_diff_tot=zeros(length(value.(m2[:p_tot])))


    p_diff_mn .= value.(m2[:p_mn]) .- mean(value.(m1[:p_mn]))
    p_diff_nh .= value.(m2[:p_nh]) .- mean(value.(m1[:p_nh]))
    p_diff_vcm .= value.(m2[:p_vcm]) .- mean(value.(m1[:p_vcm]))
    p_diff_cem .= value.(m2[:p_cem]) .- mean(value.(m1[:p_cem]))
    p_diff_tot .= value.(m2[:p_tot]) .- mean(value.(m1[:p_tot]))
    x=1:1:168
    # PlotlyJS.plot(x=1:168, y=data)

    layout = Layout(
        barmode="relative",
        xaxis_title="Time [h]",
        yaxis_title="Load deviation [MW]",
        font=attr(
            # family="Times New Roman",
            size=18
        ),
        legend=attr(x=1, y=0.1, xanchor="right"),
        width=400, height=400,
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr(zeroline=true, zerolinewidth=1, zerolinecolor="black",
                    showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        yaxis_range=[-70, 10]
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink")
        
    )

    PlotlyJS.plot([
        PlotlyJS.scatter(name="Ammonia", x=x, y=p_diff_nh, stackgroup="one", mode="none", legendrank=4),
        PlotlyJS.scatter(name="Cement", x=x, y=p_diff_cem, stackgroup="one", mode="none", legendrank=3),
        PlotlyJS.scatter(name="Ferroalloy", x=x, y=p_diff_mn, stackgroup="one", mode="none", legendrank=2),
        PlotlyJS.scatter(name="VCM", x=x, y=p_diff_vcm, stackgroup="one", mode="none", legendrank=1),
        PlotlyJS.scatter(name="Total", x=x, y=p_diff_tot, marker_color=:black)
    ], layout)
end

function load_multiple(m1=m_base, m2=m_short, m3=m_long) #
    p_1=zeros(length(value.(m1[:p_tot])))
    p_2=zeros(length(value.(m2[:p_tot])))
    p_3=zeros(length(value.(m3[:p_tot])))

    p_1 = value.(m1[:p_tot])
    p_2 = value.(m2[:p_tot])
    p_3 = value.(m3[:p_tot])

    x=1:1:length(value.(m1[:p_tot]))
    # PlotlyJS.plot(x=1:168, y=data)

    layout = Layout(
        xaxis_title="Time [h]",
        yaxis_title="Electricity demand [MW]",
        font=attr(
            # family="Times New Roman",
            size=18
        ),
        legend=attr(x=1, y=0.1, xanchor="right"),
        width=800, height=400,
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr(zeroline=true, zerolinewidth=1, zerolinecolor="black",
                    showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        # yaxis_range=[-70, 10]
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink")
        
    )

    PlotlyJS.plot([
        PlotlyJS.scatter(name="Uncongested operation", x=x, y=p_1),
        PlotlyJS.scatter(name="Short, large congestion", x=x, y=p_2),
        PlotlyJS.scatter(name="Long, small congestion", x=x, y=p_3)
    ], layout)
end

function flex_provider_stack_detail(m1=m_base, m2=m_case1, m3=m_case2)
    p_diff_mn_femn=zeros(length(value.(m3[:p_mn_femn])))
    p_diff_mn_simn=zeros(length(value.(m3[:p_mn_simn])))

    p_diff_nh_pem=zeros(length(value.(m3[:p_nh_pem])))
    p_diff_nh_hno=zeros(length(value.(m3[:p_nh_hno])))

    p_diff_vcm_cae=zeros(length(value.(m3[:p_vcm_cae])))
    p_diff_vcm_pem=zeros(length(value.(m3[:p_vcm_pem])))


    p_diff_mn_femn .= value.(m3[:p_mn_femn]) - value.(m2[:p_mn_femn])
    p_diff_mn_simn .= value.(m3[:p_mn_simn]) - value.(m2[:p_mn_simn])

    p_diff_nh_pem .= value.(m3[:p_nh_pem]) - value.(m2[:p_nh_pem])
    p_diff_nh_hno .= value.(m3[:p_nh_hno]) - value.(m2[:p_nh_hno])

    p_diff_vcm_cae .= value.(m3[:p_vcm_cae]) - value.(m2[:p_vcm_cae])
    p_diff_vcm_pem .= value.(m3[:p_vcm_pem]) - value.(m2[:p_vcm_pem])
    x=1:1:168
    # data = [p_diff_mn p_diff_nh p_diff_vcm]
    # PlotlyJS.plot(x=1:168, y=data)

    layout = Layout(
        barmode="relative",
        xaxis_title="Hour",
        yaxis_title="Deviation from non-restricted operation [MW]",
        font=attr(
            family="Times New Roman",
            size=16
        ),
        legend=attr(x=0.78, y=0.1),
        width=800, height=400,
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr(zeroline=true, zerolinewidth=1, zerolinecolor="black",
                    showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink")
        
    )

    PlotlyJS.plot([
        PlotlyJS.bar(name="VCM, PEM", x=x, y=p_diff_vcm_pem, marker_color=:blue),
        PlotlyJS.bar(name="Ammonia, PEM", x=x, y=p_diff_nh_pem, marker_color=:skyblue),
        PlotlyJS.bar(name="VCM, CAE", x=x, y=p_diff_vcm_cae, marker_color=:red),
        PlotlyJS.bar(name="Ammonia, HNO", x=x, y=p_diff_nh_hno, marker_color=:pink),
        PlotlyJS.bar(name="Ferroalloy, FeMn", x=x, y=p_diff_mn_femn, marker_color=:green),
        PlotlyJS.bar(name="Ferroalloy, SiMn", x=x, y=p_diff_mn_simn, marker_color=:lightgreen)
    ], layout)
end

function cem_operation(m) #operation of machines in cement factory
    p = Plots.plot()
    for c in sort!(collect(keys(input["cement"]["machinery"])))
        Plots.plot!(Array(value.(m[:p_cem_mach][c,:])), label=c)
    end
    # plot!(value.(m[:p_cem_kiln]), label="kiln")
    # plot!(value.(m[:p_cem_ccs]), label="ccs")
    return p
end

function cem_stor_operation(m) #operation of storages in cement factory
    p = Plots.plot()
    for c in sort!(collect(keys(input["cement"]["storages"])))
        Plots.plot!(Array(value.(m[:s_cem_stor][c,:]))/input["cement"]["storages"][c]["capacity"], label=c)
    end
    # plot!(value.(m[:p_cem_kiln]), label="kiln")
    return p
end


function cluster_operation(m1, m2, m3)
    p1=Plots.plot()
    p2=Plots.plot()
    m = [m1 m2 m3]
    name=["Base case" "Planned upgrades" "Future case"]

    for i=1:3
        plot!(p1, value.(m[i][:p_tot]), label=name[i])
        plot!(p2, value.(m[i][:p_tot]) .+ p_other, label=name[i])
    end

    hline!(p2, [2200.0], label="Grid limit")

    Plots.plot!(p1, xlabel = "Hour", ylabel = "Electricity demand [MW]", 
        legend=:outerright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        # ylims=(500,200),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(10),
        ytickfont=font(10),
        guidefont=font(10),
        legendfont=font(10)
    )

    Plots.plot!(p2, xlabel = "Hour", ylabel = "Grid demand [MW]", 
        legend=:outerright,
        # gridcolor = :lightgrey,
        # gridalpha=0.5,
        ylims=(500,2600),
        size=(800,400),
        dpi=1000,
        left_margin = 5Plots.mm,
        # right_margin = 15Plots.mm,
        bottom_margin=5Plots.mm,
        xtickfont=font(10),
        ytickfont=font(10),
        guidefont=font(10),
        legendfont=font(10)
    )


    (p1,p2)
    
end

function cluster_operation_stack(m)
    p1 = PlotlyJS.plot()
    T=length(value.(m[:p_tot]))
    nh=value.(m[:p_nh])
    cem=value.(m[:p_cem])
    vcm=value.(m[:p_vcm])
    mn=value.(m[:p_mn])

    layout = Layout(
        xaxis_title="Hour",
        yaxis_title="Power demand [MW]",
        font=attr(
            family="Times New Roman",
            size=16
        ),
        legend=attr(x=0.65, y=0.0),
        width=400, height=400, 
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr( showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # xaxis_range=[1.5, 4.5], 
        # yaxis_range=[0, 850]
        
    )


    PlotlyJS.plot([
        PlotlyJS.scatter(x=1:T, y=cem, fill="tozeroy", mode="none", name="Cement", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=mn, fill="tonexty", mode="none", name="Ferroalloy", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=vcm, fill="tonexty", mode="none", name="VCM", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=nh, fill="tonexty", mode="none", name="Ammonia", stackgroup="one", ),
    ], layout)
end

function cluster_operation_stack(m, other)
    p1 = PlotlyJS.plot()
    T=raw_input["T"]
    nh=value.(m[:p_nh])
    cem=value.(m[:p_cem])
    vcm=value.(m[:p_vcm])
    mn=value.(m[:p_mn])

    layout = Layout(
        xaxis_title="Hour",
        yaxis_title="Transmission demand [MW]",
        font=attr(
            family="Times New Roman",
            size=16
        ),
        legend=attr(x=0.8, y=1.0),
        width=800, height=400,
        margin=attr(l=20,r=20,t=40,b=20),
        plot_bgcolor="white",
        # yaxis=attr(showline=true, linewidth=1, linecolor="black"),
        yaxis=attr( showline=true, linewidth=1, linecolor="black",
                    showgrid=true, gridwidth=0.5, gridcolor="lightgrey"),
        # xaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # yaxis=attr(zeroline=true, zerolinewidth=2, zerolinecolor="LightPink"),
        # xaxis_range=[1.5, 4.5], 
        yaxis_range=[500, 2500]        
    )

    PlotlyJS.plot([
        PlotlyJS.scatter(x=1:T, y=other, fill="tozeroy", mode="none", name="Other demand", stackgroup="one", fillcolor="skyblue"),
        PlotlyJS.scatter(x=1:T, y=cem, fill="tonexty", mode="none", name="Cement", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=mn, fill="tonexty", mode="none", name="Ferroalloy", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=vcm, fill="tonexty", mode="none", name="VCM", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=nh, fill="tonexty", mode="none", name="Ammonia", stackgroup="one", ),
        PlotlyJS.scatter(x=1:T, y=repeat([2200], outer=T), mode="line", name="Limit", line=attr(color="red")),
    ], layout)
end

function cap_sens(df)
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes

    ### Lister som kan brukes til for løkker. Brukes ikke pga manuelt sagt verdier for edc og h2 lagring i for løkker
    dur_list = unique(df[:,:"dur"])
    cap_list = unique(df[:,:"cap"])
    act_list = unique(df[:,:"act"])
    # pem_list = unique(df[:,:"PEM"])




    
    color = [:red, :blue, :green]
    line = [:solid, :dash, :dot]
    plots = ["Total cost", "c_en_tot", "c_ll_tot", "c_lc_tot", "c_ll_mn", "c_ll_cem", "c_lc_vcm", "c_lc_cem"]
    x_axis = "red"
    y = Plots.plot()  

    for p in plots
        pl=Plots.plot()
        for dur in dur_list
        

            x = df[( df."dur" .== dur ) .& (df."c_gd_tot" .== 0), x_axis][:]
            y = df[( df."dur" .== dur ) .& (df."c_gd_tot" .== 0), p][:]
            
            Plots.plot!(pl,x,y, label = "$dur", xlabel=x_axis, ylabel=p)
            
        end
        display(pl)
    end

    pl=Plots.plot()

    for dur in dur_list
    

        x = df[( df."dur" .== dur ) , x_axis][:]
        y = df[( df."dur" .== dur ) , "c_gd_tot"][:]
        
        Plots.plot!(pl,x,y, label = "$dur", xlabel=x_axis, ylabel="c_gd_tot")
        
    end
    display(pl)



    # x = df[( df."H2 storage" .== 0 ) .& (df."SOEC" .== 0), :"PEM"]
    # y = df[( df."H2 storage" .== 0 ) .& (df."SOEC" .== 0), :"Total cost"]/1e6
    # plot!(x,y, label = "PEM", color = :green)


    #     y1=Plots.plot!(xlabel = "Grid capacity", ylabel = "Total cost", 
    #         # legend=:bottomright,
    #         # gridcolor = :lightgrey,
    #         # gridalpha=0.5,
    #         size=(800,300),
    #         dpi=1000,
    #         left_margin = 5Plots.mm,
    #         # right_margin = 15Plots.mm,
    #         bottom_margin=5Plots.mm,
    #         xtickfont=font(10),
    #         ytickfont=font(10),
    #         guidefont=font(10),
    #         legendfont=font(10)
    #     )
    #    return y1

end

function cost_contour(filename::String) #Total cost contour plot
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    
    x_label = sort(unique(df[:,"dur"]))
    y_label = sort(unique(df[:,"red"]))

    k=length(x_label)
    l=length(y_label)

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df."Total cost"[1] .- df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,     
    contours_start=1e4,
    contours_end=1.1e6,
    # contours_size=0.1,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title="Cost deviation", # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour(filename::String, col::String) #filename::String, contourbool::Bool=false
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    x_label = sort(unique(df[:,"dur"]))
    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))

    k=length(x_label)
    l=length(y_label)

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), col][1]
            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,     
    # contours_start=1e4,
    # contours_end=2e4,
    # contours_size=0.1,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title=col, # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour(filename::String, col::String, contour_start::Float64, contour_end::Float64) #filename::String, contourbool::Bool=false
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    x_label = sort(unique(df[:,"dur"]))
    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))

    k=length(x_label)
    l=length(y_label)

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), col][1]
            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,     
    contours_start=contour_start,
    contours_end=contour_end,
    # contours_size=0.1,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title=col, # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour(filename::String, col::String, contour_start::Float64, contour_end::Float64, contour_size::Float64) #filename::String, contourbool::Bool=false
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"dur"]))

    k=length(x_label)
    l=length(y_label)

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), col][1]
            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,     
    contours_start=contour_start,
    contours_end=contour_end,
    contours_size=contour_size,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title=col, # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour_nogd(filename::String, contour_start, contour_end, contour_size) #total cost contour in the cases of no grid deficit
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"dur"]))

    k=Int64(round(length(x_label)))
    l=Int64(round(length(y_label)))

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df."Total cost"[1]

            if df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                cost_tot = 1e8 
            else
                cost_tot = cost_tot - df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
            end

            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot/1e3, digits=3)
        end
    end

    x = x_label
    y = y_label

    # colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,
    # contours=attr(
    #     showlabels = true
    #  ),     
    contours_start=contour_start,
    contours_end=contour_end,
    contours_size=contour_size,
    colorscale="Earth",
    line_smoothing=0,
    colorbar=attr(
        # title="Unit cost of flexibility [EUR/MWh]", # title here
        titleside="right",
        titlefontsize=30,
        thickness=25
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Load reduction [MW]",
        # title=,
        title=attr(text="Total cost [k€]",xanchor="center", x=0.5),
        font=attr(size=18)
    )

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour_cap_T_nogd(filename::String) #total cost contour in the cases of no grid deficit
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"T"]))

    k=Int64(round(length(x_label)))
    l=Int64(round(length(y_label)))

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."T" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df[(df."T" .== x_label[i]), "Total cost"][1]

            if df[(df."T" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                cost_tot = 1e8 
            else
                cost_tot = cost_tot - df[(df."T" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
            end

            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,
    contours=attr(
        showlabels = true
     ), # show labels on contours     
    contours_start=0,
    contours_end=2e5,
    contours_size=5e3,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title="Cost deviation from base case, duration=6hr", # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Total period (T) [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function cost_contour_cap_act_nogd(filename::String) #total cost contour in the cases of no grid deficit for capacity vs activation time
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"act"]))

    k=Int64(round(length(x_label)))
    l=Int64(round(length(y_label)))

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."act" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df."Total cost"[1]

            if df[(df."act" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                cost_tot = 1e8 
            else
                cost_tot = cost_tot - df[(df."act" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
            end

            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(cost_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,
    contours=attr(
        showlabels = true
     ), # show labels on contours     
    contours_start=0,
    contours_end=3.5e4,
    # contours_size=5e3,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title="Cost deviation from base case, duration=6hr", # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Activation time [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function em_contour(filename::String) #Emission deviation contour
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    
    x_label = sort(unique(df[:,"dur"]))
    y_label = sort(unique(df[:,"red"]))

    k=length(x_label)
    l=length(y_label)

    z=zeros(l,k)
    df."em" = df."c_em_tot"./df."em_price"

    for i = 1:k
        for j = 1:l
            em_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "em"][1] - df."em"[1]
            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            if df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                em_tot = 1e8 
            end
            z[j,i] = round(em_tot, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,     
    contours_start=0,
    contours_end=3.53e2,
    # contours_size=0.1,
    colorscale=colorscale,
    line_smoothing=0,
    colorbar=attr(
        title="Emission deviation", # title here
        titleside="right",
        titlefontsize=30
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Capacity reduction [MW]",
        font=attr(size=18))

    p1 = PlotlyJS.plot(y1, layout)

    return p1
end

function unit_cost_flex(filename::String, contour_start, contour_end, contour_size) #cost per mwh (EUR/MWh) for flexibility
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"dur"]))

    k=Int64(round(length(x_label)))
    l=Int64(round(length(y_label)))

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df."Total cost"[1]

            if df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                unit_cost = 1e8 
            else
                cost_tot = cost_tot - df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
                if x_label[i]*y_label[j]==0
                    unit_cost=0
                else
                    unit_cost = cost_tot/(x_label[i]*y_label[j])
                end
            end



            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(unit_cost, digits=3)
        end
    end

    x = x_label
    y = y_label

    colorscale = [[0, "lime"], [1, "red"]]


    y1 = PlotlyJS.contour(; x,y,z,
    # contours=attr(
    #     showlabels = true
    #  ),     
    contours_start=contour_start,
    contours_end=contour_end,
    contours_size=contour_size,
    colorscale="Earth",
    line_smoothing=0,
    colorbar=attr(
        # title="Unit cost of flexibility [EUR/MWh]", # title here
        titleside="right",
        titlefontsize=30,
        thickness=25
    ))
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Load reduction [MW]",
        # title=,
        title=attr(text="Unit cost [€/MWh]",xanchor="center", x=0.5),
        font=attr(size=18)
    )

    p1 = PlotlyJS.plot(y1, layout)

    return p1 
end

function unit_cost_flex_log(filename::String, contour_start, contour_end, contour_size) #cost per mwh (EUR/MWh) for flexibility
    ###Important: the for loops must be manually edited to fit the results file. (h2 sizes, edc sizes), as well as colors and linestyles to fit the number of h2 sizes and edc sizes
    df = DataFrame(XLSX.readtable(filename, "MAIN_RESULTS"))

    # y1 = plot(
    #         xlabel = "PEM capacity", 
    #         ylabel = "Flexibility factor",
    #         ylims = [0.99, 1.15],
    #         title = "Sensitivity of FF with NG"
    #         )

    # @. df."c_g_avg" = round(df."c_g_avg"; digits=2)
    y_label = sort(unique(df[:,"red"]))
    x_label = sort(unique(df[:,"dur"]))

    k=Int64(round(length(x_label)))
    l=Int64(round(length(y_label)))

    z=zeros(l,k)

    for i = 1:k
        for j = 1:l
            cost_tot = df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "Total cost"][1] - df."Total cost"[1]

            if df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1] >= 10000.0 #If there is a grid deficit higher than the MIPGap, set the total cost very high for visualization
                unit_cost = 1e8 
            else
                cost_tot = cost_tot - df[(df."dur" .== x_label[i]) .& (df."red" .== y_label[j]), "c_gd_tot"][1]
                if x_label[i]*y_label[j]==0
                    unit_cost=1
                else
                    unit_cost = cost_tot/(x_label[i]*y_label[j])
                    if unit_cost≤1
                        unit_cost=1
                    end
                end
            end



            # h2_blue = df[(df."red" .== x_label[i]).& (df."dur" .== y_label[j]), :"H2_blue"][1]
            z[j,i] = round(log10(unit_cost), digits=3)
        end
    end

    x = x_label
    y = y_label


    tv=Array([contour_start:contour_size:contour_end])
    tl=Array([L"10^{%$i}" for i in tv])

    y1 = PlotlyJS.contour(; x,y,z,
    # contours=attr(
    #     showlabels = true
    #  ),     
    contours_start=contour_start,
    contours_end=contour_end,
    contours_size=contour_size,
    colorscale="Earth",
    line_smoothing=0,
    colorbar=attr(
        title="Unit cost of flexibility [€/MWh]", # title here
        titleside="right",
        titlefontsize=18,
        thickness=20,
        tickmode="array",
        tickvals=[0,1,2,3,4],
        ticktext=["10⁰", "10¹", "10²", "10³", "10⁴"],
        x=1.05
    )
    )
    layout = Layout(
        xaxis_title="Reduction duration [hr]",
        yaxis_title="Load reduction [MW]",
        # title=,
        # title=attr(text="Unit cost [EUR/MWh]",xanchor="center", x=0.5),
        font=attr(size=18)
    )

    p1 = PlotlyJS.plot(y1, layout)

    return y1 
end

function grid_plot(p1,p2,p3,lim)
    T=length(p1)
    trace1 = PlotlyJS.scatter(x=1:T, y=p1, mode="lines", name="Base case")
    trace2 = PlotlyJS.scatter(x=1:T, y=p2, mode="lines", name="Decarbonized, static")
    trace3 = PlotlyJS.scatter(x=1:T, y=p3, mode="lines", name="Decarbonized, flexible")
    trace4 = PlotlyJS.scatter(x=[1,T], y=[lim,lim], mode="lines", name="Grid limit", line=attr(dash="dash", color="red"))

    layout = Layout(
        xaxis_title="Time [h]",
        yaxis_title="Load [MW]",
        yaxis_range=[0, 3000],
        font=attr(size=18),
        plot_bgcolor="white",
        legend=attr(x=0.5, y=1,xanchor="center",yanchor="bottom", orientation="h"),
    )

    
    PlotlyJS.plot([trace1, trace2, trace3, trace4], layout)
end

function grid_plot_base(p1,p2,lim)
    T=length(p1)
    trace1 = PlotlyJS.scatter(x=1:T, y=p1, mode="none", name="General load", fill="tozeroy", stackgroup="one")
    trace2 = PlotlyJS.scatter(x=1:T, y=p2, mode="none", name="Industry load", fill="tonexty", stackgroup="one")
    trace3 = PlotlyJS.scatter(x=1:T, y=p2+p1, mode="line", name="Total grid load", line=attr(color="black"))
    trace4 = PlotlyJS.scatter(x=[1,T], y=[lim,lim], mode="lines", name="Grid limit", line=attr(dash="dash", color="red"))

    layout = Layout(
        xaxis_title="Time [h]",
        yaxis_title="Load [MW]",
        yaxis_range=[0, 2500],
        font=attr(size=18),
        width=800, height=300,
        plot_bgcolor="white",
        colorscale="",
        legend=attr(x=0.5, y=1,xanchor="center", yanchor="bottom", orientation="h"),
    )

    
    PlotlyJS.plot([trace1, trace2, trace3, trace4], layout)
end

function grid_dev_plot(m1, m2)
    T=length(value.(m1[:p_tot]))

    trace1=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_nh])-value.(m1[:p_nh])), mode="lines", name="Ammonia")
    trace2=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_cem])-value.(m1[:p_cem])), mode="lines", name="Cement")
    trace3=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_mn])-value.(m1[:p_mn])), mode="lines", name="Ferroalloy")
    trace4=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_vcm])-value.(m1[:p_vcm])), mode="lines", name="VCM")
    
    layout = Layout(
        xaxis_title="Time [h]",
        yaxis_title="Load deviation [MW]",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        plot_bgcolor="white",
        legend=attr(x=1, y=0,xanchor="right",),
    )

    
    PlotlyJS.plot([trace1, trace2, trace3, trace4], layout)

end
function grid_dev_plot(m1, m2, p_grid_def)
    T=length(value.(m1[:p_tot]))

    trace1=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_nh])-value.(m1[:p_nh])), mode="none", name="Ammonia", fill="tozeroy",stackgroup="one")
    trace2=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_cem])-value.(m1[:p_cem])), mode="none", name="Cement", fill="tonexty",stackgroup="one")
    trace3=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_mn])-value.(m1[:p_mn])), mode="none", name="Ferroalloy", fill="tonexty",stackgroup="one")
    trace4=PlotlyJS.scatter(x=1:T, y=(value.(m2[:p_vcm])-value.(m1[:p_vcm])), mode="none", name="VCM", fill="tonexty",stackgroup="one")
    trace5=PlotlyJS.scatter(x=1:T, y=p_grid_def, mode="lines", name="Demand", line=attr(color="black", dash="dash"))
    
    layout = Layout(
        xaxis_title="Time [h]",
        yaxis_title="Load deviation [MW]",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        plot_bgcolor="white",
        height=300,
        width=800,
        legend=attr(x=0.5, y=1,xanchor="center",yanchor="bottom", orientation="h"),
    )

    
    PlotlyJS.plot([trace1, trace2, trace3, trace4, trace5], layout)

end

function p_add_plot(week5nolim, week5lim, week50nolim, week50lim)
    df1 = DataFrame(XLSX.readtable(week5nolim, "MAIN_RESULTS"))
    df2 = DataFrame(XLSX.readtable(week5lim, "MAIN_RESULTS"))
    df3 = DataFrame(XLSX.readtable(week50nolim, "MAIN_RESULTS"))
    df4 = DataFrame(XLSX.readtable(week50lim, "MAIN_RESULTS"))

    trace1 =  PlotlyJS.scatter(x=df1."p_add", y=df1."hours_over_lim", line=attr(color="royalblue", dash="dash"), name="Week 5, flex")
    trace2 =  PlotlyJS.scatter(x=df2."p_add", y=df2."hours_over_lim", line = attr(color="royalblue"), name="Week 5, static")
    trace3 =  PlotlyJS.scatter(x=df3."p_add", y=df3."hours_over_lim", line=attr(color="firebrick", dash="dash"), name="Week 50, flex")
    trace4 =  PlotlyJS.scatter(x=df4."p_add", y=df4."hours_over_lim", line=attr(color="firebrick"), name="Week 50, static")

    layout = Layout(
        xaxis_title="Added static demand [MW]",
        yaxis_title="Hours of grid overload [hr]",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        plot_bgcolor="white",
        legend=attr(x=0, y=1.1,xanchor="left",yanchor="top"),
    )

    
    PlotlyJS.plot([trace1, trace2, trace3, trace4], layout)

end

function p_add_cost_plot(week5lim, week50lim)
    df1 = DataFrame(XLSX.readtable(week5lim, "MAIN_RESULTS"))
    df2 = DataFrame(XLSX.readtable(week50lim, "MAIN_RESULTS"))

    flex1 = df1."Total cost" - df1."c_gd_tot" .-df1."Total cost"[1]
    flex2 = df2."Total cost" - df2."c_gd_tot" .-df2."Total cost"[1]

    x=range(10,stop=80,length=8)

    trace1 =  PlotlyJS.scatter(x=x, y=flex1[4:11], line=attr(color="royalblue", dash="dash"), name="Week 5, flex")
    trace2 =  PlotlyJS.scatter(x=x, y=flex2[21:28], line = attr(color="firebrick", dash="dash"), name="Week 50, flex")

    layout = Layout(
        xaxis_title="Grid capacity increase [MW]",
        yaxis_title="Total flexibility cost [€]",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        plot_bgcolor="white",
        legend=attr(x=0, y=1,xanchor="left",yanchor="top"),
        # margin=attr(l=20,r=40,t=20,b=20),
    )

    
    PlotlyJS.plot([trace1, trace2], layout)
end

function actor_flex(result_5, result_50)
    df5 = DataFrame(XLSX.readtable(result_5, "MAIN_RESULTS"))
    df50 = DataFrame(XLSX.readtable(result_50, "MAIN_RESULTS"))

    x = ["Ammonia", "Cement", "Ferroalloy", "VCM"]

    y5_1 = [df5."flex_nh_tot"[3], df5."flex_cem_tot"[3], df5."flex_mn_tot"[3], df5."flex_vcm_tot"[3]]
    y50_1 = [df50."flex_nh_tot"[3], df50."flex_cem_tot"[3], df50."flex_mn_tot"[3], df50."flex_vcm_tot"[3]]

    layout_1 = Layout(
        # xaxis_title="Increase in grid capacity [MW]",
        yaxis_title="Flexibility provided [MWh]",
        yaxis_type="log",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=400, height=400,
        plot_bgcolor="white",
        margin=attr(l=20,r=20,t=20,b=20),
        legend=attr(x=1, y=1,xanchor="right",yanchor="top"),
        barmode="group",
        yaxis=attr(showline=true, linewidth=2, linecolor="black", 
                ticks="inside", tickwidth=1, tickcolor="black",tickmode="auto",nticks=8,
                showgrid="true", gridwidth=1, gridcolor="lightgrey"),
        xaxis=attr(showline=true, linewidth=2, linecolor="black")
    )

    p1= PlotlyJS.plot([
        PlotlyJS.bar(name="Week 5", x=x, y=y5_1,marker_color="LightSkyBlue"),
        PlotlyJS.bar(name="Week 50", x=x, y=y50_1,marker_color="tomato")
    ], layout_1)

    y5_2 = [df5."el_tot_nh"[2]-df5."el_tot_nh"[3], df5."el_tot_cem"[2]-df5."el_tot_cem"[3], df5."el_tot_mn"[2]-df5."el_tot_mn"[3], df5."el_tot_vcm"[2]-df5."el_tot_vcm"[3]]
    y50_2 = [df50."el_tot_nh"[2]-df50."el_tot_nh"[3], df50."el_tot_cem"[2]-df50."el_tot_cem"[3], df50."el_tot_mn"[2]-df50."el_tot_mn"[3], df50."el_tot_vcm"[2]-df50."el_tot_vcm"[3]]

    layout_2 = Layout(
        # xaxis_title="Increase in grid capacity [MW]",
        yaxis_title="Reduction in electricity use [MWh]",
        yaxis_type="log",
        # yaxis_position = 1,
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=400, height=400,
        margin=attr(l=20,r=20,t=20,b=20),
        plot_bgcolor="white",
        legend=attr(x=1, y=1,xanchor="right",yanchor="top"),
        barmode="group",
        yaxis=attr(showline=true, linewidth=2, linecolor="black", 
            ticks="inside", tickwidth=1, tickcolor="black",
            showgrid="true", gridwidth=1, gridcolor="lightgrey"),
        xaxis=attr(showline=true, linewidth=2, linecolor="black")
    )

    p2= PlotlyJS.plot([
        PlotlyJS.bar(name="Week 5", x=x, y=y5_2,marker_color="LightSkyBlue"),
        PlotlyJS.bar(name="Week 50", x=x, y=y50_2,marker_color="tomato")
    ], layout_2)


    flex_cost_nh_5 = df5."c_en_nh"[3]-df5."c_en_nh"[2] + df5."c_em_nh"[3]-df5."c_em_nh"[2] + df5."c_ll_nh"[3]-df5."c_ll_nh"[2] 
    flex_cost_cem_5 = df5."c_en_cem"[3]-df5."c_en_cem"[2] +  df5."c_ll_cem"[3] - df5."c_ll_cem"[2] + df5."c_lc_cem"[3] - df5."c_lc_cem"[2]
    flex_cost_mn_5 = df5."c_en_mn"[3]-df5."c_en_mn"[2] +  df5."c_ll_mn"[3] - df5."c_ll_mn"[2] 
    flex_cost_vcm_5 = df5."c_en_vcm"[3]-df5."c_en_vcm"[2] +  df5."c_em_vcm"[3] - df5."c_em_vcm"[2] + df5."c_lc_vcm"[3] - df5."c_lc_vcm"[2]

    flex_cost_nh_50 = df50."c_en_nh"[3]-df50."c_en_nh"[2] + df50."c_em_nh"[3]-df50."c_em_nh"[2] + df50."c_ll_nh"[3]-df50."c_ll_nh"[2] 
    flex_cost_cem_50 = df50."c_en_cem"[3]-df50."c_en_cem"[2] +  df50."c_ll_cem"[3] - df50."c_ll_cem"[2] + df50."c_lc_cem"[3] - df50."c_lc_cem"[2]
    flex_cost_mn_50 = df50."c_en_mn"[3]-df50."c_en_mn"[2] +  df50."c_ll_mn"[3] - df50."c_ll_mn"[2] 
    flex_cost_vcm_50 = df50."c_en_vcm"[3]-df50."c_en_vcm"[2] +  df50."c_em_vcm"[3] - df50."c_em_vcm"[2] + df50."c_lc_vcm"[3] - df50."c_lc_vcm"[2]


    y5_3 = [flex_cost_nh_5, flex_cost_cem_5, flex_cost_mn_5, flex_cost_vcm_5]
    y50_3 = [flex_cost_nh_50, flex_cost_cem_50, flex_cost_mn_50, flex_cost_vcm_50]
    

    layout_3 = Layout(
        # xaxis_title="Increase in grid capacity [MW]",
        yaxis_title="Total cost of flexibility [€]",
        yaxis_type="log",
        # yaxis_position = 1,
        # yaxis_title_standoff=-100,
        # yaxis_range=[0,"null"],
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=400, height=400,
        margin=attr(l=20,r=20,t=20,b=20),
        plot_bgcolor="white",
        legend=attr(x=1, y=1,xanchor="right",yanchor="top"),
        barmode="group",
        yaxis=attr(showline=true, linewidth=2, linecolor="black", 
                ticks="inside", tickwidth=1, tickcolor="black",tickmode="auto",nticks=8,
                showgrid="true", gridwidth=1, gridcolor="lightgrey"),
        xaxis=attr(showline=true, linewidth=2, linecolor="black")
        # yaxis_tickvals=[2e4, 4e4, 6e4, 8e4, 1e4, 2e5, 4e5, 6e5, 8e5, 1e6]
    )

    p3= PlotlyJS.plot([
        PlotlyJS.bar(name="Week 5", x=x, y=y5_3,marker_color="LightSkyBlue"),
        PlotlyJS.bar(name="Week 50", x=x, y=y50_3,marker_color="tomato")
    ], layout_3)

    y5_4 = y5_3./y5_1
    y50_4 = y50_3./y50_1
    

    layout_4 = Layout(
        # xaxis_title="Increase in grid capacity [MW]",
        yaxis_title="Unit cost of flexibility [€/MWh]",
        # yaxis_position = 1,
        # yaxis_type="log",
        yaxis_range=[0,360],
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=400, height=400,
        margin=attr(l=20,r=20,t=20,b=20),
        plot_bgcolor="white",
        legend=attr(x=1, y=1,xanchor="right",yanchor="top"),
        barmode="group",
        yaxis=attr(showline=true, linewidth=2, linecolor="black", 
            ticks="inside", tickwidth=1, tickcolor="black",
            showgrid="true", gridwidth=1, gridcolor="lightgrey"),
        xaxis=attr(showline=true, linewidth=2, linecolor="black")
    )

    p4= PlotlyJS.plot([
        PlotlyJS.bar(name="Week 5", x=x, y=y5_4,marker_color="LightSkyBlue"),
        PlotlyJS.bar(name="Week 50", x=x, y=y50_4,marker_color="tomato")
    ], layout_4)

    (p1, p2, p3, p4)

    #Consider making subplots. In that case: maybe remove yaxis_title, replace with title, specify bar colors, and remove legends for all plots except 1.
    # [p1 p2;p4 p3]
end

function industries()
	x = [
		["Base case", "Base case", "Base case", "Base case", "Decarbonized", "Decarbonized", "Decarbonized", "Decarbonized"],
    	["Ammonia", "Cement", "Ferroalloy", "VCM", "Ammonia", "Cement", "Ferroalloy" , "VCM"] ]
	
	fix = [67.4, 6.0, 42, 74.1, 393.8, 22, 46.2, 74.1]   # to let direct labels
	max = [77.3, 24.2, 70, 98.8, 631.4, 40.2, 77, 145.7]   # to let direct labels
	flex = max-fix   # to let direct labels

    layout = Layout(
        barmode="stack",
        # xaxis_title="Increase in grid capacity [MW]",
        yaxis_title="Power demand [MW]",
        # yaxis_position = 1,
        # yaxis_type="log",
        # yaxis_range=[0,"null"],
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=800, height=800,
        margin=attr(l=20,r=10,t=10,b=20),
        plot_bgcolor="white",
        legend=attr(x=1, y=1,xanchor="right",yanchor="top")
        # barmode="group"
    )
	
	PlotlyJS.Plot([PlotlyJS.bar(x=x, y=fix, name="Static", marker_color="indianred"),
		  PlotlyJS.bar(x=x, y=flex, name="Flexible", marker_color="lightsalmon")], 
		  layout)
end

function yearly_grid()
    df = dropmissing(CSV.read("input/full_2022_grenland.csv", DataFrame, header=1))
    y = df."2022"
    x = 1:length(y)

    trace1 =  PlotlyJS.scatter(x=x, y=y, line=attr(color="black"), name="Grid load 2022")

    layout = Layout(
        xaxis_title="Time of the year [h]",
        yaxis_title="Grid load [MW]",
        # yaxis_range=[0, 3000],
        font=attr(size=18),
        width=800,
        height=300,
        plot_bgcolor="white",
        margin=attr(l=20,r=10,t=10,b=20),
        legend=attr(x=0, y=1,xanchor="left",yanchor="top"),
    )

    
    p=PlotlyJS.plot(trace1, layout)
    add_vrect!(p,
        722, 889,
        fillcolor="LightSalmon", opacity=0.5,
        layer="above", line_width=0,
    )
    add_vrect!(p,
        8283, 8450,
        fillcolor="LightSalmon", opacity=0.5,
        layer="above", line_width=0,
    )
    p
    
end