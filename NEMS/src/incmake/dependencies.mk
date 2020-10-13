# This is used as a top-level makefile when updating the $(COMPONENTS)
# variable to add or reorder components based on dependencies.  This
# file is loaded alone in a block of code that updates the component
# list.  Most of the other incmake/*.mk files are not loaded.  Hence,
# the utilities and platform information are unavailable.

# ----------------------------------------------------------------------

# Do not change these five lines:
SHELL=/bin/sh
NEMSDIR=${realpath ${dir ${realpath ${firstword $(MAKEFILE_LIST)}}}/../..}
ROOTDIR=$(realpath $(NEMSDIR)/..)
CONFDIR=$(NEMSDIR)/src/conf
include $(NEMSDIR)/src/incmake/dep_helper.mk

# ----------------------------------------------------------------------

FMS:
	$(call prepend_component,$@)

FV3_DEPS=FMS

ifneq (,$(findstring CCPP=Y,$(COMPONENTS)))
  FV3_DEPS += CCPP
endif

CCPP:
	$(call prepend_component,$@)

MOM6: FMS
FV3: $(FV3_DEPS)
