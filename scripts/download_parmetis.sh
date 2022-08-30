#!/usr/bin/env bash

###########################################################################
### Author:  Panagiotis Velissariou <panagiotis.velissariou@noaa.gov>
###
### Version - 1.0
###
###   1.0 Mon Aug 22 2022
###########################################################################


###====================
# Make sure that the current working directory is in the PATH
[[ ! :$PATH: == *:".":* ]] && export PATH="${PATH}:."


####################
# Get the directory where the script is located
if [[ $(uname -s) == Darwin ]]; then
  readonly scrNAME="$( grealpath -s "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )"
  readonly scrDIR="$(cd "$(dirname "${scrNAME}" )" && pwd -P)"
else
  readonly scrNAME="$( realpath -s "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )"
  readonly scrDIR="$(cd "$(dirname "${scrNAME}" )" && pwd -P)"
fi
####################


####################
# Get the application's root directory
appDIR=${APP_DIR}
if [[ -z "${appDIR}" ]]; then
  for i in ${scrDIR} ${scrDIR}/.. ${scrDIR}/../..
  do
    appDIR=$(find ${i} -maxdepth 1 -type d -iname NEMS)
    if [[ -n ${appDIR:+1} ]]; then
      appDIR="$(cd "$(dirname "${appDIR}" )" && pwd -P)"
      break
    fi
  done
fi
if [[ ! -d ${appDIR} ]]; then
  echo "Couldn't determine the project root directory."
  echo "Got: \"appDIR = ${appDIR}\" which is not a valid directory."
  echo "You might need to set the environment variable APP_DIR before running this script."
  echo "Exiting ..."
  exit 1
fi
####################


####################
# Load the utility functions
lst="${scrDIR:+${scrDIR}/}functions_utilities ${scrDIR:+${scrDIR}/}scripts/functions_utilities functions_utilities"
funcs=
for ilst in ${lst}
do
  if [ -f "${ilst:-}" ]; then
    funcs="${ilst}"
    break
  fi
done

if [ -n "${funcs:+1}" ]; then
  source "${funcs}"
  [ $? -ne 0 ] && exit 1
else
  echo " ### ERROR :: in ${scrNAME}"
  echo "     Cannot load the required file: functions_utilities"
  echo "     Exiting now ..."
  echo
  exit 1
fi

unset ilst funcs
####################


####################
# Make sure that the directory thirdparty_open exists or otherwise create it.
#
thirdparty_open="${appDIR}/thirdparty_open"
makeDIR ${thirdparty_open}
####################


####################
# Clone the ParMetis/Metis libraries into thirdparty_open.
#
pushd ${thirdparty_open} >/dev/null 2>&1
  # Make sure that the parmetis directory is removed
  deleteDIR parmetis

  ### 1) First clone ParMetis
  #git clone https://github.com/KarypisLab/ParMETIS.git parmetis
  git clone https://github.com/pvelissariou1/ParMETIS.git parmetis
  err=$?
  if [ ${err} -ne 0 ]; then
    procError "failed to clone the ParMETIS git repository"
  fi

  ### 2) Second clone GKlib
    git clone https://github.com/KarypisLab/GKlib.git parmetis/GKlib
    err=$?
    if [ ${err} -ne 0 ]; then
      procError "failed to clone the GKlib git repository"
    fi

  ### 3) Third clone Metis
  git clone https://github.com/KarypisLab/METIS.git parmetis/metis
  err=$?
  if [ ${err} -ne 0 ]; then
    procError "failed to clone the METIS git repository"
  fi

  #find parmetis -iname ".git*" -exec rm -rf {} \; >/dev/null 2>&1
popd >/dev/null 2>&1
####################

exit ${err:-0}
