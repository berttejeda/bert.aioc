#!/usr/bin/env bash

script_dir=${0%/*}
script_name=${0##*/}
script_base_name=${script_name%%.*}
environment_name=${script_dir##*/}

RESTORE=$(echo -en '\033[0m')
RED=$(echo -en '\033[00;31m')
GREEN=$(echo -en '\033[00;32m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
MAGENTA=$(echo -en '\033[00;35m')
PURPLE=$(echo -en '\033[00;35m')
CYAN=$(echo -en '\033[00;36m')
LIGHTGRAY=$(echo -en '\033[00;37m')
LRED=$(echo -en '\033[01;31m')
LGREEN=$(echo -en '\033[01;32m')
LYELLOW=$(echo -en '\033[01;33m')
LBLUE=$(echo -en '\033[01;34m')
LMAGENTA=$(echo -en '\033[01;35m')
LPURPLE=$(echo -en '\033[01;35m')
LCYAN=$(echo -en '\033[01;36m')
WHITE=$(echo -en '\033[01;37m')

USAGE="""
Usage: ./${script_name}
e.g.
	* Create the InnoSetup Installer, bumping up major version
		./${script_name} build major
	* Create the InnoSetup Installer, bumping up minor version
		./${script_name} build minor
	* Create the InnoSetup Installer, bumping up patch version
		./${script_name} build patch
"""

if [[ ($# -lt 1) || ("${@}" =~ ^--help$) ]]; then 
	echo -e "${USAGE}"
	exit 0
fi

remote_name=github

# CLI
while (( "$#" )); do
	if [[ "$1" =~ ^--dry$ ]]; then exec_action=echo;shift;fi
	if [[ "$1" =~ ^build$ ]]; then action=$2;shift;fi
	if [[ "$1" =~ ^--remote-name$|^-r$ ]]; then remote_name=$2;shift;fi
	if [[ "$1" =~ ^--start-tag-or-commit$|^-s$ ]]; then start_tag_or_commit=$2;shift;fi
	if [[ "$1" =~ ^--end-tag-or-commit$|^-e$|^-s$ ]]; then end_tag_or_commit=$2;shift;fi		
	release=$@
	shift
	unmatched_args+="${1} "
done

function build() {

	innosetupdir="/c/Program Files (x86)/Inno Setup 6"

	RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'

	base=$(git tag 2>/dev/null| tail -n 1)

	if [ -z "$base" ];then
	  base=0.0.0
	fi

	MAJOR=`echo $base | sed -e "s#$RE#\1#"`
	MINOR=`echo $base | sed -e "s#$RE#\2#"`
	PATCH=`echo $base | sed -e "s#$RE#\3#"`

	case "$release" in
	major)
	  let MAJOR+=1
	  ;;
	minor)
	  let MINOR+=1
	  ;;
	patch)
	  let PATCH+=1
	  ;;
	esac

	if [ ! -d "$innosetupdir" ]; then
	    echo "ERROR: Couldn't find innosetup which is needed to build the installer. We suggest you install it using chocolatey. Exiting."
	    exit 1
	fi
	export AIOC_VERSION="$MAJOR.$MINOR.$PATCH" 
	echo "AIOC Version is ${AIOC_VERSION}"
	echo "Building InnoSetup"
	${exec_action} "$innosetupdir/iscc.exe" $PWD/setup.iss
	echo "Adding git tag for ${AIOC_VERSION}"
	if ! git tag "${AIOC_VERSION}";then ${exec_action} git tag "${AIOC_VERSION}";fi
}

if [[ $action == "installer" ]];then	
	build
elif [[ $action == "history" ]];then
    git_branch=$(git rev-parse --abbrev-ref HEAD);
    last_commit=$(git log --pretty=format:'%h' -n 1)
    repo_url=$(git config --get remote.${remote_name}.url | sed 's/\.git//' | sed 's/:\/\/.*@/:\/\//');
    ${exec_action} git log --no-merges ${start_tag_or_commit}..${end_tag_or_commit-${last_commit}} --format="* %s [%h]($repo_url/commit/%H)" | sed 's/      / /'
fi
