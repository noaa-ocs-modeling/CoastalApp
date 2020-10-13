SHELL = /bin/sh

# Don't change these two:
NEMSDIR=${realpath ${dir ${realpath ${firstword $(MAKEFILE_LIST)}}}/..}
CONFDIR=$(NEMSDIR)/src/conf

# Flag variable so the configure.nems knows we're in NEMS.  This is
# needed by the FV3 to allow the NEMS configure file to be the same
# file as the FV3 configure file.
export InNemsMakefile=YES

# variables that need to move between makefiles on different levels of the build tree
# via shell environment variables
export TOP := $(NEMSDIR)/src

include $(CONFDIR)/test-results.mk
include $(NEMSDIR)/src/incmake/globals.mk
include $(NEMSDIR)/src/incmake/gmsl/gmsl
include $(NEMSDIR)/src/incmake/utils.mk
include $(NEMSDIR)/src/incmake/whoami.mk

# Read in the path to external components if the file exists.
-include ./conf/externals.nems

ifneq ($(wildcard ./conf/configure.nems),)
  # An "if" is needed here to avoid loading the include when it does
  # not exist.  A "-include" will not achieve that because it will try
  # to build the configure.nems.
  include ./conf/configure.nems
endif

# external COMP dependencies ###################################################

# The below "define comp_template" is a convenient way to create a
# block of code that loads the *.mk file that was created by a
# component.  Note that in definitions like this, variable references
# that should be retained in the generated rule must have $$(varname)
# syntax, not $(varname) The special variable $(1) is an argument to
# comp_template, and contains the component name.

define comp_template
  $$(info $(1): include $$(call $$(call lc,$(1))_mk))
  comp_mk=$$(call $$(call lc,$(1))_mk)
  ifeq (,$$(wildcard $$(comp_mk)))
    ifeq (YES,$(INCLUDES_ARE_OPTIONAL))
      $$(warning $$(comp_mk): component $(1) makefile fragment is missing)
    else
      $$(error $$(comp_mk): component $(1) makefile fragment is missing)
    endif
  else
    include $$(comp_mk)
  endif
  DEP_FRONTS    := $$(DEP_FRONTS) -DFRONT_$(1)=$$(ESMF_DEP_FRONT)
  DEP_INCS      := $$(DEP_INCS) $$(addprefix -I, $$(ESMF_DEP_INCPATH))
  DEP_CMPL_OBJS := $$(DEP_CMPL_OBJS) $$(ESMF_DEP_CMPL_OBJS)
  DEP_LINK_OBJS := $$(DEP_LINK_OBJS) $$(ESMF_DEP_LINK_OBJS)
  DEP_SHRD_PATH := $$(DEP_SHRD_PATH) $$(addprefix -L, $$(ESMF_DEP_SHRD_PATH)) $$(addprefix -Wl$$(comma)-rpath$$(comma), $$(ESMF_DEP_SHRD_PATH))
  DEP_SHRD_LIBS := $$(DEP_SHRD_LIBS) $$(addprefix -l, $$(ESMF_DEP_SHRD_LIBS))
endef

# Next, we the components in reverse order by evaluating the
# "comp_template" in a $(foreach) loop with the component name as
# the first argument (AKA $(1)) within the comp_template.

# A note on order: reversing the order is needed to ensure proper link
# order when one component depends on another (ie. MOM6 and FV3 must
# show up before FMS in the link order).
COMP_LINK_ORDER=$(call reverse,$(COMPONENTS))
$(info Components in linker order: $(COMP_LINK_ORDER))
$(foreach COMP,$(COMP_LINK_ORDER),$(eval $(call comp_template,$(COMP))))

################################################################################
##$(info $$DEP_LINK_OBJS is [$(DEP_LINK_OBJS)])

CPPFLAGS += $(DEP_FRONTS)

ifneq (,$(findstring CMEPS,$(COMPONENTS)))
CPPFLAGS += -DCMEPS
endif

TARGET = ../exe/NEMS.x

ifneq (,$(findstring MACOSX,$(CPPDEFS)))
INCS = -IENS_Cpl \
	-I. \
	$(ESMF_INC) \
	$(DEP_INCS)
else
INCS = -IENS_Cpl \
	-I. \
	$(DEP_INCS)
endif

MAIN = MAIN_NEMS.o

OBJS = module_NEMS_UTILS.o \
       module_MEDIATOR_methods.o \
       module_MEDIATOR.o \
       module_MEDIATOR_SpaceWeather.o \
       module_EARTH_INTERNAL_STATE.o \
       module_EARTH_GRID_COMP.o \
       module_NEMS_INTERNAL_STATE.o \
       module_NEMS_GRID_COMP.o \
       module_NEMS_Rusage.o

COBJS = nems_c_rusage.o

MAKEFILE = makefile

# Dependencies are unknown.
.NOTPARALLEL:

#
# GOCART specific compilation variables/flags
#
GOCART_MODE=stub
ESMADIR=$(CHEM_DIR)
#gjt: comment out the following line because it unconditionally uses CHEM_INC
#gjt: THIS NEEDS TO BE FIXED!
-include $(CHEM_INC)/NCEP_base.mk

