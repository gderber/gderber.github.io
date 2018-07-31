#!/bin/sh
# ======================================================================
#
# Dotfile.sh installer
#
#    G. S. Derber
#
# ======================================================================
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
# function updateremotes
#
# ======================================================================
updateremotes () {
    cd ${DOTFILEDIR}
    local DN=$(dnsdomainname)
    local GITFQDN=${GITHOST}.${DN}
    unset ORIGIN
    
    if $(ping -c1 git > /tmp/dotfilessh > /dev/null 2>&1) ; then
	ORIGIN=git
    elif $(ping -c1 ${GITFQDN} > /tmp/dotfilessh > /dev/null 2>&1) ; then
	ORIGIN=${GITFQDN}
    fi
    echo ${ORIGIN}
    if [ "${ORIGIN}" = "git" ] || [ "${ORIGIN}" = "${GITFQDN}" ] ; then
	git remote rename origin github
	git remote add origin "git@${ORIGIN}:dotfiles.git"
    fi
}

# ======================================================================
#
# function download
#
# ======================================================================
download () {
    if [ -d ${DOTFILEDIR} ]; then
	# Update
	cd ${DOTFILEDIR}
	git pull origin master
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
	SUDO="$(which sudo)"
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
	    if [ ! -f "${INSTDIR}/dotfiles.sh" ] || [ "${TODAY}" != "${LASTUPDATE}" ]; then
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
    
download &&
    install &&
    if [ -f ${PWD}/dotfiles.sh ]; then
	selfinstall ${PREFIX} &&
	    echo "..."
    fi
    if [ -f ${DOTFILESRC} ]; then
	if $(grep -q LASTUPDATE ${DOTFILESRC}) ; then
	    sed -i 's/LASTUPDATE=.*/LASTUPDATE='$(date +%F)'/g' "${DOTFILESRC}"
	else
	    echo "LASTUPDATE=$(date +%F)" >> "${DOTFILESRC}"
	fi
    else
	echo "LASTUPDATE=$(date +%F)" > "${DOTFILESRC}"
    fi
