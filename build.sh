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

# Default configuration for WW3 (on Hera)
if [ "${NETCDF_CONFIG}" == "" ]
    then 
    echo "ERROR - Your NETCDF_CONFIG environment variable for WW3 is not set"
    exit 1
else
    echo "NETCDF_CONFIG set to ${NETCDF_CONFIG}"
fi
if [ "${METIS_PATH}" == "" ]
    then 
    echo "ERROR - Your METIS_PATH environment variable for WW3 is not set"
    exit 1
else
    echo "METIS_PATH set to ${METIS_PATH}"
fi
echo 'F90 NOGRB NC4 DIST MPI PDLIB SCRIP PR3 UQ FLX0 SEED LD2 ST4 STAB0 NL1 BT1 DB1 MLIM TR0 BS0 XX0 WNX1 WNT1 CRX1 CRT1 O0 O1 O2 O3 O4 O5 O6 O7 O14 O15 IC0 IS0 REF0' > $ROOTDIR/WW3/model/esmf/switch
echo "WW3 configured with these switch file options: $(<${ROOTDIR}/WW3/model/esmf/switch)"
cp $ROOTDIR/WW3/model/bin/comp.Intel comp
cp $ROOTDIR/WW3/model/bin/link.Intel link

# Make coupled NEMS app
#make -f GNUmakefile build COMPONENTS="ADCIRC NWM ATMESH"
make -f GNUmakefile build COMPONENTS="ADCIRC WW3 ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH WW3 NWM"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH  NWM"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH NWM"
