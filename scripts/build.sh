#!/usr/bin/env bash

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


####################
# Get the directory where the script is located
if [[ $(uname -s) == Darwin ]]; then
#  readonly scrDIR="$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )" )" && pwd -P)"
  readonly scrNAME="$( grealpath -s "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )"
  readonly scrDIR="$(cd "$(dirname "${scrNAME}" )" && pwd -P)"
else
#  readonly scrDIR="$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" )" )" && pwd -P)"
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
lst="${scrDIR:+${scrDIR}/}functions_build ${scrDIR:+${scrDIR}/}scripts/functions_build functions_build"
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
  echo "     Cannot load the required file: functions_build"
  echo "     Exiting now ..."
  echo
  exit 1
fi

unset ilst funcs
####################


####################
# Check if the module command exists
checkModuleCmd
####################

############################################################
### BEG:: SYSTEM CONFIGURATION
############################################################

# Call ParseArgs to get the user input.
ParseArgs "${@}"

# Set the variables for this script
getNEMSEnvVars ${appDIR}

# Check if the user supplied valid components
checkNEMSComponents

# Get the compilers to use for this project compilation
getCompilerNames "${COMPILER}"

# Get the list of the third party components to build
getThirdParty
############################################################
### END:: SYSTEM CONFIGURATION
############################################################

##########
# If the user requested to clean the build folder, do the cleaning end exit
compileERR=0
if [ ${CLEAN:-0} -ge 1 ]; then
  echo "User requested to only clean the project. Cleaning ..."

  pushd ${NEMS_DIR} >/dev/null 2>&1
    case ${CLEAN:-0} in
      1)
       compileNems clean
       compileERR=$?
       exit ${compileERR}
       ;;
      2)
       compileNems distclean
       compileERR=$?
       exit ${compileERR}
       ;;
      *)
       ;; #Do Nothing
    esac
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
echo "    APP_DIR        = ${APP_DIR}"
echo "    ACCEPT_ALL     = ${ACCEPT_ALL}"
echo "    CLEAN          = ${CLEAN}"
echo "    COMPILER       = ${COMPILER}"
echo "    NEMS_COMPILER  = ${NEMS_COMPILER}"
echo "    NEMS_PARALLEL  = ${PARALLEL}"
echo "    NEMS_PLATFORM  = ${NEMS_PLATFORM}"
echo "    NEMS_DIR       = ${NEMS_DIR}"
echo "    CC             = ${CC}"
echo "    CXX            = ${CXX}"
echo "    FC             = ${FC}"
echo "    F90            = ${F90}"
echo "    PCC            = ${PCC}"
echo "    PCXX           = ${PCXX}"
echo "    PFC            = ${PFC}"
echo "    PF90           = ${PF90}"
echo "    MODULES FILE   = ${modFILE}"
echo "    WW3_CONFOPT    = ${WW3_CONFOPT}"
echo "    WW3_COMP       = ${WW3_COMP}"
echo "    WWATCH3_NETCDF = ${WWATCH3_NETCDF}"
echo "    COMPONENTS     = ${COMPONENT}"
echo "    THIRDPARTY     = ${THIRDPARTY}"
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
echo "    NETCDF_CONFIG  = ${NETCDF_CONFIG}"
echo
echo "    ESMFMKFILE     = ${ESMFMKFILE:-UNDEF}"
echo
echo "NOTE: If the parallel compiler names are different in your platform, you may pass one or more"
echo "      of the environment variables: PCC, PCXX, PFC, PF90 to $(basename ${scrNAME}) and run the script as:"
echo "         PCC=yourPCC PCXX=yourPCXX PFC=yourPFC PF90=yourPF90 $(basename ${scrNAME}) [options]"
echo

[ ${modulecmd_ok:-0} -ge 1 ] && module list

if [ ${ACCEPT_ALL:-0} -le 0 ]; then
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
else
  echo "User accepted all settings."
  sleep 2
fi

############################################################
### END:: GET FINAL USER RESPONSE
############################################################


############################################################
### BEG:: START THE CALCULATIONS
############################################################

###========================================
### BEG :: install thirdparty_open libraries and programs
### First compile thirdparty libraries if requested by the user or,
### use the environment variables DATETIMEHOME, PARMETISHOME, ...
### if they are set. If a thirdparty library was explicitly requested
### vi -tp option then try to compile the library from the thirdparty_open
### and ignore the environment.
###========================================
compileDateTime
  compileERR=$(( ${compileERR:-0} + $? ))

compileMetis
  compileERR=$(( ${compileERR:-0} + $? ))
###========================================
### END :: install thirdparty_open libraries and programs
###========================================


###========================================
### BEG :: Compile the project
### This part of the code is executed only if the user supplied
### valid model or data components to be compiled into the NEMS application.
###========================================
if [ -n "${COMPONENT:+1}" ]; then
  compileERR=0
  pushd ${NEMS_DIR} >/dev/null 2>&1
    case ${CLEAN:-0} in
      -1)
        compileNems clean
        compileERR=$(( ${compileERR:-0} + $? ))
        ;;
      -2)
        compileNems distclean
        compileERR=$(( ${compileERR:-0} + $? ))
        ;;
      -3)
        compileNems noclean
        compileERR=$(( ${compileERR:-0} + $? ))
        ;;
       *)
         ;; #Do Nothing
    esac

    if [ ${compileERR} -eq 0 ]; then
      compileNems build
      compileERR=$(( ${compileERR:-0} + $? ))
    fi

    if [  ${compileERR} -eq 0 ]; then
      if [ -f exe/NEMS.x ]; then
        cp -p exe/NEMS.x exe/NEMS${compFNAME:+-${compFNAME}}.x
        compileERR=$(( ${compileERR:-0} + $? ))
      fi
    fi
  popd >/dev/null 2>&1

  ##########
  # Install all data, executables, libraries in a common directory
  if [  ${compileERR} -eq 0 ]; then
    installNems
    compileERR=$(( ${compileERR:-0} + $? ))
  fi
fi
###========================================
### END :: Compile the project
###========================================


exit ${compileERR:-0}
