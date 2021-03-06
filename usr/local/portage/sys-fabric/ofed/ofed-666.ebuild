# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="transitional dummy package for sys-fabric/rdma-core"
HOMEPAGE=""
SRC_URI=""

LICENSE="|| ( GPL-2 BSD-2 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+opensm"

DEPEND="sys-fabric/rdma-core
    opensm? ( sys-fabric/opensm )"
RDEPEND="${DEPEND}"

BDEPEND=""
