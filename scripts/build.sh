#!/bin/bash

###########################################################################
### Author:  Panagiotis Velissariou <panagiotis.velissariou@noaa.gov>
###
### Version - 1.2
###
###   1.2 Sun Mar 06 2022
###   1.1 Wed Apr 14 2021
###   1.0 Fri Dec 04 2020
###########################################################################


###====================
# Make sure that the current working directory is in the PATH
[[ ! :$PATH: == *:".":* ]] && export PATH="${PATH}:."


# Get the directory where the script is located
if [[ $(uname -s) == Darwin ]]; then
  readonly scrNAME="$( grealpath -s "${BASH_SOURCE[0]}" )"
  readonly scrDIR="$(cd "$(dirname "${scrNAME}" )" && pwd -P)"
else
  readonly scrNAME="$( realpath -s "${BASH_SOURCE[0]}" )"
  readonly scrDIR="$(cd "$(dirname "$(realpath -s "${BASH_SOURCE[0]}")" )" && pwd -P)"
fi

lst="${scrDIR}/functions_build ${scrDIR}/scripts/functions_build functions_build "
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
else
  echo " ### ERROR :: in ${scrNAME}"
  echo "     Cannot load the required file: functions_build"
  echo "     Exiting now ..."
  echo
  exit 1
fi

unset ilst funcs
###====================


############################################################
### BEG:: SYSTEM CONFIGURATION
############################################################

# Call ParseArgs to get the user input.
ParseArgs "${@}"

# Set the variables for this script
getNEMSEnvVars ${scrDIR}

# Check if the user supplied valid components
checkNEMSComponents

# Get the compilers to use for this project compilation
getCompilerNames "${COMPILER}"

############################################################
### END:: SYSTEM CONFIGURATION
############################################################


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


############################################################
### BEG:: GET FINAL USER RESPONSE
############################################################

# Get a final user response for the variables
echo
echo "The following variables are defined:"
echo "    CLEAN          = ${CLEAN}"
echo "    COMPILER       = ${COMPILER:-Undefined, Supported values are: [${MY_COMPILING_SYTEMS}]}"
echo "    NEMS_COMPILER  = ${NEMS_COMPILER}"
echo "    NEMS_PARALLEL  = ${PARALLEL:-0}"
echo "    NEMS_PLATFORM  = ${NEMS_PLATFORM}"
echo "    CC             = ${CC:-UNDEF}"
echo "    CXX            = ${CXX:-UNDEF}"
echo "    FC             = ${FC:-UNDEF}"
echo "    F90            = ${F90:-UNDEF}"
echo "    PCC            = ${PCC:-UNDEF}"
echo "    PCXX           = ${PCXX:-UNDEF}"
echo "    PFC            = ${PFC:-UNDEF}"
echo "    PF90           = ${PF90:-UNDEF}"
echo "    MODULES FILE   = ${modFILE}"
echo "    WW3_CONFOPT    = ${WW3_CONFOPT}"
echo "    WW3_COMP       = ${WW3_COMP}"
echo "    WWATCH3_NETCDF = ${WWATCH3_NETCDF}"
echo "    COMPONENTS     = ${COMPONENT:-Undefined, Supported values are: [${MY_COMPONENT_LIST}]}"
echo "    BUILD_EXECS    = ${BUILD_EXECS}"
echo "    OS             = ${OS}"
echo "    PLATFORM       = ${PLATFORM}"
echo "    MACHINE_ID     = ${MACHINE_ID}"
echo "    FULL_MACHINE_ID= ${FULL_MACHINE_ID}"
echo "    BUILD_TARGET   = ${BUILD_TARGET:-${PLATFORM}.${NEMS_COMPILER}}"
echo "    EXTERNALS_NEMS = ${EXTERNALS_NEMS}"
echo "    VERBOSE        = ${VERBOSE}"
echo
echo "    HDF5HOME       = ${HDF5HOME}"
echo "    NETCDFHOME     = ${NETCDFHOME}"
echo "    NETCDF_INCDIR  = ${NETCDF_INCDIR}"
echo "    NETCDF_LIBDIR  = ${NETCDF_LIBDIR}"
echo
echo "    ESMFMKFILE     = ${ESMFMKFILE}"
echo
echo "NOTE: If the parallel compiler names are different in your platform, you may pass one or more"
echo "      of the environment variables: PCC, PCXX, PFC, PF90 to $(basename ${scrNAME}) and run the script as:"
echo "         PCC=yourPCC PCXX=yourPCXX PFC=yourPFC PF90=yourPF90 $(basename ${scrNAME}) [options]"
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

############################################################
### END:: GET FINAL USER RESPONSE
############################################################


############################################################
### BEG:: START THE CALCULATIONS
############################################################

##########
# Compile the project
compileERR=0
pushd ${nemsDIR} >/dev/null 2>&1
  case ${CLEAN:-0} in
    -1 )
      compileNems clean
      compileERR=$?
      ;;
    -2 )
      compileNems distclean
      compileERR=$?
      ;;
    -3 )
      compileNems noclean
      compileERR=$?
      ;;
     * )
      compileNems clean
      compileERR=$?
      ;;
  esac

  if [ ${compileERR} -eq 0 ]; then
    compileNems build
    compileERR=$?
  fi

  if [  ${compileERR} -eq 0 ]; then
    if [ -f exe/NEMS.x ]; then
      cp -p exe/NEMS.x exe/NEMS${compFNAME:+-${compFNAME}}.x
    fi
  fi
popd >/dev/null 2>&1

##########
# Install all data, executables, libraries in a common directory
[ ${compileERR:-0} -eq 0 ] && installNems
##########

exit 0
