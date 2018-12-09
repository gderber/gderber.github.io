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
# Version: 0.1
# Package-Requires: (git make keychain pass)
# Last-Updated: Sun Dec  9 12:09:26 2018 (-0500)
#           By: Geoff S Derber
#     Update #: 90
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
# function checkdependencies
#
# ...
#
# ======================================================================
checkdependencies () {
    echo "Checking for required programs"
    DEPENDS="git make keychain pass"
    #DEPENDS="${DEPENDS} emacs-nox"
    MISSING=""
    for APP in ${DEPENDS}
    do
        if [ ! $(command -v ${APP}) ]; then
            MISSING="${MISSING} ${APP}"
        fi
    done

    missingLength=${#MISSING}
    if [ ${missingLength} -gt 0 ]; then
        if [ $(sudo -v > /tmp/dotfilessh > /dev/null 2>&1) ]; then
            apt install ${MISSING}
        else
            echo "Missing Applications: ${MISSING}" &&
                exit 1
        fi
    fi

    echo "Check complete"
}

# ======================================================================
#
# function idghuser
#
# Identifies github username
#
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
selfinstall () {
    BASEPREFIX=${1}
    BINDIR="bin"
    local PREFIX
    unset SUDO
    if [ $(sudo -v > /tmp/dotfilessh > /dev/null 2>&1) ]; then
        PREFIX=${1:-"/usr/local/"}
        SUDO="$(command -v sudo)"
    elif [ -n "${BASEPREFIX}" ]; then
        if [ -d "${BASEPREFIX}" ]; then
            PREFIX="${BASEPREDIX}"
        else
            PREFIX="${HOME}/${BASEPREFIX}"
        fi
    else
        PREFIX="${HOME}/.local"
    fi
    INSTDIR="${PREFIX}/${BINDIR}"

    echo "INSTDIR: ${INSTDIR}"
    echo ${PWD}

    if [ ! -f ${PWD}/dotfiles.sh ]; then
        if [ "${INSTDIR}" != "${PWD}" ]; then
            if [ ! -f "${INSTDIR}/dotfiles.sh" ] ||
                   [ "${TODAY}" != "${LASTUPDATE}" ]; then
                mkdir -pv ${INSTDIR} &&
                    ${SUDO} cp ${DOTFILESSHDIR}/dotfiles.sh ${INSTDIR} &&
                    chmod 755 ${INSTDIR}/dotfiles.sh
            fi
        fi
    fi
}

# ======================================================================
#
#
#
# ======================================================================
dfinstall () {
    cd ${DOTFILEDIR} &&
        git verify-commit $(git rev-parse HEAD) &&
        make install
}

# ======================================================================
#
# initpass
#
# 
#
# ======================================================================
initpass () {
    # Identify the key to use
    # Really need a way to identify a specific key
    keyVal=$(gpg -K |
                 awk '/sec/{if (length($2) > 0) print $2}' |
                 sed 's|.*/0x||' |
                 head -n 1) &&
        pass init ${keyVal}
}

# ======================================================================
#
# genuserkeys
#
# ======================================================================
genuserkeys () {
    # Generate GPG keys
    keyVal=$(gpg -K |
                 awk '/sec/{if (length($2) > 0) print $2}' |
                 sed 's|.*/0x||' |
                 head -n 1) &&
        if [ ! -n $keyVal ]; then
            gpg --full-generate-key \
                --expert &&
                keyVal=$(gpg -K | awk '/sec/{if (length($2) > 0) print $2}'|sed 's|.*/0x||' ) &&
                gpg --edit-key --expert $keyVal
        fi

    keyVal=$(gpg -K |
                 awk '/sec/{if (length($2) > 0) print $2}' |
                 sed 's|.*/0x||' |
                 head -n 1)
    if [ ! -f ${HOME}/.pgpkey ]; then
        gpg \
            --armor \
            --export ${keyal} > ${HOME}/.pgpkey
    fi

    # Eport Authentication key
    keyVal=$(gpg -K |
                 awk '/\[A\]/{if (length($2) > 0) print $2}' |
                 sed 's|.*/0x||' |
                 head -n 1)

    user=$(echo ${HOME}| cut -d/ -f4)
    echo $user
    if [ ! -f ${HOME}/.ssh/${user}_gpg.pub ]; then
        gpg --armor \
            --export-ssh-key \
            --output ${HOME}/.ssh/${user}_gpg.pub \
            ${keyVal}

    fi

    SSHKEYS="ed25519 rsa"
    # Check if password-store is setup
    if [ ! -d ${HOME}/.password-store ]; then
        initpass &&
        for key in ${SSHKEYS}
        do
            # Add passwords for ssh keys
            pass insert ${USER}/ssh/${key}
        done
    fi

    # Generate SSH Keys
    # ed25519 is primary
    # rsa is for applications/sites that don't support ed25519
    for key in ${SSHKEYS}
    do
        # If the key doesn't exist, generate it
        if [ ! -f ~/.ssh/id_${key} ]; then
            case $key in
                ed25518)
                    OPTS=""
                    ;;
                rsa)
                    OPTS="-b 4096"
                    ;;
            esac
            ssh-keygen -t ${key} \
                       -f ${HOME}/.ssh/id_${key} ${OPTS}
        fi
    done
}


# ======================================================================
#
#
#
# ======================================================================
setcrontab () {
    CRONCMD="$(command -v nightly)"

    #Add to Crontab
    CRONJOB="0 23 * * * ${CRONCMD}"
    # Pipe contents of crontab to grep
    # Grep removes cronjob if it exists
    # Print crinjob
    # Pipe alk of the above back to crontab
    ( crontab -l |
          grep -v -F "${CRONCMD}" ; echo "${CRONJOB}" ) |
        crontab -


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

checkdependencies &&
download &&
dfinstall &&
genuserkeys &&
initpass &&
setcrontab

if [ -f ${DOTFILESRC} ]; then
    if $(grep -q LASTUPDATE ${DOTFILESRC}) ; then
        sed -i 's/LASTUPDATE=.*/LASTUPDATE='$(date +%F)'/g' "${DOTFILESRC}"
    else
        echo "LASTUPDATE=$(date +%F)" >> "${DOTFILESRC}"
    fi
else
    echo "LASTUPDATE=$(date +%F)" > "${DOTFILESRC}"
fi

#
# dotfiles.sh ends here
