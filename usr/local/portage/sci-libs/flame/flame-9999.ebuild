# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 fortran-2 multilib

DESCRIPTION="High-performance object-based library for DLA computations"
HOMEPAGE="http://www.cs.utexas.edu/~flame/web/"
EGIT_REPO_URI="https://github.com/flame/libflame.git"

LICENSE="BSD-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="static-libs +openmp +threads debug lapack"

DEPEND="lapack? ( virtual/lapack )"
RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES=(
    "${FILESDIR}"/update-version-file.sh-make-valid-multilib-version.patch
)

src_configure() {
    econf \
        --enable-lapack2flame \
        $(use_enable lapack external-lapack-interfaces) \
        --enable-supermatrix \
        --enable-memory-alignment=16 \
        --enable-max-arg-list-hack \
        --enable-vector-intrinsics=sse \
        --enable-dynamic-build \
        $(use_enable static-libs static-build) \
        $(use_enable debug) \
        --enable-multithreading=$(
            if use openmp; then 
                echo "openmp"
            else
                if use threads; then 
                    echo "pthreads"
                else
                    echo "none"
                fi
            fi)
}
