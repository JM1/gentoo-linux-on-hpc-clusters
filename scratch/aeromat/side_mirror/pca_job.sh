#!/usr/bin/env bash
#SBATCH --partition=hpc3
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=32
#SBATCH --ntasks-per-core=1
#SBATCH --exclusive
#SBATCH --mem=8G
#SBATCH --time=4:00:00
#SBATCH --output=slurm.%j.out
#SBATCH --error=slurm.%j.err

# Set LD_LIBRARY_PATH to prevent errors like
#  [wr50:317033] mca_base_component_repository_open: unable to open mca_pml_ucx: libbfd-2.32.0.gentoo-sys-devel-binutils-st.so: cannot open shared object file: No such file or directory (ignored)
# Is also set by /etc/modulefiles/mpi/openmpi-x86_64 for system-wide/non-gentoo-prefix OpenMPI programs

export LD_LIBRARY_PATH=$HOME/gentoo/usr/lib64/:$HOME/gentoo/usr/lib64/binutils/x86_64-pc-linux-gnu/2.33.1/

prefix=car

# test
mpirun hbrs_theta_utils_cli --verbose 2 pca --backend ELEMENTAL_MPI --pval-prefix ${prefix} --center --normalize --overwrite --output-prefix ${prefix}_centered_normalized

# all pcs
mpirun hbrs_theta_utils_cli --verbose 2 pca --backend ELEMENTAL_MPI --pval-prefix ${prefix} --center --normalize --overwrite --output-prefix ${prefix}_centered_normalized               --pcs 0-last

# only mean
mpirun hbrs_theta_utils_cli --verbose 2 pca --backend ELEMENTAL_MPI --pval-prefix ${prefix} --center --normalize --overwrite --output-prefix ${prefix}_centered_normalized               --pcs none

# pcs without mean
mpirun hbrs_theta_utils_cli --verbose 2 pca --backend ELEMENTAL_MPI --pval-prefix ${prefix} --center --normalize --overwrite --output-prefix ${prefix}_centered_normalized_keep-centered --pcs 0 --pcs 1 --pcs 2 --pcs 3 --pcs 4-last --keep-centered

# pcs with mean
mpirun hbrs_theta_utils_cli --verbose 2 pca --backend ELEMENTAL_MPI --pval-prefix ${prefix} --center --normalize --overwrite --output-prefix ${prefix}_centered_normalized               --pcs 0-2
