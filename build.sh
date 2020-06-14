#!/bin/bash

# Description : Script to compile NSEModel NEMS application
# Usage       : ./build.sh
# Date        : Feb 27, 2020
# Contact     : moghimis@gmail.com 

# Check for env variables
if [ "${ROOTDIR}" == "" ]
    then 
    echo "ERROR - Your ROOTDIR environment variable is not set"
    exit 1
fi
if [ "${NEMSDIR}" == "" ]
    then 
    echo "ERROR - Your NEMSDIR environment variable is not set"
    exit 1
fi
if [ "${METIS_PATH}" == "" ]
    then 
    echo "ERROR - Your METIS_PATH environment variable for WW3 is not set"
    exit 1
else
    echo "METIS_PATH set to ${METIS_PATH}"
fi

# Load modules
source ${ROOTDIR}/modulefiles/hera/ESMF_NUOPC
module list

echo "Building NEMS app in ${NEMSDIR}"
cd $NEMSDIR

# Clean up
make -f GNUmakefile distclean_ADCIRC COMPONENTS="ADCIRC"
make -f GNUmakefile distclean_WW3DATA COMPONENTS="WW3DATA"
make -f GNUmakefile distclean_ATMESH COMPONENTS="ATMESH"
make -f GNUmakefile distclean_WW3 COMPONENTS="WW3"
make -f GNUmakefile distclean_NWM COMPONENTS="NWM"
make -f GNUmakefile distclean_NEMS COMPONENTS="ADCIRC WW3 NWM ATMESH"

# Make coupled NEMS app
#make -f GNUmakefile build COMPONENTS="ADCIRC NWM ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3 ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH WW3 NWM"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH  NWM"
make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH NWM"
