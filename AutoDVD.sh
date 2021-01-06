#!/usr/bin/env bash

unmountAfterReading=true  # unmount disk drive automatically for quicker disk swap
diskAutodetect=true       # can only be used if unmountAfterReading=true
titleMinlength=300        # 300 seconds = 5 minutes

prefix="[\e[36mAutoDVD\e[0m] "
workingPath="/home/$(whoami)/.AutoDVD"
packages=("coreutils" "makemkv-bin" "makemkv-oss" "util-linux")

if readlink /proc/$$/exe | grep -q "dash"; then
	echo -e "${prefix}Please run this script with bash."
	exit
fi


# functions

function ln ()
{
  echo -e "${prefix}${1}"
}

function br ()
{
  echo ""
}

function error ()
{
  br
  ln "\e[31mERROR\e[0m> ${1}"
  br
  exit
}

function warning ()
{
  ln "\e[33mWARNING\e[0m> ${1}"
}

function banner ()
{
  br
  br
  echo "  █████╗ ██╗   ██╗████████╗ ██████╗     ██████╗ ██╗   ██╗██████╗ "
  echo " ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗    ██╔══██╗██║   ██║██╔══██╗"
  echo " ███████║██║   ██║   ██║   ██║   ██║    ██║  ██║██║   ██║██║  ██║"
  echo " ██╔══██║██║   ██║   ██║   ██║   ██║    ██║  ██║╚██╗ ██╔╝██║  ██║"
  echo " ██║  ██║╚██████╔╝   ██║   ╚██████╔╝    ██████╔╝ ╚████╔╝ ██████╔╝"
  echo " ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝     ╚═════╝   ╚═══╝  ╚═════╝ "
  br
  echo " ----------------------------------------------------------------"
  br
  echo "                      by Oliver Vollborn                         "
  echo "                  `tput smul`https://github.com/vollborn`tput rmul`"
  br
  warning "Copying DVDs may be `tput bold`\e[31millegal\e[0m`tput sgr0` in your country."
  warning "Please check your legal boundaries before using AutoDVD."
  warning "I do not take responsibilty for your actions."
  br
}

function prompt ()
{
  if [[ -n ${1} ]]; then
    printf "[${1}]» "
  else
    printf "» "
  fi
}

function readPrompt ()
{
  read input
  if [[ ! -n ${input} ]]; then
    echo ${1}
  else
    echo ${input}
  fi
}

function pause()
{
   read -s -n 1
}

function checkRoot ()
{
  rootTest=$(sudo echo "success")
  if [[ ! "${rootTest}" == "success" ]]; then
    error "Please run this script as root."
  fi
  ln "Sudo check completed."
}

function checkRequiredPackages ()
{
  for index in "${packages[@]}"; do
    $(dpkg -s ${index} &> /dev/null) || echo "missing"
  done
}

function checkPackages ()
{
  if [[ ! -n $(checkRequiredPackages) ]]; then
    ln "All dependencies are installed."
  else
    br
    ln "Some dependencies need to be installed."

    ln "Adding repositories..."
    sudo add-apt-repository -y ppa:heyarje/makemkv-beta &> /dev/null
    sudo apt-get update &> /dev/null

    ln "Installing packages..."
    sudo apt-get install -y ${packages[@]} &> /dev/null

    ln "Checking installation..."
    if [[ ! -n $(checkRequiredPackages) ]]; then
      ln "Installation succeeded!"
      br
    else
      error "Installation failed."
    fi
  fi
}

