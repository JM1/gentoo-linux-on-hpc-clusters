# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib

DESCRIPTION="intel/opa-psm2"
HOMEPAGE="https://github.com/intel/opa-psm2"
SRC_URI="https://github.com/intel/opa-psm2/archive/PSM2_${PV}.tar.gz -> ${PN}-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="sys-process/numactl"
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}/${PN}-PSM2_${PV}"

src_install() {
    emake DESTDIR="${ED}" install
}
