# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake-utils

DESCRIPTION="RDMA core userspace libraries and daemons"
HOMEPAGE="https://github.com/linux-rdma/rdma-core"
SRC_URI="https://github.com/linux-rdma/${PN}/releases/download/v${PV}/${PN}-${PV}.tar.gz"

LICENSE="|| ( GPL-2 BSD-2 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/libnl
!sys-fabric/libibverbs"
RDEPEND="${DEPEND}
sys-apps/ethtool"
BDEPEND=""

PATCHES=(
    "${FILESDIR}"/${PN}-23-disable-systemd-and-udev-integration.patch
)
