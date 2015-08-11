#!/bin/bash - 
#===============================================================================
#
#          FILE: install.sh
# 
#         USAGE: ./install.sh 
# 
#   DESCRIPTION: Simple install Script for Nweather
# 
#       OPTIONS: Installs Nweather.sh and assists user in setting Default StationID
#  REQUIREMENTS: Bash 4, GNU coreutils 8.23, GNU Tar 1.27.1, GNU Wget 1.15
#          BUGS: Tested on Linux, will not be able to install any Dependencies if system 
#                does not use apt-get or yum.
#         NOTES: ---
#        AUTHOR: nwmsocal (), nwmsocal702@gmail.com
#  ORGANIZATION: N/A
#       CREATED: 08/06/2015 03:25
#      REVISION: 1.1.2
#       LICENSE: GNU GPLv3
#===============================================================================

set -o errtrace            # -E ERR Trap is inherited by shell functions
set -o pipefail            # The return value of a pipeline is the status of the last command to exit non-zero
set -o nounset             # Treat unset variables as an error when substituting
                           

err_handler ()
{
	local PROGNAME=$(basename "$0")                                        # Equals script name stripped of path
	local LINENUM=${1:-"Unknown line"}                                     # Argument 1: last line of error occurance
	local ERRSTATUS=${2:-$?}                                               # Code of last command defaults to 1 if unset
	local message=${message:-"Unknown Error"}                              # Sets default for local variable message
        
	echo
	echo "${line0} ERROR ${line0}" 
	[[ -d ~/nweather ]] && rm -rf ~/nweather
	[[ -e ~/master.tar.gz ]] && rm -rf ~/master.tar.gz
	echo "Error: ${message}" 1>&2                                          # Prints specific error message
	echo  "${PROGNAME}: line ${LINENUM}: exit status:${ERRSTATUS}" 1>&2    # Prints script name/line number/exit status
	exit "${ERRSTATUS}"
}


# Trap All errors or non 0 exits
trap 'err_handler ${LINENO} $?' ERR

