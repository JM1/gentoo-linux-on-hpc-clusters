# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# kate: tab-indents on; replace-tabs off;

EAPI=7

inherit git-r3 fortran-2 cmake-utils multilib

DESCRIPTION="Distributed-memory, arbitrary-precision, dense and sparse-direct linear algebra, conic optimization, and lattice reduction"
HOMEPAGE="http://libelemental.org"
EGIT_REPO_URI="https://github.com/elemental/Elemental.git"

LICENSE="BSD-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="openmp valgrind scalapack -qt5 -debug"

DEPEND="
virtual/mpi
virtual/blas
virtual/lapack
dev-libs/mpc
dev-libs/gmp
dev-libs/mpfr
sci-libs/qd
sci-libs/metis
sci-libs/flame
virtual/lapacke
scalapack? ( sci-libs/scalapack )
valgrind? ( dev-util/valgrind )
qt5? ( dev-qt/qtwidgets )"

RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES=(
	"${FILESDIR}"/fix-math-library-search-paths.patch
	"${FILESDIR}"/use-system-default-cflags-and-raise-cpp-std.patch
)

src_configure() {
	local mycmakeargs=(
		-DBINARY_SUBDIRECTORIES=OFF
		-DEL_USE_QT5=$(usex qt5 ON OFF)
		-DEL_TESTS=OFF
		-DEL_EXAMPLES=OFF
		-DEL_HYBRID=$(usex openmp ON OFF)
		-DINSTALL_PYTHON_PACKAGE=OFF
		-DEL_DISABLE_SCALAPACK=$(usex scalapack OFF ON)
		-DEL_DISABLE_PARMETIS=ON
		-DEL_DISABLE_QUAD=ON
		-DEL_DISABLE_VALGRIND=$(usex valgrind OFF ON)
		-DINSTALL_CMAKE_DIR="share/cmake"
		-DMATH_LIBS="$(usex scalapack '-lscalapack ' '')-lflame -llapack -lblas"
	)
	
	if use debug; then
		CMAKE_BUILD_TYPE=Debug
	else
		CMAKE_BUILD_TYPE=Release
	fi
	
	cmake-utils_src_configure
}
