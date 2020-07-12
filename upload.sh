#!/bin/sh
#
# vim:set syntax=sh fileformat=unix shiftwidth=4 softtabstop=4 expandtab textwidth=120:
# kate: syntax bash; end-of-line unix; space-indent on; indent-width 4; word-wrap-column 120; word-wrap on;
# kate: remove-trailing-space on;
#
# Copyright (c) 2019-2020 Jakob Meng, <jakobmeng@web.de>

set -e
set -x

[ -n "$1" ] && SRV_HOST="$1"          || SRV_HOST=wr0.wr.inf.h-brs.de
[ -n "$2" ] && SRV_USER="$2"          || SRV_USER=jmeng2m
[ -n "$3" ] && SRV_HOME="$3"          || SRV_HOME=/home/$SRV_USER
[ -n "$4" ] && SRV_GENTOO_PREFIX="$4" || SRV_GENTOO_PREFIX=$SRV_HOME/gentoo
[ -n "$5" ] && SRV_SCRATCH="$5"       || SRV_SCRATCH=/scratch/$SRV_USER

scp -rp home/* home/.local/ home/.taudef* "$SRV_USER@$SRV_HOST:$SRV_HOME/"
scp -rp scratch/* "$SRV_USER@$SRV_HOST:$SRV_SCRATCH/"
scp -rp etc/ usr/ "$SRV_USER@$SRV_HOST:$SRV_GENTOO_PREFIX/"
