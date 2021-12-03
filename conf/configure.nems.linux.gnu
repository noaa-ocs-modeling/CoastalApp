## NEMS configuration file
##
## Platform: Generic/Linux
## Compiler: GNU with MPI   --- needs fixing

SHELL           = /bin/sh

################################################################################
## Include the common configuration parts
include         $(TOP)/conf/configure.nems.NUOPC

################################################################################
## Other settings

LIBDIR      ?= .

NETCDF_INC   = -I${NETCDF_INCDIR}
NETCDF_LIB   = -L${NETCDF_LIBDIR} -lnetcdf

#NEMSIO_INC   = -I${LIBDIR}/incmod/nemsio
#NEMSIO_LIB   = -L${LIBDIR} -lnemsio
NEMSIO_INC   =
NEMSIO_LIB   =
SYS_LIB      =

EXTLIBS      = $(NEMSIO_LIB) \
               $(NETCDF_LIB) \
               $(ESMF_LIB)   \
               $(SYS_LIB) -lm

EXTLIBS_POST = $(NEMSIO_LIB)  \
               $(ESMF_LIB)    \
               $(NETCDF_LIB)  \
               $(SYS_LIB)
###
FC          = mpif90 -g -ffree-line-length-none -fno-range-check -fbacktrace
F77         = mpifort -g -ffree-line-length-none -fno-range-check -fbacktrace
FREE         = -free
FIXED        = -fixed
R8           = -r8

FINCS        = $(ESMF_INC) $(NEMSIO_INC) $(NETCDF_INC)
#TRAPS        = ???

FFLAGS       = $(TRAPS) $(FINCS)

OPTS_NMM     = -g -ffree-line-length-none -fno-range-check -fbacktrace $(FREE)

FFLAGM_DEBUG =

FFLAGS_NMM   = $(MACROS_NWM) $(OPTS_NMM) $(FFLAGS)

FPP          = -fpp
CPP          = cpp -P -traditional
CPPFLAGS     = -DENABLE_SMP -DCHNK_RRTM=8 

AR           = ar
ARFLAGS      = -r

RM           = rm
