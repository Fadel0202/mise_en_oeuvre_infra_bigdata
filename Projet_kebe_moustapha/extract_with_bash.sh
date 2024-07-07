#!/usr/bin/bash

time_shell=$(date +"%Y-%m-%dT%H-%M-%S+00:00")
url="http://api.openweathermap.org/data/2.5/air_pollution"
#les coordonnées de Paris
LATITUDE=48.8534
LONGITUDE=2.3488
#les timestamps UNIX (temps en secondes depuis le 1er janvier 1970)
START_TIME=1606223802
END_TIME=1606482999
API_KEY="9e10cb40d36accd025b6480ca50ddf8e"
wget -O "Current_air_pollution_data_paris_${time_shell}.json" "${url}?lat=${LATITUDE}&lon=${LONGITUDE}&start=${START_TIME}&end=${END_TIME}&appid=${API_KEY}"
