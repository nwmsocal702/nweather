#!/bin/bash

# Get informtion getopts: basically just saves output of different command line switch arguments into variables

# Default setting no args if you already know stationID
def=weather.noaa.gov/pub/data/observations/metar/decoded/KSBD.TXT

#Help screen

helpfunction () {
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
the def variable"
echo "nsd_cccc.txt includes a complete list of all current stations"
echo
echo "If an option is selected the search must include city"
echo "Search arguments which include spaces must be quoted ex:'los angeles'"
echo "if -c option is selected do not abbreviate country ex: 
'united states' is a valid search term 'us' is not"
echo
}


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

if [[  $state == ??* ]]
then
     state=$(grep -i "$state" statelist.txt | cut -d'=' -f1)
fi

# Find station 4 letter ID and figure out how to search for it using grep.

if
	[[ -n $city && -n $state && -n $country ]]
then
	stationID=$(grep -i "$city" nsd_cccc.txt | grep -i ";$state;" | grep -i ";$country;" | cut -d';' -f1)
elif
	[[ -n $city && -n $state && -z $country ]]
then
	stationID=$(grep -i "$city" nsd_cccc.txt | grep -i ";$state;" | cut -d';' -f1)
elif
	[[ -n $city && -z $state && -z $country ]]
then
	stationID=$(grep -i "$city" nsd_cccc.txt | cut -d';' -f1)
elif
	[[ -n $city && -z $state && -n $country ]]
then
	stationID=$(grep -i "$city" nsd_cccc.txt | grep -i ";$country;" | cut -d';' -f1)
elif
	[[ -z $city && -z $state && -z $country && -z $h ]]
then
	curl $def
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
	curl -sf http://weather.noaa.gov/pub/data/observations/metar/decoded/"$s".TXT && echo -e "\n"
done

# Tell if search found nothing

if
	[ -z $stationID ] > /dev/null 2>&1
then
	echo -e "\n"
	echo "Error: Current weather information does not exist for $city"
	exit
fi
