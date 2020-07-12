#!/usr/bin/env bash
#SBATCH --partition=hpc3
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH --exclusive
#SBATCH --mem=8G
#SBATCH --time=1:00:00
#SBATCH --output=slurm.%j.out
#SBATCH --error=slurm.%j.err

module load openmpi/gnu

mpirun ./bin_no_prefix 28 100