function cleanTemporaryDirectory ()
{
  sudo rm -r ${tmpPath}/*.* &> /dev/null
}

function createTemporaryDirectory ()
{
  # Create working directory
  if [[ ! -d ${workingPath} ]]; then
    sudo mkdir ${workingPath} &> /dev/null
    if [[ ! -d ${workingPath} ]]; then
      error "Working directory \"${workingPath}\" could not be created."
    fi
  fi

  # Specify and create tmpPath
  tmpPath="${workingPath}/${driveName}"
  if [[ -d ${tmpPath} ]]; then
    cleanTemporaryDirectory
  else
    sudo mkdir ${tmpPath} &> /dev/null
    if [[ ! -d ${tmpPath} ]]; then
      error "Temporary directory \"${tmpPath}\" could not be created."
    fi
  fi
}

function checkUnmountAfterReading ()
{
  if ${unmountAfterReading}; then
    ln "The drive will be automatically unmounted after reading."
  fi
}

function checkTitleMinlength ()
{
  [[ ${titleMinlength} -eq 0 ]] && titleMinlength=0 # 0 if value is invalid

  if [[ ${titleMinlength} -eq 1 ]]; then
    ln "The minimal title length is set to 1 second."
  else
    ln "The minimal title length is set to ${titleMinlength} seconds."
  fi
}

function validateUser ()
{
  if id -u "${1}" &> /dev/null; then
    echo "1"
  else
    if [[ ${1} == *:* ]]; then
      name=$(echo ${1} | cut -d":" -f2)
      group=$(echo ${1} | cut -d":" -f1)
      if id -u "${name}" &> /dev/null; then
        if id -g "${group}" &> /dev/null; then
          echo "1"
          return
        fi
      fi
    fi
  fi
}

function hasDrive ()
{
  drives=$(lsblk | grep "rom" | cut -d" " -f1)
  for i in ${drives}; do
    if [[ "${i}" == "${1}" ]]; then
      echo "exists"
      break
    fi
  done
}

function beep ()
{
  echo -en "\a" #> /dev/tty5
}

function setDrivePath ()
{
  defaultDriveName=$(lsblk | grep "rom" | cut -d" " -f1 | cut -d$'\n' -f1)

  br
  ln "Please specify your DVD drive name."
  while [[ ! -n $(hasDrive "${driveName}") ]]; do
    if [[ -n ${driveName} ]]; then
      ln "This drive does not exist."
    fi
    prompt ${defaultDriveName}
    driveName=$(readPrompt ${defaultDriveName})
  done
  
  drivePath="/dev/${driveName}"
}

function setDestinationPath ()
{
  defaultDestinationPath="/media"

  br
  ln "Please specify the path to your destination directory."
  while [[ ! -d ${destinationPath} ]]; do
    if [[ -n ${destinationPath} ]]; then
      ln "This directory does not exist."
    fi
    prompt ${defaultDestinationPath}
    destinationPath=$(readPrompt ${defaultDestinationPath})
  done
}

function setMediaOwner()
{
  defaultOwner=$(whoami)

  br
  ln "Please specify a user who should own the created files."
  while [[ ! -n $(validateUser "${owner}") ]]; do
    if [[ -n ${owner} ]]; then
      ln "This user does not exist."
    fi
    prompt ${defaultOwner}
    owner=$(readPrompt ${defaultOwner})
  done
}

function performDiskAutodetect ()
{
  br
  ln "Please insert a new disk."
  while [[ ! -n ${mountedPath} ]]; do
    mountedPath=$(mount | grep ${drivePath} | cut -d" " -f3)
    printf "."
    sleep 1s
  done
  br
  br
}

function performWaitForDisk ()
{
  while [[ ! -n ${mountedPath} ]]; do
    ln "Please insert a DVD and continue by pressing any key."
    pause
    mountedPath=$(mount | grep ${drivePath} | cut -d" " -f3)
    if [[ ! -n ${mountedPath} ]]; then
      ln "Mount point cannot be found."
      br
    fi
  done
}


# program start

banner

checkRoot
checkPackages
checkUnmountAfterReading
checkTitleMinlength

setDrivePath
setDestinationPath
setMediaOwner

createTemporaryDirectory

br
ln "Configuration completed."
br
ln "Drive Path        »  ${drivePath}"
ln "Destination Path  »  ${destinationPath}"
ln "Media Owner       »  ${owner}"
br


# main loop

counter=0
while true; do
  counter=$((${counter}+1))

  if ${diskAutodetect} && ${unmountAfterReading}; then
    performDiskAutodetect
  else
    performWaitForDisk
  fi
  
  mountedBasename=$(basename ${mountedPath})

  ln "Disk ${counter}: ${mountedPath}"
  ln "Please specify the name of this DVD."
  prompt ${mountedBasename}
  diskName=$(readPrompt ${mountedBasename})

  destination="${destinationPath}/${diskName}.mkv"
  if [[ -f $destination ]]; then
    br
    warning "${destination} does already exist."
    warning "The file will get overwritten after reading the DVD."
    br
  fi

  ln "Reading DVD..."
  ln "This may take a while."
  br
  sudo makemkvcon --minlength=${titleMinlength} mkv dev:${drivePath} all ${tmpPath}
  br

  ln "Moving created file..."
  largestFile=$(find ${tmpPath} -maxdepth 1 -printf '%s %p\n' | sort -nr | head -n 1 | cut -d" " -f2-) # Assuming the largest title is the actual movie
  if [[ "${largestFile}" == "${tmpPath}" ]]; then
    error "Title file could not be found"
  fi
  sudo mv "${largestFile}" "${destination}"

  if [[ ! -f ${destination} ]]; then
    error "Output file could not be created."
  fi

  ln "Set file owner..."
  sudo chown ${owner} "${destination}"

  ln "${mountedBasename} saved to ${destination}"

  if ${unmountAfterReading}; then
    ln "Unmounting ${mountedPath}..."
    umount "${mountedPath}"
    sleep 2s # wait for unmounting
  fi

  mountedPath=""
  cleanTemporaryDirectory

  beep
done
