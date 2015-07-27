#!/bin/bash
#Script to install nweather program on Linux

# -E: ERR trap is inherited by shell functions
set -o errtrace
# -u: Treat unset variables as an error when substituting
set -o nounset
# If any command in a pipeline fails, that will be used as return code of whole pipeline
set -o pipefail 


err_handler ()
{
	local PROGNAME=$(basename "$0")              # Equals script name stripped of path
	local LINENUM=${1:-"Unknown line"}         # Argument 1: last line of error occurance
	local ERRSTATUS=${2:-$?}                   # Code of last command defaults to 1 if unset
	local message=${message:-"Unknown Error"}  # Sets default for local variable message

	echo "" 1>&2
	echo "Error: ${message}" 1>&2
	echo  "${PROGNAME}: line ${LINENUM}: exit status:${ERRSTATUS}" 1>&2
	exit ${ERRSTATUS}
}

# Trap on ERR and run function err_handler which checks status
# prints line number and shows unique error message for each error
trap 'err_handler ${LINENO} $?' ERR


# Check if root if not give user a chance to enter password
# through sudo and restart script if not exit
if [ $EUID -ne 0 ]; then
	echo "Warning: you must be root to run this script!"
	sudo -k
	exec sudo "$0" "$@"
fi


# Function to ask user to quit if old version of Bash detected
ask () 
{
	read -rp "$1"
	case $(echo "$REPLY" | tr 'A-Z' 'a-z') in
		y|yes) :
			;;
		*)     message="User terminated installation!"
		       false
		       ;;
       esac
}


# Check if BASH if not exit
if [ "$(basename "$SHELL")" != bash ]; then
	message="SHELL is not BASH!"
	false
fi


# Check BASH Version and print Warning message if old Bash
line0="################"
echo "${line0} Checking BASH Version number ${line0}" 
bash=${BASH_VERSION%.*}
BVERSION=${bash%.*}

if [ "$BVERSION" -le 3 ]; then
	echo "${line0} WARNING ${line0}"
	echo -n "Old version of BASH detected, version:${bash} "
	echo "needs to be updated for complete compatibility with Nweather!"
	echo -n "Download and compile the latest version of bash " 
	echo "from ftp://ftp.cwru.edu/pub/bash/bash-4.3.tar.gz"

	ask "Continue with installation [Y/N]:"
else
	echo "BASH version: ${bash} is up to date!"
fi

# Check if Dependencies (Wget, Tar, sha256sum) are installed 
declare -a notinstalled
declare -a programs=(wget tar sha256sum) 

echo "${line0} Checking for dependencies ${line0}" 

for app in  "${programs[@]}"; do
if ${app} -v > /dev/null 2>&1 || ${app} --version > /dev/null 2>&1; then
	echo "Success: ${app} is already installed"
else
	 notinstalled=("${notinstalled[@]-}" "${app}")
	 echo "Warning: ${app} is not installed"
fi
done


# Function to install dependencies
installdep () 
{
	for prog in "${notinstalled[@]}"; do
		echo "Installing ${prog} from ${tool} repository"
		${1} -y install ${prog} > /dev/null 2>&1 &&
		echo "Successfully installed dependency - ${prog}" ||
		{ message="Installing ${prog} Failed"; false; }
	done
}


# Function to check OS Type and install dependencies
DISTROTYPE=$(cat /etc/*-release | grep "PRETTY_NAME" | grep -Eo '".*"' | tr -d '""')
echo "${line0} Checking Distro Version ${line0}" 
echo "${DISTROTYPE}"
echo -e "${OSTYPE}""\n"
echo "${line0} Checking Dependencies ${line0}"

if (( "${#notinstalled[@]}" )) ; then
	echo "${#notinstalled[@]} dependencies needed for installation"

        if  apt-get --version > /dev/null 2>&1 ; then
	         tool="apt-get"
	         installdep "apt-get" || { message="apt-get failed to install dependencies!"; false; }

        elif  yum --version > /dev/null 2>&1 ; then
	         tool="yum"
                 installdep "yum" || { message="yum failed to install dependencies!"; false; }	

        elif [ "${#notinstalled[@]}" -ge 1 ]; then
	         message="install ${notinstalled[*]} and restart installation!"
	         false
        fi
else
	echo "Dependencies are already installed!"
fi


# Download data from github/noaa and untar
website="https://github.com/nwmsocal702/nweather/archive/master.tar.gz"
website1="weather.noaa.gov/data/nsd_cccc.txt"

[ -d ~ ] && cd ~ > /dev/null 2>&1 || { message="Could not locate home directory"; false; }

echo "${line0}Downloading Nweather from Github.com ${line0}"
wget -q ${website}; status1=$?

wget -q ${website1}; status2=$?

if (( status1+status2 )) ; then 
	message="Downloading source package of Nweather from Github"
	false
else
	echo "Successfully Downloaded Nweather source package from Github.com"
fi

# Untar
echo "Unpacking Nweather source package in Home Directory!"
[ -d ~/nweather ] || mkdir ~/nweather && tar -xzf master.tar.gz -C nweather \
 --strip-components 1 > /dev/null 2>&1  || 
{ message="Unpacking Nweather Source package to Home Directory!"; false; }

echo "Successfully unpacked Nweather to Home Directory!"


# Test Hashes of files

echo "${line0} Checking sha256 Hashes ${line0}" 
nweathersum='3d4f086118434975ce8096d7822348a4ae14efd12dcf87c2d5f743cc764df778'
statelistsum='14f624a6791200c440b7cbf5607113826d1dad3509935e7f781d39656ba27b74'

shsum=$(sha256sum ~/nweather/nweather.sh | cut -d' ' -f1) || { message="Calculating sha256 Hash of nweather.sh"; false; }
statesum=$(sha256sum ~/nweather/statelist.txt | cut -d' ' -f1) || { message="Calculating sha256 Hash of statelist.txt"; false; }

if [ "${shsum}" = "${nweathersum}" ]; then
echo "Success: Hash matches for nweather.sh"
else
message="Hash does not match for nweather.sh"
false
fi

if [ "${statesum}" = "${statelistsum}" ]; then
echo "Success: Hash matches for statelist.txt"
else
message="Hash does not match for statelist.txt"
false
fi



# Install files 
sh_dir='/usr/local/bin'
data_dir='/var/lib'

if [ -d ${sh_dir} ] && [ -d ${data_dir} ]; then
	echo "${line0} Copying installation files ${line0}"
else
	echo "Either ${sh_dir} or ${data_dir} doesnt exist"
fi

[ -d ${data_dir}/nweather ] || mkdir ${data_dir}/nweather > /dev/null 2>&1 && 
chmod -R 755 ${data_dir}/nweather > /dev/null 2>&1   || 
{ message="Creating installation directory in ${data_dir}"; false; }

\cp ~/nweather/statelist.txt  ${data_dir}/nweather > /dev/null 2>&1   && 
\cp ~/nweather/nweather.sh ${sh_dir}/nweather > /dev/null 2>&1 || 
{ message="Failed to copy files to installation Directory."; false; }

echo "Success: Installing files"
chmod 755 ${sh_dir}/nweather ${data_dir}/nweather/* || { message="Failed to set permissions"; false; }
echo "Success: Installing files and setting permissions"
echo "${line0} Installation complete ${line0}"


trap - EXIT
exit 0