ifeq ($(GOCART_MODE),stub)
	LIBGOCART=
else
	LIBGOCART=$(LIB_GOCART)
		CHEM_LIB=$(CHEM_DIR)_full/$(CHEM_VER)
		CHEM_MOD=$(CHEM_LIB)/mod
		CHEM_INC=$(CHEM_LIB)/include
		PHYS_LIB=$(PHYS_DIR)_full/$(CHEM_VER)
		PHYS_MOD=$(PHYS_LIB)/mod
		PHYS_INC=$(PHYS_LIB)/include
endif

ifeq ($(PHYS_MODE),compile)
        PHYS_LIB = $(TOP)/atmos/gsm/gsmphys
        PHYS_INC = $(TOP)/atmos/gsm/gsmphys
        PHYS_DIR = $(TOP)/atmos/gsm/gsmphys
endif
ifeq ($(CHEM_MODE),compile)
        CHEM_LIB = $(TOP)/../../chem/gocart
        CHEM_INC = $(TOP)/../../chem/gocart/src/Config
        CHEM_DIR = $(TOP)/../../chem
	CHEM_MOD = $(TOP)/../../chem/gocart/${ARCH}/include
ESMADIR=$(CHEM_LIB)
#gjt: THIS NEEDS TO BE FIXED!
#include $(ESMADIR)/src/Config/NCEP_base.mk
endif



export GOCART_MODE
ESMADIR=$(CHEM_LIB)
#gjt: comment out the following line because it unconditionally uses CHEM_INC
#gjt: THIS NEEDS TO BE FIXED!
#-include $(CHEM_INC)/NCEP_base.mk
#
# log info
#
CPPFLAGS += $(WHOFLAGS)

################################################################################
#
# Add all ESMF_VERSION_* variables to CPPFLAGS, with proper quoting.
# For variables that cannot be quoted (value contains both ' and "),
# give a warning and skip those variables.
#
################################################################################

# Macro to add one variable $(1) to cppflags with $(2) = ' or "
add_one_to_cppflags=$(eval CPPFLAGS += -D$(1)=$(2)$($(1))$(2))$(info CPPFLAGS += $(1)=$(2)$($(1))$(2))

# Macro that decides whether to use ' or " to quote, and then calls add_one_to_cppflags:
add_to_cppflags=$(call quote_var,$(1),add_one_to_cppflags,$(dollar)$(lparen)$(1)$(rparen): cannot quote value; ignoring variable.  Value contains both single- and double-quote characters: $($(1)))

# Loop over all defined variables, calling add_to_cppflags (see above)
# on each.  The $(and ...,) ensures the result is the empty string.
$(and $(foreach var,$(.VARIABLES),$(if $(call startswith,$(var),ESMF_VERSION),$(call add_to_cppflags,$(var)))),)

################################################################################
#
# Ask user which target he/she wants to build
#
################################################################################
define no_rule_error
No build rule specified.

  make clean
  make nems COMPONENTS="FV3 MOM6 CICE5 WW3"

Specify a build rule and components.  Make sure you compile components first.
Please
endef

all:
	$(error $(no_rule_error))

################################################################################
#
# NEMS
#
################################################################################

LIBS_NEMS = $(DEP_LINK_OBJS)             \
            ENS_Cpl/ENS_Cpl.a

EXTRA_LINK_FLAGS =

ifneq (,$(findstring MACOSX,$(CPPDEFS)))
EXTRA_LINK_FLAGS += -headerpad_max_install_names
endif

nems: nems_libs $(OBJS) $(COBJS) $(MAIN) ./conf/configure.nems
	echo libgocart is $(LIBGOCART)
	echo extlibs is $(EXTLIBS)
	$(FC) $(SMP) -o $(TARGET) $(MAIN) $(OBJS) $(COBJS) $(LIBS_NEMS) $(EXTLIBS) $(LIBGOCART) $(EXTRA_LINK_FLAGS)
	@echo "$(TARGET) is created."

conf/configure.nems:
	$(error NEMS configure file is missing!  You must configure NEMS before building.)

nems_libs:
	cd ENS_Cpl             && $(MAKE) stub

################################################################################
#
# Clean everything
#
################################################################################

.SUFFIXES: .F90 .tmp.f90 .o

$(COBJS) : %.o: %.c 
	$(CC) -c $*.c

clean:
	$(RM) -f *.tmp.f90 *.lst *.o *.mod lm map
	cd ENS_Cpl ; $(MAKE) clean
$(OBJS): %.o: %.tmp.f90
	$(FC) $(FFLAGS) $(INCS) -c $*.tmp.f90
	mv -v $*.tmp.o $*.o

%.tmp.f90: %.F90
	$(CPP) $(CPPFLAGS) $< > $*.tmp.f90
MAIN_NEMS.o: %.o: %.tmp.f90
	$(FC) $(FFLAGS) $(INCS) -c $*.tmp.f90
	mv -v $*.tmp.o $*.o

