# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# kate: tab-indents on; replace-tabs off;

EAPI=7

inherit git-r3 cmake-utils multilib

DESCRIPTION=""
HOMEPAGE="https://github.com/JM1/hbrs-cmake"
EGIT_REPO_URI="https://github.com/JM1/hbrs-cmake.git"

LICENSE="GPL-3 BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="-debug -test"

DEPEND=">=dev-libs/boost-1.62.0"
RDEPEND="${DEPEND}"
BDEPEND=""

src_configure() {
	local mycmakeargs=(
		-DHBRS_CMAKE_ENABLE_TESTS=$(usex test)
	)
	
	if use debug; then
		CMAKE_BUILD_TYPE=Debug
	fi
	
	cmake-utils_src_configure
}
