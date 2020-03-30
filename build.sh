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

#make
make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH"
#make -f GNUmakefile build COMPONENTS="ADCIRC WW3DATA ATMESH WW3"
