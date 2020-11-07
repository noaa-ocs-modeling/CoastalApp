# This reproduces the $CONF_OPTION logic in the obsolete NEMS/src/configure script.
ifneq ($(CONFOPT),)
  $(warning CONFOPT is deprecated.  Use CONFIGURE_NEMS_FILE, EXTERNALS_NEMS_FILE, and CHOSEN_MODULE instead.)

  $(info Automatically converting to new variables from CONFOPT="$(CONFOPT)")

  ifeq ($(CONFOPT),nmmb_intel_wcoss)
    CONFIGURE_NEMS_FILE ?= configure.nems.Wcoss.intel_nmmb
    CHOSEN_MODULE       ?= wcoss/ESMF_700_nmmb

  else ifeq ($(CONFOPT),gsm_intel_wcoss)
    CONFIGURE_NEMS_FILE ?= configure.nems.Wcoss.intel_gsm
    CHOSEN_MODULE       ?= wcoss.phase1/ESMF_700_gsm

  else ifeq ($(CONFOPT),gsm_intel_wcoss_c)
    CONFIGURE_NEMS_FILE ?= configure.nems.Wcoss_C.intel_gsm
    CHOSEN_MODULE       ?= wcoss.cray/ESMF_700_gsm

  else ifeq ($(CONFOPT),coupled_intel_wcoss)
    CONFIGURE_NEMS_FILE ?= configure.nems.Wcoss.intel
    EXTERNALS_NEMS_FILE ?= externals.nems.Wcoss
    CHOSEN_MODULE       ?= wcoss.phase1/ESMF_NUOPC

  else ifeq ($(CONFOPT),coupled_intel_wcoss_cray)
    CONFIGURE_NEMS_FILE ?= configure.nems.Wcoss_C.intel
    EXTERNALS_NEMS_FILE ?= externals.nems.Wcoss_C
    CHOSEN_MODULE       ?= wcoss.cray/ESMF_NUOPC

  else ifeq ($(CONFOPT),coupled_intel_gaea)
    CONFIGURE_NEMS_FILE ?= configure.nems.Gaea.intel
    EXTERNALS_NEMS_FILE ?= externals.nems.Gaea
    CHOSEN_MODULE       ?= gaea/ESMF_NUOPC

  else ifeq ($(CONFOPT),coupled_intel_yellowstone)
    CONFIGURE_NEMS_FILE ?= configure.nems.Yellowstone.intel
    EXTERNALS_NEMS_FILE ?= externals.nems.Yellowstone
    CHOSEN_MODULE       ?= gaea/ESMF_NUOPC

  else ifeq ($(CONFOPT),coupled_linux_gnu)
    CONFIGURE_NEMS_FILE ?= configure.nems.Linux.gnu conf/configure.nems
    EXTERNALS_NEMS_FILE ?= externals.nems.Linux.gnu

  else
    ifneq ($(wildcard $(ROOTDIR)/conf/$(CONFOPT)),)
      CONFIGURE_NEMS_FILE ?= $(CONFOPT)
    else
      $(error $(CONFOPT): unknown configuration)
    endif
  endif
endif
