########################################################################
#
# Main driver for Intel development machine support
#
########################################################################

ifneq (,$(wildcard /work/stampede))
  NEMS_COMPILER?=intel
  $(call add_build_env,stampede.$(NEMS_COMPILER),env/tacc/stampede.$(NEMS_COMPILER).mk)
endif
