# Usage
Have a look at the [Examples](@ref) and see the [API reference](@ref) for details on the usage of `ParallelReductionPipes`.

## Installation
`ParallelReductionPipes` can be installed directly with the [Julia package manager] from the [Julia REPL]:
```julia-repl
julia>]
  pkg> add https://github.com/Dvegrod/ParallelReductionPipes.jl
```
!!! tip "Warning"
    When using ADIOS2, which is a dependency of this package, make sure to be using the installation you actually want, the [Julia package manager] one or a native build. To link ADIOS2.jl to a native build you can export the following environment variable:
    ```shell
        export JULIA_ADIOS2_PATH="YOUR PATH TO ADIOS .so DIRECTORY"
    ```

## Launching the runtime

In order to execute the runtime reducer in any computer, the following steps can be followed:
1. Create a julia project.
2. Add [MPI] and [ParallelStencil] to the project. Additionally, [CUDA] can also be added.
3. Set the environment variable "JULIA_PROJECT" to this project (or specify it to julia in the next step).
4. Execute the reducer by either:
   * Calling the main routine of the reducer like in the following script.
     ```julia
        using ParallelReductionPipes

        main(CPUBackend, connection_location)
     ```
   * Executing the launch script.
     ```shell
        julia \[path to ParallelReductionPipes\]src/runtime.jl CPU connection_location
     ```
   These will launch a runtime that will be listening in "connection_location" which is a path where the ADIOS communication files will be placed.
