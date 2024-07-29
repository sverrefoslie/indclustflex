using JuMP
using Gurobi
using YAML
using CoolProp
using CSV
using DataFrames
using XLSX

include("input.jl")
include("model.jl")
include("vcm_model.jl")
include("mn_model.jl")
include("nh_model.jl")
include("cem_model.jl")
include("../output/plots.jl")
include("../output/output.jl")

println("Model loaded")

###

# Run input=read_data() with input yaml file
# Run m=create_model(input) 