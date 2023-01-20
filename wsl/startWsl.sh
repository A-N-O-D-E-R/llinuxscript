#!/bin/bash
abspath="$(cd "$(dirname "$0")" && pwd -P)" # Get the Absolute Path of /wsl
envPath="$(cd $(dirname "$0") && pwd -P)/.env" # Get the Absolute Path of .env
chmod +x $abspath/wsl-port-conf.ps1 & $abspath/wsl_params.yaml
chmod +w $envPath
#TODO : ENABLE MIST port
powershell.exe $abspath/wsl-port-conf.ps1 $envPath 8080 #change 8080 to the port to bind
