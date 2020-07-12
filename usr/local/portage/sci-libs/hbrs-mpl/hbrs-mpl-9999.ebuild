# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# kate: tab-indents on; replace-tabs off;

EAPI=7

inherit git-r3 cmake-utils multilib

DESCRIPTION=""
HOMEPAGE="https://github.com/JM1/hbrs-mpl"
EGIT_REPO_URI="https://github.com/JM1/hbrs-mpl.git"
EGIT_BRANCH="master"

LICENSE="GPL-3 BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="openmp -debug -test"

DEPEND="
sci-libs/hbrs-cmake
>=dev-libs/boost-1.62.0
virtual/mpi
sci-libs/elemental
"
# virtual/lapack and sci-libs/lapacke-reference are only needed for MATLAB addon

RDEPEND="${DEPEND}"
BDEPEND=""

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_configure() {
	local mycmakeargs=(
		-DHBRS_MPL_ENABLE_ELEMENTAL=ON
		-DHBRS_MPL_ENABLE_MATLAB=OFF
		-DHBRS_MPL_ENABLE_TESTS=$(usex test)
		-DHBRS_MPL_ENABLE_DEBUG_OUTPUT=$(usex debug)
	)
	
	if use debug; then
		CMAKE_BUILD_TYPE=Debug
	fi
	
	cmake-utils_src_configure
}
