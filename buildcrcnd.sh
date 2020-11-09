#!/bin/bash -i 

# Description : Script to compile NSEModel NEMS application
# Usage       : ./build.sh
# Date        : Feb 27, 2020
# Contact     : moghimis@gmail.com 


# load modules
source modulefiles/ndcrc/ESMF_NUOPC

cd NEMS
curdir=$PWD ;

echo $curdir
cd $curdir/src ; make clean ;
cd $curdir 

# location of netcdf at ND-CRC
export NETCDF=/opt/crc/n/netcdf/4.7.0/intel/18.0/      
export NETCDFHOME=/opt/crc/n/netcdf/4.7.0/intel/18.0/

# location of ESMFMKFILE
export ESMFMKFILE=/afs/crc.nd.edu/user/d/dwirasae/AlaskaProject/esmf_8/DEFAULTINSTALLDIR/lib/libO/Linux.intel.64.mvapich2.default/esmf.mk 

#clean up
make -f GNUmakefile distclean_ADCIRC COMPONENTS="ADCIRC"
make -f GNUmakefile distclean_WW3DATA COMPONENTS="WW3DATA"
make -f GNUmakefile distclean_ATMESH COMPONENTS="ATMESH"
#make -f GNUmakefile distclean_NWM COMPONENTS="NWM"
make -f GNUmakefile distclean_WW3 COMPONENTS="WW3"

#make
#make -f GNUmakefile build COMPONENTS="ADCIRC NWM ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH WW3 NWM"
make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH WW3 WW3DATA"
#make -f GNUmakefile build COMPONENTS="WW3DATA ADCIRC ATMESH"
#make -f GNUmakefile build COMPONENTS="WW3"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH  NWM"
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH"



