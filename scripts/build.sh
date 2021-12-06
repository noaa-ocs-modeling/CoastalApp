#!/bin/bash

###########################################################################
### Author:  Panagiotis Velissariou <panagiotis.velissariou@noaa.gov>
###
### Version - 1.1
###
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


#########
# Call ParseArgs to get the user input.
ParseArgs "${@}"


##########
# Set the variables for this script
CLEAN=${MY_CLEAN:-0}

[ -n "${MY_COMPILER:+1}" ] && COMPILER="$( toLOWER "$( basename "${MY_COMPILER}" )" )"

[ -n "${MY_COMPONENT:+1}" ] && COMPONENT="$( toUPPER "${MY_COMPONENT}" )"

PARALLEL=${MY_PARALLEL:-1}

BUILD_EXECS="${MY_EXECUTABLES}"

[ -n "${MY_OS:+1}" ] && OS="$( toLOWER "${MY_OS}" )"

if [ -n "${MY_PLATFORM:+1}" ]; then
  PLATFORM="$( toLOWER "${MY_PLATFORM}" )"
else
  PLATFORM="${OS}"
fi

[ "${MY_PARMAKE:0}" -gt 1 ] && PARMAKE=${MY_PARMAKE}

[ -n "${MY_VERBOSE:+1}" ] && VERBOSE="$( toLOWER "${MY_VERBOSE}" )"

modFILE="envmodules${COMPILER:+_${COMPILER}}${PLATFORM:+.${PLATFORM}}"
##########


##########
# Customizations and environment variables for NEMS and other models
export BUILD_EXECS="${BUILD_EXECS}"

# Customize the NEMS.x filename to include the component names
if [ -n "${COMPONENT:+1}" ]; then
  compFNAME="$( strTrim "$( toLOWER "${COMPONENT}" )" )"
  compFNAME="$( echo "${compFNAME}" | sed 's/ /_/g' )"
fi

# Export some important environment variables for NEMS and for other models
export NEMS_COMPILER=${COMPILER}
export NEMS_PARALLEL=${PARALLEL}
export NEMS_PLATFORM=${PLATFORM}
export MACHINE_ID=${PLATFORM}
export FULL_MACHINE_ID=${PLATFORM}

# This used in NEMS to get the configuration flags for the chosen compiler
# in the top level conf directory. Supported OSes are linux and macosx.
# Sometimes we might need to specify special flags not founf in the default
# files for s pecific platform
if [ ! -f "conf/configure.nems.${FULL_MACHINE_ID}.${NEMS_COMPILER}" ]; then
  export BUILD_TARGET=${OS}.${NEMS_COMPILER}
fi

if [ ! -f "conf/externals.nems.${FULL_MACHINE_ID}" ]; then
  export EXTERNALS_NEMS="externals.nems"
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

readonly modDIR="${NEMSMODS_DIR:-${scrDIR}/modulefiles}"
if [ ! -f "${modDIR}/${modFILE}" ]; then
  echo
  echo "The modulefiles directory \"${modDIR}\" does not appear to contain the module file: ${modFILE}."
  echo "Is this the correct \"modulefiles\" directory?"
  echo "You might need to set the environment variable \"NEMSMODS_DIR\" to point to a custom modulefiles directory before running this script."
  echo "Exiting ..."
  echo
  exit 1
else
  # Source the environment module
  source ${modDIR}/${modFILE}
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
# Get the compilers to use for this project compilation
case "${COMPILER}" in
  gnu)
     CC=gcc
     CXX=g++
     FC=gfortran
     F90=gfortran
     PCC=${PCC:-mpicc}
     PCXX=${PCXX:-mpicxx}
     PFC=${PFC:-mpif90}
     PF90=${PF90:-${PFC}}
     ;;
  intel)
     CC=icc
     CXX=icpc
     FC=ifort
     F90=ifort
     PCC=${PCC:-mpiicc}
     PCXX=${PCXX:-mpiicpc}
     PFC=${PFC:-mpiifort}
     PF90=${PF90:-${PFC}}
     ;;
  pgi)
     CC=pgcc
     CXX=pgc++
     FC=pgfortran
     F90=pgfortran
     PCC=${PCC:-pgcc}
     PCXX=${PCXX:-pgc++}
     PFC==${PFC:-pgfortran}
     PF90=${PF90:-${PFC}}
     ;;
  *) # No defaults. Give the user the option to define the environment variables
     # CC, CXX, FC, F90 before running this script.
     #echo "WARNING: The supplied compiling system \"${COMPILER}\", is not suported."
     #echo "         Supported systems are anyone of: compiling_system=[${MY_COMPILING_SYTEMS}]"
     #echo "         Use: --compiler=compiling_system."
     #echo "         Will continue with OS defaults."
     CC=${CC:-}
     CXX=${CXX:-}
     FC=${FC:-}
     F90=${F90:-}
     PCC=${CC:-}
     PCXX=${CXX:-}
     PFC=${FC:-}
     PF90=${F90:-}
     ;;
esac

export CC CXX FC F90 PCC PCXX PFC PF90
##########


##########
component_ww3="$( echo "${COMPONENT}" | sed 's/ /:/g' )"
if [[ :${component_ww3}: == *:"WW3":* ]]; then
  export WW3_CONFOPT="${COMPILER}"
  export WW3_COMP="${COMPILER}"
  export WWATCH3_NETCDF=NC4
fi
##########


##########
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
if [[ :${component_ww3}: == *:"WW3":* ]]; then
  echo "    WW3_CONFOPT    = ${WW3_CONFOPT}"
  echo "    WW3_COMP       = ${WW3_COMP}"
  echo "    WWATCH3_NETCDF = ${WWATCH3_NETCDF}"
fi
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
##########


############################################################
### START THE CALCULATIONS
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
