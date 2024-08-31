# Basic example

In this example we will show how to use `ParallelReductionPipes` to process and reduce data obtained from a mandelbrot set calculator. The data generator will zoom in into the mandelbrot set on each output iteration.

The objective would be the reduction of a plane (1000x1000) into another plane (100x100). Where the input is the provided by the data generator.

For this example we assume every script is executed on the same directory, and that the ADIOS configuration file is also in that directory.


The generator is shown below:

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT, "mandel", "multistep_generator.jl"))
```

The generator has to receive two arguments, the resolution of the square region and the number of times the mandelbrot expression is applied to a point. e.g 1000 500 can be used as a trial.

Once the generator is online, we can also launch the reduction runtime, using the following script. This is an MPI program therefore it should be launched with srun, mpiexec or any other tool of such nature appropiate for your installation.

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT, "mandel","launch_runtime.jl"))
```

!!! Tip "Note"
    It does not matter which program is executed first, the generator, the reducer or even the pipe builder.

Now we specify our reduction pipe, it will consist on:
 - An average reduction layer with a window of 10x10
 - A custom layer that multiplies the input by 100, this has a window of 1x1 since there is no reduction

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT,"mandel", "pipe_gen.jl"))
```

Once the reducer runtime has received the pipe configuration it will begin the reduction. We can check out the steps of the output with the following script:
```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT,"mandel", "get_output.jl"))
```
