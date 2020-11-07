# Target configuration file:

NEMS_CONF_FILES=\
  $(CONFDIR)/configure.nems \
  $(CONFDIR)/externals.nems \
  $(CONFDIR)/modules.nems \
  $(NEMSDIR)/src/ESMFVersionDefine.h \
  $(CONFDIR)/modules.nems.sh \
  $(CONFDIR)/modules.nems.csh \
  $(CONFDIR)/test-results.mk

########################################################################

# Sources of the configuration files:

# Set default values for the configure.nems and ESMFVersionDefine.h locations:
override CONFIGURE_NEMS_FILE ?= configure.nems.$(BUILD_TARGET)
override ESMF_VERSION_DEFINE ?= $(NEMSDIR)/src/ESMFVersionDefine_ESMF_NUOPC.h

# Set default value for the externals.nems location:
ifneq ($(EXTERNALS_NEMS),)
  override EXTERNALS_NEMS_FILE ?= $(EXTERNALS_NEMS)
endif
override EXTERNALS_NEMS_FILE ?=

# Decide where modules belong.
override MODULE_DIR ?= $(ROOTDIR)/modulefiles

# Make paths to modulefiles, etc. absolute.  Variables are unchanged
# if they are already absolute paths, or are empty.
override MODULE_DIR:=$(call abspath2,$(MODULE_DIR),$(ROOTDIR)/modulefiles/$(FULL_MACHINE_ID))
override CONFIGURE_NEMS_FILE:=$(call abspath2,$(CONFIGURE_NEMS_FILE),$(ROOTDIR)/conf/$(CONFIGURE_NEMS_FILE))
override EXTERNALS_NEMS_FILE:=$(call abspath2,$(EXTERNALS_NEMS_FILE),$(ROOTDIR)/conf/$(EXTERNALS_NEMS_FILE))

# Set default for CHOSEN_MODULE if a known machine is in use.
ifneq (,$(DEFAULT_MODULE))
  override CHOSEN_MODULE ?= $(DEFAULT_MODULE)
endif

# Remove the module logic if no module is selected.
ifeq (,$(CHOSEN_MODULE))
  MODULE_LOGIC=echo No module selected.
  MODULE_LIST=
endif
