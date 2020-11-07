########################################################################
#
# Main driver for CISL machine support
#
########################################################################

ifneq (,$(wildcard /glade))
  NEMS_COMPILER?=intel
  $(call add_build_env,cheyenne.$(NEMS_COMPILER),env/cisl/cheyenne.$(NEMS_COMPILER).mk)
endif
