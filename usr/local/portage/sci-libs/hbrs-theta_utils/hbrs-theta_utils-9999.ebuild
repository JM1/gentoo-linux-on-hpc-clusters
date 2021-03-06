# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# kate: tab-indents on; replace-tabs off;

EAPI=7

inherit git-r3 cmake-utils multilib

DESCRIPTION=""
HOMEPAGE="https://github.com/JM1/hbrs-theta_utils"
EGIT_REPO_URI="https://github.com/JM1/hbrs-theta_utils.git"

LICENSE="GPL-3 BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="openmp -debug -test"

DEPEND="
sci-libs/hbrs-cmake
sci-libs/hbrs-mpl
>=dev-libs/boost-1.62.0
virtual/mpi
sci-libs/netcdf[hdf5,mpi]
sci-libs/vtk[mpi]
"
# virtual/lapack and sci-libs/lapacke-reference are only needed for MATLAB addon

RDEPEND="${DEPEND}"
BDEPEND=""

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_configure() {
	local mycmakeargs=(
		-DHBRS_THETA_UTILS_ENABLE_TESTS=$(usex test)
		-DHBRS_THETA_UTILS_ENABLE_DEBUG_OUTPUT=$(usex debug)
	)
	
	if use debug; then
		CMAKE_BUILD_TYPE=Debug
	fi
	
	cmake-utils_src_configure
}
