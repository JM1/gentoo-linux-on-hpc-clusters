#!/usr/bin/env bash
#SBATCH --partition=hpc3
#SBATCH --nodes=5
#SBATCH --ntasks-per-node=30
#SBATCH --ntasks-per-core=1
#SBATCH --exclusive
#SBATCH --mem=185G
#SBATCH --time=72:00:00
#SBATCH --output=slurm.%j.out
#SBATCH --error=slurm.%j.err

# Set LD_LIBRARY_PATH to prevent errors like
#  [wr50:317033] mca_base_component_repository_open: unable to open mca_pml_ucx: libbfd-2.32.0.gentoo-sys-devel-binutils-st.so: cannot open shared object file: No such file or directory (ignored)
# Is also set by /etc/modulefiles/mpi/openmpi-x86_64 for system-wide/non-gentoo-prefix OpenMPI programs

export LD_LIBRARY_PATH=$HOME/gentoo/usr/lib64/:$HOME/gentoo/usr/lib64/binutils/x86_64-pc-linux-gnu/2.34/

set -e
set -x

mpirun pvserver --server-port=31336 --reverse-connection --client-host=wr0.wr.inf.h-brs.de --force-offscreen-rendering --disable-xdisplay-test
