Nweather
========
5-31-2105

INTRODUCTION
This is Nweather, version 1.1.2 This utility is designed to download and read up to date weather information from around the world and display it in terminal. This data is retrieved from the National Oceanic and Atmospheric Administration. Each weather station has a four letter ID for access.

DEPENDENCIES required: GNU BASH Version 4.3.30, GNU Coreutils 8.21, Grep 2.20, Wget 1.15 and Curl 7.37.1
Also Required is the station ID List (nsd_cccc.txt) and the statelist file (statelist.txt). Both are readily available at https://github.com/nwmsocal702/nweather.

##INSTALL

#### Via Wget
`sudo bash -c "$(wget https://raw.githubusercontent.com/nwmsocal702/nweather/master/install.sh -O -)"`

#### Via Curl
`sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/nwmsocal702/nweather/master/install.sh)"` 



INSTALLATION: To Download go to https://github.com/nwmsocal702/nweather. Default installation using the install script downloades and installs nweather to /usr/local/bin and the data files to /var/lib. But nweather will also work if nweather.sh and nsd_cccc.txt and statelist.txt are in the same directory. I also recommend changing the default station ID which is set in the def variable on line 12 in the nweather script and replace the four letter stationid KSBD with the station ID of the station closest to you. You can find your stationID by searching the stationlist ID file nsd_cccc.txt.
For best practice and ease of use, if not installing nweather inside your PATH I set an alias in my .bashrc for nweather
like this: alias weather='bash ~/nweather.sh' 

##OPERATING INSTRUCTIONS
Usage: nweather [OPTION]... {ARGUMENT}....

Nweather has the following options

`-l, -l=city Mandatory        Search for city`
`-s, -s=state                 Search for state`
`-c, -c=country               Search for Country`
`-h, -h=help                  Help screen`

If no option is selected and script is run by itself it will display the default weather conditions for a single pre set station under the def variable in the script which is the weather station closest to me the author.
If an option is selected the search must include a city option.
`ex: nweather -l riverside is valid`
`ex: nweather -l riverside -s ca is valid`
`ex: nweather -l "los angeles" -s ca -c "united states" is valid`
`ex: "nweather -s ca"  and "nweather -c usa" are both invalid`
Also if the -c option is selected do not abbreviate country
`ex: "united states" is a valid search term "us" is not.`
Search arguments which include spaces must be qouted
`ex: "los angeles" is a valid search term whereas los angeles is not.`

##LICENSING
This is FREE software licensed under the GNU GENERAL PUBLIC LICENSE Version 3.  http://www.gnu.org/licenses/gpl-3.0.html 

##QUESTIONS
To contact the developer for further questions,feature requests, feedback or to submit a bug report email nwmsocal702@gmail.com


