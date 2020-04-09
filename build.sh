#!/bin/bash
# moghimis@gmail.com 
# Script to compile NSEModel NEMS application

## Feb 27, 2020

# load modules
source modulefiles/hera/ESMF_NUOPC

cd NEMS

#clean up
make -f GNUmakefile distclean_ADCIRC COMPONENTS="ADCIRC"
make -f GNUmakefile distclean_WW3DATA COMPONENTS="WW3DATA"
make -f GNUmakefile distclean_ATMESH COMPONENTS="ATMESH"
make -f GNUmakefile distclean_NWM COMPONENTS="NWM"

#make
make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
# Beheen - is ATMESH part of the NSEM? We see this in CONOPS as MESH STREAM??
#make -f GNUmakefile build COMPONENTS="ADCIRC ATMESH WW3 NWM"
