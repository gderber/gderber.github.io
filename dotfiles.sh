#!/bin/sh
# ======================================================================
#
# dotfiles.sh ---
# 
# Filename: dotfiles.sh
# Description: 
# Author: Geoff S Derber
# Maintainer: 
# Created: Fri Sep  7 15:58:44 2018 (-0400)
# Version: 
# Package-Requires: ()
# Last-Updated: Sun Jun  9 08:39:40 2019 (-0400)
#           By: Geoff S Derber
#     Update #: 35
# URL: 
# Doc URL: 
# Keywords: 
# Compatibility: 
# 
# 

# Commentary: 
# 
# 
# 
# 

# Change Log:
# 
# 
# 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
# 
# 
# ======================================================================
# Code:

SRCFILEDIR=${HOME}/.local/src
DOTFILEDIR=${SRCFILEDIR}/dotfiles
DOTFILESSH=$(command -v dotfiles.sh)
DOTFILESRC=${HOME}/.dotfilesrc
DOTFILESSHDIR=${PWD}
TODAY=$(date +%F)
GITHOST=git
GIT=$(command -v git)
CLONE="${GIT} clone"

user=$(echo ${HOME}| sed 's|.*/||')
if [ ${UID} -lt 100000 ]; then
    fqdn=$(hostname -f)
    useremail=${user}@${fqdn}
    username=${user}
else
    fqdn=$(hostname -f|cut -d. -f3-)
    useremail=${user}@${fqdn}
    username=${user}

fi


# ======================================================================
#
# function help
#
# ======================================================================
dfhelp() {
    cat << HELP
dotfiles.sh

Installs / updates dotfiles from git repo automatically

Switch
--prefix	Sets install prefix (Defaults to "/usr/local/" or "/home/\${user}/"
		Depending on if executing user has sudo priveledges.
--ghuser [name] Sets github's user name to $[name]
--reset	 	Resets all previously set optionss
--h|--help	Prints this help

HELP
}

# ======================================================================
#
# function idghuser
#
# ======================================================================
idghuser () {
    if [ -z $1 ]; then
        read -p "What is your github username? (Leave blank if you do not have one)" GHUSER
    else
        GHUSER=$1
    fi
    if [ -n ${GHUSER} ]; then
        echo "GHUID=${GHUSER}" > "${DOTFILESRC}"
    fi
}

# ======================================================================
#
# function genkeys
#
# ======================================================================
genkeys () {
    keyVal=$(gpg -K | awk '/sec/{if (length($2) > 0) print $2}'|sed 's|.*/0x||' ) &&
        if [ ! -n $keyVal ]; then
            gpg --full-generate-key --expert &&
                keyVal=$(gpg -K | awk '/sec/{if (length($2) > 0) print $2}'|sed 's|.*/0x||' ) &&
                gpg --edit-key --expert $keyVal
        fi
}

# ======================================================================
#
# function installkeys
#
# ======================================================================
exportkeys () {
    keyVal=$(gpg -K |
                 awk '/sec/{if (length($2) > 0) print $2}' |
                 sed 's|.*/0x||' |
                 sort -u)

    # Export gpg pubkey
    # Using file 'finger' looks for
    gpg --armor --export ${keyVal} > ${HOME}/.pubkey

    mkdir -p ${HOME}/.ssh

    gpg --export-ssh-key ${keyVal} > ${HOME}/.ssh/${username}.pub
}

# ======================================================================
#
# function installkeys
#
# ======================================================================
installkeys () {
    local DN=$(dnsdomainname)
    local GITFQDN=${GITHOST}.${DN}
    unset ORIGIN
    local ORIGIN

    if ping -c1 git > /dev/null; then
        ORIGIN=git
    elif ping -c1 ${GITFQDN} > /dev/null; then
        ORIGIN=${GITFQDN}
    fi
}


# ======================================================================
#
# setcrontab
#
# ...
#
#
# ======================================================================
setcrontab () {
    if command -v nightly > /dev/null 2>&1 ; then
        CRONCMD="$(command -v nightly)"

        #Add to Crontab
        CRONJOB="0 23 * * * ${CRONCMD}"
        # Pipe contents of crontab to grep
        # Grep removes cronjob if it exists
        # Print crinjob
        # Pipe alk of the above back to crontab
        ( crontab -l | grep -v -F "${CRONCMD}" ; echo "${CRONJOB}" ) | crontab -
    fi

}

# ======================================================================
#
# setgitconflocal
#
# ======================================================================
setgitconflocal () {
    keyVal=$(getgpgkey)
    cat << GITCONFLOCAL > ${HOME}/.gitconfig.local
[user]
  email = ${useremail}
  name = ${username}
  signingkey = ${keyVal}
GITCONFLOCAL

}


# ======================================================================
#
# function updateremotes
#
# ======================================================================
updateremotes () {
    cd ${DOTFILEDIR}
    local DN=$(dnsdomainname)
    local GITFQDN=${GITHOST}.${DN}
    unset ORIGIN
    local ORIGIN

    if ping -c1 git > /dev/null; then
        ORIGIN=git
    elif ping -c1 ${GITFQDN} > /dev/null; then
        ORIGIN=${GITFQDN}
    fi
    if [ -n "${ORIGIN}" ] ; then
        git remote rename origin github
        git remote add origin "git@${ORIGIN}:dotfiles.git"
    fi
}

# ======================================================================
#
# function download
#
# Clone or Update the dotfiles repo
#
# ======================================================================
download () {
    if [ -d ${DOTFILEDIR} ]; then
        # Update
        cd ${DOTFILEDIR}
        if ping -c1 git > /dev/null ; then
            git pull origin master
        else
            git pull github master
        fi
    else
        mkdir -p ${SRCFILEDIR}
        cd ${SRCFILEDIR}
        GHUID=${GHUID:-gderber}
        ${CLONE} "https://github.com/${GHUID}/dotfiles.git"
        updateremotes
    fi

}

# ======================================================================
#
#
#
# ======================================================================
install () {
    cd ${DOTFILEDIR} &&
        make install
}

while :; do
    case $1 in
        --prefix)
            if [ -n $2 ]; then
                PREFIX=$2
                shift
            else
                printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --ghuser)
            if [ -n $2 ]; then
                GHUSER=$2
                shift
            else
                printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --reset)
            RESET=true
            ;;
        -h|-\?|--help)
            dfhelp
            exit
            ;;
        -?*)
            dfhelp
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ "${RESET}" != "true " ] && [ -f ${DOTFILESRC} ]; then
    . ${DOTFILESRC}
else
    idghuser
fi

genkeys &&
    download &&
    install &&
    setcrontab &&
    setgitconflocal
#
# dotfiles.sh ends here
