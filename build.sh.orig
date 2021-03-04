#!/bin/bash

###########################################################################
### Author:  Panagiotis Velissariou <panagiotis.velissariou@noaa.gov>
###
### Version - 1.0 Fri Dec 04 2020
###########################################################################


###====================
# Make sure that the current working directory is in the PATH
[[ ! :$PATH: == *:".":* ]] && export PATH="${PATH}:."


# Get the directory where the script is located
scrNAME="${BASH_SOURCE[0]}"
if [[ $(uname -s) == Darwin ]]; then
#  readonly scrDIR="$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)"
  readonly scrDIR="$(cd "$(dirname "$(grealpath -s "${scrNAME}" )" )" && pwd -P)"
else
#  readonly scrDIR="$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)"
  readonly scrDIR="$(cd "$(dirname "$(realpath -s "${scrNAME}")" )" && pwd -P)"
fi

funcs="$( find ${scrDIR} -type f -name "functions_build" | head -n 1 )"
if [ -f "${funcs}" ]; then
  source "${funcs}"
else
  echo " ### ERROR :: in ${scrNAME}"
  echo "     Cannot load the required file: ${funcs}"
  echo "     Exiting now ..."
  echo
  exit 1
fi

unset funcs
###====================


#########
# Call ParseArgs to get the user input.
ParseArgs "${@}"


##########
# Set the variables for this script
CLEAN=${MY_CLEAN:-0}

[ -n "${MY_COMPILER:+1}" ] && COMPILER="$( toLOWER "${MY_COMPILER}" )"

[ -n "${MY_COMPONENT:+1}" ] && COMPONENT="${MY_COMPONENT}"

[ -n "${MY_OS:+1}" ] && OS="$( toLOWER "${MY_OS}" )"

[ "${MY_PARMAKE:0}" -gt 1 ] && PARMAKE=${MY_PARMAKE}

[ -n "${MY_PLATFORM:+1}" ] && PLATFORM="$( toLOWER "${MY_PLATFORM}" )"

[ -n "${MY_OS:+1}" ] && OS="$( toLOWER "${MY_OS}" )"

[ -n "${MY_VERBOSE:+1}" ] && VERBOSE="$( toLOWER "${MY_VERBOSE}" )"

mod_file="envmodules${COMPILER:+_${COMPILER}}${PLATFORM:+.${PLATFORM}}"

if [ -n "${COMPONENT:+1}" ]; then
  comp_fname="$( strTrim "$( toLOWER "${COMPONENT}" )" )"
  comp_fname="$( echo "${comp_fname}" | sed 's/ /_/g' )"
fi
##########


##########
# Get the project directories and perform a basic check on them
readonly nemsDIR="${NEMS_DIR:-${scrDIR}/NEMS}"
if [ ! -f "${nemsDIR}/NEMSAppBuilder" ]; then
  echo "The project directory \"${nemsDIR}\" does not appear to contain NEMSAppBuilder."
  echo "Is this the correct NEMS directory?"
  echo "You might need to set the environment variable NEMS_DIR before running this script."
  echo "Exiting ..."
  exit 1
fi

readonly modsDIR="${NEMSMODS_DIR:-${scrDIR}/modulefiles}"
if [ ! -f "${modsDIR}/${mod_file}" ]; then
  echo "The modulefiles directory \"${modsDIR}\" does not appear to contain module: ${mod_file}."
  echo "Is this the correct modulefiles directory?"
  echo "You might need to set the environment variable NEMSMODS_DIR before running this script."
  echo "Exiting ..."
  exit 1
fi
##########


##########
# If the user requested to clean the build folder, do the cleaning end exit
if [ ${CLEAN:-0} -ge 1 ]; then
  echo "User requested to only clean the project. Cleaning ..."

  pushd ${nemsDIR} >/dev/null 2>&1
    [ ${CLEAN:-0} -eq 1 ] && compileNems clean
    [ ${CLEAN:-0} -eq 2 ] && compileNems distclean
  popd >/dev/null 2>&1

  exit 0
fi
##########


##########
# Export some environment variables for NEMS
export NEMS_COMPILER=${COMPILER}

# Source the environment module
source ${modsDIR}/${mod_file}

component_ww3=":$( echo "${COMPONENT}" | sed 's/ /:/g' ):"
if [[ :$component_ww3: == *:"WW3":* ]]; then
  if [ -z "${METIS_PATH}" ]; then
    echo "ERROR :: The METIS_PATH environment variable for WW3 is not set."
    echo "   Set the METIS_PATH environment variable before running this script:"
    echo "     METIS_PATH=\"path_to_compiled_metis\""
    echo "Exiting ..."
    exit 1
  else
    export METIS_PATH="${METIS_PATH}"
  fi
  export WW3_COMP="${COMPILER}"
fi

##########


##########
# Get a final user response for the variables
echo
echo "The following variables are defined:"
echo "    CLEAN          = ${CLEAN}"
echo "    COMPILER       = ${COMPILER:-Undefined, Supported values are: [${MY_COMPILING_SYTEMS}]}"
echo "    NEMS_COMPILER  = ${NEMS_COMPILER}"
echo "    WW3_COMP       = ${WW3_COMP}"
echo "    COMPONENTS     = ${COMPONENT:-Undefined, Supported values are: [${MY_COMPONENT_LIST}]}"
echo "    OS             = ${OS}"
echo "    PLATFORM       = ${PLATFORM}"
echo "    VERBOSE        = ${VERBOSE}"
echo
echo "    METIS_PATH     = ${METIS_PATH}"
echo "    HDF5HOME       = ${HDF5HOME}"
echo "    NETCDFHOME     = ${NETCDFHOME}"
echo "    NETCDF_INCDIR  = ${NETCDF_INCDIR}"
echo "    NETCDF_LIBDIR  = ${NETCDF_LIBDIR}"
echo
echo "    ESMFMKFILE     = ${ESMFMKFILE}"
echo

module list

echo_response=
while [ -z "${echo_response}" ] ; do
  echo -n "Are these values correct? [y/n]: "
  read echo_response
  echo_response="$( getYesNo "${echo_response}" )"
done

if [ "${echo_response:-no}" = "no" ]; then
  echo
  echo "User responded: ${echo_response}"
  echo "Exiting now ..."
  echo
  exit 1
fi

unset echo_response
##########


############################################################
### START THE CALCULATIONS
############################################################

##########
# Compile the project
pushd ${nemsDIR} >/dev/null 2>&1
  case ${CLEAN:-0} in
    -1 )
      compileNems clean
      err=$?
      ;;
    -2 )
      compileNems distclean
      err=$?
      ;;
    -3 )
      compileNems noclean
      err=$?
      ;;
     * )
      compileNems clean
      err=$?
      ;;
  esac

  if [ ${err} -eq 0 ]; then
    compileNems build
    err=$?
  fi

  if [  ${err} -eq 0 ]; then
    if [ -f exe/NEMS.x ]; then
      cp -p exe/NEMS.x exe/NEMS${comp_fname:+-${comp_fname}}.x
    fi
  fi
popd >/dev/null 2>&1

exit 0
