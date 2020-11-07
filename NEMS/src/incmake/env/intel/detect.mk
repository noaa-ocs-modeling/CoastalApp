########################################################################
#
# Main driver for Intel development machine support
#
########################################################################

ifneq (,$(wildcard /panfs))
  NEMS_COMPILER?=intel
  $(call add_build_env,endeavor.$(NEMS_COMPILER),env/intel/endeavor.$(NEMS_COMPILER).mk)
endif
