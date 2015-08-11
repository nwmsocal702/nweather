#!/bin/bash
# Nweather Version 1.0
# Date 5-31-2015
# Dependencies GNU BASH Version 4.3, GNU Coreutils 8.21, GNU Grep 2.20, GNU Wget 1.15
# Nweather is an application to retrieve up to date weather information from around the world!


set -o errtrace
set -o pipefail
export nsd
export stl


# Check where nweather is installed amd if data files are found
function first_check() {
local data_dir=/var/lib
local sh_dir=/usr/local/bin

if [[ "${PWD}" == ${sh_dir}/nweather ]]; then
	[[ -s "${data_dir}/nsd_cccc.txt" ]] && 
        [[ -s "${data_dir}/statelist.txt" ]] && val1=1	
	
else
	[[ -s "$PWD/nsd_cccc.txt" ]] &&
	[[ -s "$PWD/statelist.txt" ]] && val2=1
fi

if [[ -n "$val1" || -n "$val2" ]]; then
	:
elif [[ -n "$val1" ]]; then
	nsd="/var/lib/nweather/nsd_cccc.txt"
	stl="/var/lib/nweather/statelist.txt"
elif [[ -z "$val1" && -n "$val2" ]]; then
	nsd="nsd_cccc.txt"
	stl="statelist.txt"
else
	echo "Error: nsd_cccc.txt/statelist.txt Files not found!"
	echo 'To install: sudo bash -c "$(wget https://raw.githubusercontent.com/nwmsocal702/nweather/master/install.sh -O -)"' 
	exit 1
fi

}

	
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
first_check "$@"
local def=weather.noaa.gov/pub/data/observations/metar/decoded/KSBD.TXT

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