# Global Variables
declare -a notinstalled=(" ")
line0="###############"

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check
#   DESCRIPTION:  Check if Root and the Shell is BASH if not exit
#-------------------------------------------------------------------------------
function check() {
# Check if root
if [[ $EUID -ne 0 ]]; then
	echo "Warning: you must be root to run this script!"
	sudo -k
	exec sudo "$0" "$@"
fi

# check if BASH if not exit
if [[ "$(basename "$SHELL")" != bash ]]; then
	{ local message="Shell is not BASH!"; false; }
fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  ask
#   DESCRIPTION:  Function to ask user if they wish to continue if they dont meet
#                 the scripts requirements.
#-------------------------------------------------------------------------------
function ask() {
	read -rp "Continue with installation? [Y/N]:"
	case $(echo "$REPLY" | tr '[:upper:]' '[:lower:]') in
		y|yes) :
			;;
		*)     echo "${1}"
		       exit 0
		       ;;
       esac
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  version_check
#   DESCRIPTION: Check BASH version # and warn user if BASH is not up to date  
#-------------------------------------------------------------------------------
function version_check() {
check "$@"
echo "${line0} Checking BASH Version Number ${line0}"
local bash=${BASH_VERSION%.*}
local BVERSION=${bash%.*}

if [ "$BVERSION" -le 3 ]; then
	echo "${line0} WARNING! ${line0}" 
	echo "Old version of BASH detected,Version:${bash} "
	echo "Installation will probably succeed, but it is recommended that you"\
        "upgrade your BASH Version"
	echo "BASH 4.3 is available from ftp://ftp.cwru.edu/pub/bash/bash-4.3.tar.gz"

	ask "User Terminated installation, BASH Version old!"
else
	echo "BASH version: ${bash} is up to date!"
fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install_check
#   DESCRIPTION:  Check to see if Nweather is already installed and weather dependencies are met.
#-------------------------------------------------------------------------------
function install_check() {
version_check "$@" || { local message="Function version_check exited with No Success!"; false; }
local statelistdir='/var/lib/nweather/statelist.txt'
local nweathershdir='/usr/local/bin/nweather'
local nsd_ccccdir='/var/lib/nweather/nsd_cccc.txt'
declare -a programs=(wget tar sha256sum)

if [[ -s ${statelistdir} && -s ${nweathershdir} && -s ${nsd_ccccdir} ]]; then
	 echo "Installation files already exist, Continuing will OverWrite with New Files"
	 ask "User Terminated install to Not overwrite previous installation!"
fi

# Check dependencies for installation
echo "${line0} Checking if Dependencies are already installed! ${line0}"

for app in "${programs[@]}"; do
	if ${app} -v >/dev/null 2>&1 || ${app} --version >/dev/null 2>&1; then
		echo "Success ${app} is already installed"
	else
		notinstalled=("${notinstalled[@]}" "${app}")
		echo "Warning: ${app} is not installed" 1>&2
	fi
done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  installdep
#   DESCRIPTION:  Install Dependencies if needed
#-------------------------------------------------------------------------------
function installdep() {

for prog in "${notinstalled[@]}"; do
	echo "Installing ${prog} from ${tool} repository"
	${1} -y install ${prog} >/dev/null 2>&1 ||
	{ local message="Installing ${prog} with ${1} Failed"; false; }
        echo "Successfully installed dependency - ${prog}" 
done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION: Check OS Type and setup install for dependencies
#-------------------------------------------------------------------------------
function install() {
install_check "$@"
local distrotype=$(cat /etc/*-release | grep "PRETTY_NAME" | grep -Eo '".*"' | tr -d '""')
echo "${line0} Checking Distro Version! ${line0}" 
echo "${distrotype}"
echo "${OSTYPE}"
echo "${line0} Checking Dependencies! ${line0}" 

if [[ "${#notinstalled[@]}" -ge 2 ]]; then
        unset notinstalled[0]
	echo "${#notinstalled[@]} Dependencies needed for installation"
	
	if apt-get --version >/dev/null 2>&1; then
		local tool="apt-get"
		installdep "${tool}" 
	elif yum --version >/dev/null 2>&1; then
		local tool="yum"
		installdep "${tool}" 
	elif [[ "${#notinstalled[@]}" -ge 1 ]]; then
		{ local message="Install ${notinstalled[*]} and restart installation!"; false; }
	fi
else
	echo "Dependencies are already installed!"
fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  download
#   DESCRIPTION:  Download Data from Github.com and noaa.gov and Untar
#-------------------------------------------------------------------------------
function download() {
install "$@" 
local website="https://github.com/nwmsocal702/nweather/archive/master.tar.gz"
echo "${line0} Downloading Nweather from Github.com! ${line0}"
(
cd ~ &&
wget -q ${website}
)
local status1=$?

if (( status1 )); then
	{ local message="Downloading source package of Nweather from github.com"; false; }
else
	echo "Successfully Downloaded Nweather source package from Github.com"
fi

# Untar
echo "Unpacking Nweather source package in Home Directory!"
[ -d ~/nweather ] || mkdir ~/nweather 
tar -xzf ~/master.tar.gz -C ~/nweather --strip-components 1 >/dev/null 2>&1 \
|| { local message="Unpacking Nweather source package to Home Dir!"; false; }
echo "Successfully unpacked Nweather to Home Directory!"
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME: hashtest
#   DESCRIPTION: Test Hashes of installation files 
#-------------------------------------------------------------------------------
function hashtest() {
download "$@"
local nweathersum='15b0760227a3c086acadead5056e35695fe34edba2c57100abc56325208831d7'
local statelistsum='14f624a6791200c440b7cbf5607113826d1dad3509935e7f781d39656ba27b74'
local nsd_ccccsum='da88e9e00d22c044c7e9d681d64faaf15627608805700a14bd1db9c13f1b2a92'

shsum=$(sha256sum ~/nweather/nweather.sh | cut -d' ' -f1)      ||
{ local message="Calculating sha256 Hash of nweather.sh"; false; }
statesum=$(sha256sum ~/nweather/statelist.txt | cut -d' ' -f1) ||
{ local message="Calculating sha256 Hash of statelist.txt"; false; }
nsdsum=$(sha256sum ~/nweather/nsd_cccc.txt | cut -d' ' -f1)    ||
{ local message="Calculating sha256 Hash of nsd_cccc.txt"; false; }

if [ "${shsum}" = "${nweathersum}" ]; then
echo "Success: Hash matches for nweather.sh"
else
	{ local message="Hash does not match for nweather.sh"; false; }
fi

if [ "${statesum}" = "${statelistsum}" ]; then
echo "Success: Hash matches for statelist.txt"
else
	{ local message="Hash does not match for statelist.txt"; false; }
fi

if [ "${nsdsum}" = "${nsd_ccccsum}" ]; then
echo "Success: Hash matches for nsd_cccc.txt"
else
	{ local message="Hash does not match for nsd_cccc.txt"; false; }
fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME: final
#   DESCRIPTION: Final installation of files 
#-------------------------------------------------------------------------------
function final_install() {
download "$@"
local sh_dir='/usr/local/bin'
local data_dir='/var/lib'

if [[ -d ${sh_dir} && -d ${data_dir} ]]; then
	echo "${line0} Copying installation files! ${line0}" 
else
	{ local message="Install Dir ${sh_dir} or ${data_dir} is not found"; false; }
fi

[ ! -d ${data_dir}/nweather ] && mkdir ${data_dir}/nweather >/dev/null 2>&1  
        chmod -R 755 ${data_dir}/nweather >/dev/null 2>&1 ||
       	{ local message="Setting Permissions in ${data_dir}/nweather"; false; }

cp ~/nweather/statelist.txt  ${data_dir}/nweather > /dev/null 2>&1   && 
cp ~/nweather/nweather.sh ${sh_dir}/nweather > /dev/null 2>&1        &&
cp ~/nweather/nsd_cccc.txt ${data_dir}/nweather > /dev/null 2>&1     ||
{ local message="Failed to copy files to installation Directories."; false; }

echo "Success: Installing files"
chmod 755 ${sh_dir}/nweather ${data_dir}/nweather/* ||
       	{ local message="Failed to set permissions"; false; }

echo "Success: Installing files and setting permissions"

echo "Cleaning up Temp Files!"
[[ -d ~/nweather ]] && rm -rf ~/nweather
[[ -e ~/master.tar.gz ]] && rm -rf ~/master.tar.gz

echo "${line0} Installation Complete! ${line0}" 
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME: station_check
#   DESCRIPTION: Function to help user choose default StationID 
#-------------------------------------------------------------------------------
function station_check() {
final_install "$@"
local nsd="/var/lib/nweather/nsd_cccc.txt"
local nw="/usr/local/bin/nweather"
echo "Do you wish to continue and auto add your default station or quit and manually set
the default stationID later after reading the Doc (Installation is complete either way)?"
ask "Installation complete, a default station has not been set!"
tput clear

echo "${line0} StationID List Find! ${line0}" 
echo "----Save the 4 Charachter StationID of the Station you wish to set as Default"
sleep 2
echo "----The StationID is on the first column on the left of each listed Station" 
sleep 2
echo "----Example: KWHP is the StationID for Los Angeles, Whiteman Airport, CA, USA"
sleep 2
echo "----Enter [ h ] for Help, Enter [ q ] to Quit"
sleep 2
echo "----Once you quit you will be asked to enter your 4 Charachter StationID"
echo "${line0}${line0}${line0}######"
echo

read -rp "Press [Enter] to Continue!" -n 1

less ${nsd}

read -rp "Enter your 4 Charachter StationID:" -n 4
echo

statID=$(echo "$REPLY" | tr '[:lower:]' '[:upper:]')

if grep "${statID}" ${nsd} >/dev/null 2>&1; then
	echo "Setting Default StationID"
	sed -i'' "12s/KSBD/${statID}/" ${nw} || 
	{ local message="Failed to set default station in /usr/local/bin/nweather";
	  false; }
else
        { message="StationID not found in current Station List"; false; }
fi

echo "Success: Type nweather for default Station's current conditions
and type nweather -h for a list of options for other stations or locations"
}

station_check "$@"

exit 0
