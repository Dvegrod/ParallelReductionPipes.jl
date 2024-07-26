#!/bin/bash -l
#
#SBATCH --job-name="dvegarod_perftests_julia"
#SBATCH --time=00:03:00
#SBATCH --output=batchout.o
#SBATCH --error=batcherr.e
#SBATCH --account=c23
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --constraint=gpu

srun -n 1 julia mandel/multistep_generator.jl 1000 500 &> production.out &

# srun -n 1 julia mandel/sst-read.jl &> reduction.out &

# Wait for all background jobs to complete
wait
