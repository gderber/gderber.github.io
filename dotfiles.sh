#!/usr/bin/env bash
# ======================================================================
#
# Dotfile.sh installer
#
#    G. S. Derber
#
# ======================================================================
SRCFILEDIR=${HOME}/src
DOTFILEDIR=${SRCFILEDIR}/dotfiles
DOTFILESSH=$(which dotfiles.sh)
DOTFILESRC=${HOME}/.dotfilesrc
DOTFILESSHDIR=${PWD}
TODAY=$(date +%F)
GITHOST=git
GIT=$(which git)
CLONE="${GIT} clone"

# ======================================================================
#
# function help
#
# ======================================================================
function __help () {
    cat << HELP
dotfiles.sh

...
HELP
}

# ======================================================================
#
# function idghuser
#
# ======================================================================
function idghuser () {
    if [[ -z $1 ]]; then
	read -p "What is your github username? (Leave blank if you do not have one)" GHUSER
    else
	GHUSER=$1
    fi
    [[ -n ${GHUSER} ]] && echo "GHUID=${GHUSER}" > "${DOTFILERC}"
}

# ======================================================================
#
#
#
# ======================================================================
function getlocaldomain () {
    local DN
    DN=$(python -c 'import socket; print(socket.getfqdn())'|cut -d. f2-)
    ehco -ne ${DN}
}

# ======================================================================
#
#
#
# ======================================================================
function download () {
    if [[ -d ${SRCFILEDIR} ]]; then
	# Update
	cd ${DOTFILEDIR}
	git pull origin master
    else
	mkdir -p ${SRCFILEDIR}
	cd ${SRCFILEDIR}
	local DN=$(getlocaldomain)
	local GITFQDN=${GITHOST}.${DN}
	if [[ $(ping -c1 git &>/dev/null) ]]; then
	    ${CLONE} "git@git:dotfiles.git"
	elif [[ $(ping -c1 ${GITFQDN} &>/dev/null) ]]; then
	    ${CLONE} "git@{GITFQDN}:dotfiles.git"
	else
	    GHUID=${GHUID:-gderber}
	    ${CLONE} "https://github.com/${GHUID}/dotfiles.git"
	fi
    fi
    
}

# ======================================================================
#
#
#
# ======================================================================
function selfinstall () {
    BASEPREFIX=${1}
    BINDIR="bin"
    local PREFIX
    unset SUDO
    if [[ $(sudo -v &>/dev/null) ]]; then
	PREFIX=${1:-"/usr/local/"}
	SUDO="$(which sudo)"
    elif [[ -n "${BASEPREFIX}" ]]; then
	if [[ -d "${BASEPREFIX}" ]]; then
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
    [[ "${INSTDIR}" != "${PWD}" ]] &&
	if [[ ! -f "${INSTDIR}/dotfiles.sh" ]] || [[ "${TODAY}" != "${LASTUPDATE}" ]]; then
	    mkdir -pv ${INSTDIR} &&
		${SUDO} cp ${DOTFILESSHDIR}/dotfiles.sh ${INSTDIR} &&
		chmod 755 ${INSTDIR}/dotfiles.sh
	fi
}

# ======================================================================
#
#
#
# ======================================================================
function install () {
    cd ${DOTFILEDIR} &&
	make install
}
    
# ======================================================================
#
#
#
# ======================================================================
function main () {

    while [[ -n $1 ]]
    do
	case $1 in
	    --prefix)
		PREFIX=$2
		shift 2
		;;
	    --ghuser)
		GHUSER=$2
		shift 2
		;;
	    --reset)
		RESET=true
		shift 1
		;;
	    *)
		__help
		exit 1
		;;
	esac
    done

    if [[ "${RESET}" != "true " ]] && [[ -f ${DOTFILESRC} ]]; then
	source ${DOTFILESRC}
    else
	idghuser
    fi
    
    download &&
	install &&
    selfinstall ${PREFIX} &&

    if [[ -f ${DOTFILESRC} ]]; then
	if [[ $(grep -q LASTUPDATE ${DOTFILESRC}) ]]; then
	    echo "sed"
	else
	    echo "LASTUPDATE=$(date +%F)" >> "${DOTFILESRC}"
	fi
    else
	echo "LASTUPDATE=$(date +%F)" > "${DOTFILESRC}"
    fi
}

main $@
