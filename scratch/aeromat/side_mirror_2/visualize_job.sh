#!/usr/bin/env bash
#SBATCH --partition=hpc3
#SBATCH --nodes=20
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

prefix=car

[ -e "${prefix}.para" ] || exit 255

archive_path="$PWD/archive"

# Copy Grid to output for Ensight Gold (e.g. readable with ParaView)
case_dir="$archive_path/ensight"
if [ -e "${prefix}.grid.case" ] || [ -e "${case_dir}/${prefix}.grid.case" ]; then
    echo "ensight files found, skipping tau2plt"
else
    "${TAUHOME}/bin/tau2plt" "${prefix}.grid" -g -G
    ./archive.sh
fi

# visualize original flow
vtk_dir="$archive_path/${prefix}_original/vtk"
if [ -d "$vtk_dir" ]; then
    echo "vtk dir $vtk_dir found, skipping $file_prefix"
else
    mpirun hbrs_theta_utils_cli --verbose 2 visualize --grid-prefix ${prefix} --overwrite --pval-prefix ${prefix} --output-prefix ${prefix}_original
    ./archive.sh
fi

# visualize pca-decomposed flow
for tag in \
    pca_0 \
    pca_1 \
    pca_2 \
    pca_3 \
    pca_4 \
    pca_5-last \
    pca_centered_normalized_all \
    pca_centered_normalized_0-last \
    pca_centered_normalized_none \
    pca_centered_normalized_keep-centered_0 \
    pca_centered_normalized_keep-centered_1 \
    pca_centered_normalized_keep-centered_2 \
    pca_centered_normalized_keep-centered_3 \
    pca_centered_normalized_keep-centered_4-last \
    pca_centered_normalized_keep-centered_0-last \
    pca_centered_normalized_0-2; \
do
    (
        file_prefix="${prefix}_${tag}"
        vtk_dir="$archive_path/$file_prefix/vtk"
        if [ -d "$vtk_dir" ]; then
            echo "vtk dir $vtk_dir found, skipping $file_prefix"
            continue
        fi
        
        pval_dir="$archive_path/$file_prefix/pval"
        if [ ! -d "$pval_dir" ]; then
            echo "pval dir $pval_dir not found, skipping $file_prefix"
            continue
        fi
        cd "$pval_dir"
        mpirun hbrs_theta_utils_cli --verbose 2 visualize --grid-prefix ${prefix} --overwrite --pval-prefix ${file_prefix}
    )
    ./archive.sh
done
