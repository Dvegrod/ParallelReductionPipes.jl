# [ParallelReductionPipes.jl] [![Star on GitHub](https://img.shields.io/github/stars/JuliaPerf/ParallelReductionPipes.jl.svg)](https://github.com/JuliaPerf/ParallelReductionPipes.jl/stargazers)
The package `ParallelReductionPipes` provides utilities to perform data reduction and visualisation tasks. This package includes a program that can extract data from a numerical simulation and provide a reducer output following the preferences of the user.

## Dependencies
`ParallelReductionPipes` relies on:
 - [ADIOS2]
 - [MacroTools]
For the configuration of pipelines, and addittionally:
 - [MPI]
 - [ParallelStencil]
For the runtime reducer to be executed. Optionally, this runtime also relies on [CUDA] for GPU reduction.

## Contributors
This project has initially been developed as an internship at the Swiss National Supercomputing Centre by Daniel Sergio Vega Rodriguez, under supervision of Dr. Samuel Omlin and co-supervision of Dr. Jean Favre.

The contributors to this repository have been so far:
- Daniel Sergio Vega Rodriguez ([@Dvegrod](https://github.com/Dvegrod)), Swiss National Supercomputing Centre (CSCS), ETH Zurich | Università della Svizzera italiana (USI)
- Dr. Samuel Omlin ([@omlins](https://github.com/omlins)), Swiss National Supercomputing Centre (CSCS), ETH Zurich
