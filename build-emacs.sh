#!/usr/bin/env bash
# -*- mode: shell-script; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
#
# Copyright (C) 2020 coldnew's personal project
# Authored-by:  Yen-Chin, Lee <coldnew.tw@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

# Get where is this script
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configration
INSDIR="${SDIR}/build"
SRCDIR="${SDIR}/emacs"

################################################################################
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e
################################################################################

do_autogen () {
    ./autogen.sh
}

do_configure_cli () {
    ./configure --prefix=${INSDIR} --with-modules --with-libgmp \
                --without-x \
                --without-ns \
		--with-nativecomp
}

do_configure_linux () {
    ./configure --prefix=${INSDIR} --with-modules --with-libgmp \
                --without-ns --disable-ns-self-contained \
                --with-x --with-x-toolkit=gtk3 \
		--with-nativecomp
}

do_make () {
    #    make bootstrap
    make -j9
}


do_install () {
    make install
}

do_clean () {
    make distclean
    make mantainer-clean
}

################################################################################

# check if submodule already exist
if [ ! -d $SRCDIR/src ]; then
    git submodule init
    git submodule update
fi

# building emacs
cd $SRCDIR

# check commit id, if already build, it's no need to rebuild
if [ -f "$INSDIR/commit-id" ]; then
    OLD_ID=$(cat "$INSDIR/commit-id")
    NEW_ID=$(git rev-parse --short HEAD)
    if [ $OLD_ID == $NEW_ID ]; then
        echo "Your emacs is match to commit-id, no need to rebuild."
        exit 0 # quit
    else
        echo -ne "$NEW_ID" > "$INSDIR/commit-id"
        echo "Start rebuilding emacs..."
    fi
fi

do_autogen

# configure according to platform
if [[ $CI == "true" ]]; then
    do_configure_cli
else
    case $(uname) in
        "Linux")
            do_configure_linux
            ;;
        *)
            echo "This building script only support Linux"
            exit -1
            ;;
    esac
fi

# You need to set --with-modules to enable dynamic modules feature
do_make
do_install
