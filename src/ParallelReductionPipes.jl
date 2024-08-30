"""
The package `ParallelReductionPipes` provides utilities to perform data reduction and visualisation tasks. This package includes a program that can extract data from a numerical simulation and provide a reducer output following the preferences of the user.
A normal use case would look like this:

                           Extension:
                           Uses MPI &
                           ParallelStencil
┌─────────────┐ ADIOS 2   ┌───────────────┐ Reduced    ┌──────────────┐
│             │ SST/BP5   │               │ Output     │ Other        │
│  Simulation ┼──────────►│Reducer Runtime┼───┬───────►│              │
│             │  Input    │               │   │        │ Listeners    │
└─────────────┘           └───▲─┬─────────┘   │        └──────────────┘
                       Control│ │             │
                       Channel│ │             │
                          ┌───┼─▼─────────┐   │
                          │ Julia         │   │
                          │   Notebook or ◄───┘
                          │   Script      │
                          └───────────────┘

The runtime is implemented as an extension of the core module and requires MPI and ParallelStencil.

`ParallelReductionPipes` implements the Pipe type. Which is used to configure a reduction pipeline. An example of a pipe building script is shown below:
```julia
using ParallelReductionPipes
# Create a pipe
pipe :: Pipe = newPipe("var name", "sstfile", "adios_config.xml", [1000, 1000],
Float64)

# Add one layer
w5x5 = window([5, 5])
pipe = reduction(pipe, w5x5, :average)

# Launch to the reducer runtime using the control channel
build(pipe)
```
As it can be seen pipes are built by layers which collapse a window of points into a single point as output, using a specific reduction operation. Custom reduction operations are supported too.
"""
module ParallelReductionPipes

using ADIOS2
using MacroTools

ALL::Int = -1

slice_mode = :v1

supported_types = Type[
    Float64
]

# Code related to configuring and deploying a reduction pipeline
include("blueprinting/structs.jl")

include("shared.jl")
include("blueprinting/input.jl")
include("blueprinting/kernels.jl")
include("blueprinting/operators.jl")
include("blueprinting/custom.jl")
include("blueprinting/reduction.jl")
include("blueprinting/build.jl")
include("blueprinting/connection.jl")


abstract type AbstractBackend end
struct CUDABackend <: AbstractBackend end
struct CPUBackend <: AbstractBackend end

main(backend :: Type{<: AbstractBackend}) = error("Invalid, or disabled backend, check dependencies ($backend)")

export Pipe,newPipe,buildPipe,reduction,window,@custom_reduction_mini,@custom_reduction,addCustomReduction,getOutputStep,build

end
