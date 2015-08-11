#!/bin/bash
#===============================================================================
#
#          FILE: nweather
#
#         USAGE: ./nweather
#
#   DESCRIPTION: Small program to retrieve up to date weather information from
#                around the world and display it inside the terminal! 
#           
#       OPTIONS: By default no options it displays info for one station that is set
#                by the user but can also look up current weather conditions for almost
#                any major city in the world!
#  REQUIREMENTS: GNU BASH 4, GNU Coreutils 8.21, GNU Grep 2.20, GNU Wget 1.15
#          BUGS: Currently in development
#         NOTES:
#        AUTHOR: nwmsocal (), nwmsocal702@gmail.com
#  ORGANIZATION: N/A
#       CREATED: 05-31-2015
#      REVISION: 1.1.2
#       LICENSE: GNU GPLv3
#
#
#
#===============================================================================

set -o errtrace
set -o pipefail


#Help screen
function helpfunction () {
echo "Nweather -h (help)"
echo "Usage: nweather [OPTION]... [ARGUMENT]...."
echo "Nweather: Retrieve and display current weather conditions from
the National Weather Service weather stations"
echo 
echo "Mandatory arguments and options:"
echo "-l, -l=city -Mandatory                   Search for City"
echo "-s, -s=state                             Search for state"
echo "-c, -c=country                           Search for Country"
echo "-h, help                                 help screen"
echo 
echo "If no option is selected and program is run by itself it will 
display the default weather conditions for pre set station under
the def variable in line 12 of nweather.sh"
echo "nsd_cccc.txt includes a complete list of all current stations"
echo
echo "If an option is selected the search must include city"
echo "Search arguments which include spaces must be quoted ex:'los angeles'"
echo "if -c option is selected do not abbreviate country ex: 
'united states' is a valid search term 'us' is not"
echo
}


function mainf() {
local def=weather.noaa.gov/pub/data/observations/metar/decoded/KSBD.TXT
local shdir='/usr/local/bin'
local datadir='/var/lib/nweather'
local git='https://raw.githubusercontent.com/nwmsocal702/nweather/master/install.sh' 

if [[ "$PWD" == "$shdir" ]]; then
      [ -e "$datadir/nsd_cccc.txt" ] && local nsd="$datadir/nsd_cccc.txt" &&
      [ -e "$datadir/statelist.txt" ] && local stl="$datadir/statelist.txt" ||
      local fail=1;
else
      [ -e "$PWD/nsd_cccc.txt" ] && local nsd="$PWD/nsd_cccc.txt" &&
      [ -e "$PWD/statelist.txt" ] && local stl="$PWD/statelist.txt" ||
      local fail=1
fi

if [[ "$fail" -eq 1 ]]; then
	echo -n "Error: Cannot locate data files, Would you like to Reinstall? [Y/N] "
	read answer
	if [[ "$answer" =~ ^[y|Y|yes|Yes|YES]{1,3}$ ]]; then
		sudo bash -c "$(wget $git -O -)"
                exit 0
        fi
fi


while getopts ":l:s:c:h" opt
do
	case $opt in
		l)
			city="$OPTARG";;
		s)
			state="$OPTARG";;
		c)
			country="$OPTARG";;
		h)
			helpfunction
			h=mytest;;
		\?)
			echo "Error: Invalid Argument"
			echo "Try nweather -h for additional help"
			exit 0;;
	esac
done

#Figure out state abrehevation

if [[ $state == ??* ]]
then
     state=$(grep -i "$state" $stl | cut -d'=' -f1)
fi

# Find station 4 letter ID and figure out how to search for it using grep.

if
	[[ -n $city && -n $state && -n $country ]]
then
	stationID=$(grep -i "$city" $nsd | grep -i ";$state;" | grep -i ";$country;" | cut -d';' -f1)
elif
	[[ -n $city && -n $state && -z $country ]]
then
	stationID=$(grep -i "$city" $nsd | grep -i ";$state;" | cut -d';' -f1)
elif
	[[ -n $city && -z $state && -z $country ]]
then
	stationID=$(grep -i "$city" $nsd | cut -d';' -f1)
elif
	[[ -n $city && -z $state && -n $country ]]
then
	stationID=$(grep -i "$city" $nsd | grep -i ";$country;" | cut -d';' -f1)
elif
	[[ -z $city && -z $state && -z $country && -z $h ]]
then
	wget -qO- $def
	exit 0
elif
	[[ -n $h ]]
then
	exit 0
else
	echo "Error: Must select a city using the -c option"
	echo "nweather -h for additional help"
	exit
fi

# Load station ID's and download them

for s in $stationID
do
	wget -qO- http://weather.noaa.gov/pub/data/observations/metar/decoded/"$s".TXT && echo -e "\n"
done

# Tell if search found nothing

if
	[ -z "$stationID" ] > /dev/null 2>&1
then
	echo -e "\n"
	echo "Error: Current weather information does not exist for $city"
	exit 1
fi
exit 0
}

mainf "$@"
