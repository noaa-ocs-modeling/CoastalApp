########################################################################
#
# Main driver for Intel development machine support
#
########################################################################

ifneq (,$(wildcard /lrz/sys))
  NEMS_COMPILER?=intel
  $(call add_build_env,supermuc_phase2.$(NEMS_COMPILER),env/lrz/supermuc_phase2.$(NEMS_COMPILER).mk)
endif
