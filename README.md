# Modelling of demand side flexibility in industry clusters with limited availability of electric power generation

## Introduction
This model is used for modelling multiple industries located in a cluster, relying on electricity for operating their processes. The model includes multiple energy carriers, including electricity, heat, natural gas and hydrogen, but focuses on the processes depending on electricity, and in particular, the ones with flexibility potentials. The objective function minimizes costs, including energy costs, load shifting costs and load shedding costs.  

The use of the model is best illustrated by looking at the file `generic_run.jl`, which describes a simple run of the model.

In general, the model has a top-level in which the overall grid capacity restrictions are defined, and the main cost functions of all actors are included in the objective function. On the sub-level, each industry actor has their own variables and constraints, which limit their operation, and define their costs. 

The main operations of utilizing the model is typically:

### 1: Running the `IndClust.jl` file
### 2: Reading the input data using read_data()
### 3: Creating the model using create_model()
### 4: Defining some grid or power capacity constraint, e.g. using grid_cap_calc()
### 5: Optionally adding other constraints
### 6: Running the model, and retrieving results

## Main files
`IndClust.jl` is the main script, importing all other scripts used by the model. 
After running this file, the modules for reading input, the main model and the different industry modules are ready to use. 

`input.jl` contains functions used for reading input files, such as parameters and grid usage data.

`model.jl` contains the function create_model, which creates the JuMP model, and defines the top-level variables and constraints. This also runs the functions defining the different industries included.

`cem_model.jl`, `nh_model.jl`, `vcm_model.jl` and `mn_model.jl` contain the functions, veriables and constraints defining the different industries included. 

`input/input.yml` contains all the parameters of the model.

`output/output.jl` reads the main results from the JuMP model, and organises them in a dataframe, which can be exported to an excel file, or another format of choice.  


## Cite

If you find `IndClustFlex` useful in your work, we kindly request that you cite the following [publication](https://doi.org/0000/000):

<!-- ```bibtex
@article{hellemo2024energymodelsx,
  title={EnergyModelsX: Flexible Energy Systems Modelling with Multiple Dispatch},
  author={Hellemo, Lars and B{\o}dal, Espen Flo and Holm, Sigmund Eggen and Pinel, Dimitri and Straus, Julian},
  journal={Journal of Open Source Software},
  volume={9},
  number={97},
  pages={6619},
  year={2024}
}
``` -->

For earlier work, see our [paper in Advances in Applied Energy](https://www.sciencedirect.com/science/article/pii/S2666792423000318):


```bibtex
@article{foslie_decarbonizing_2023,
	title = {Decarbonizing integrated chlor-alkali and vinyl chloride monomer production: {Reducing} the cost with industrial flexibility},
	author = {Foslie, Sverre Stefanussen and Straus, Julian and Knudsen, Brage Rugstad and Korpås, Magnus},
	year = {2023},
	journal = {Advances in Applied Energy},
    volume={12},
	pages = {100152},
	doi = {10.1016/j.adapen.2023.100152},
}
```