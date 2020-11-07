########################################################################
#
# Main driver for NOAA R&D computing environment support
#
########################################################################

ifneq (,$(wildcard /scratch365/dwirasae))
  NEMS_COMPILER?=intel
  $(call add_build_env,ndcrc.$(NEMS_COMPILER),env/ndcrc/ndcrc.$(NEMS_COMPILER).mk)
endif

#else
#  ifneq (,$(and $(wildcard /lfs1),$(wildcard /lfs3)))
#    NEMS_COMPILER?=intel
#    $(call add_build_env,jet.$(NEMS_COMPILER),env/rdhpcs/jet.$(NEMS_COMPILER).mk)
#  else
#    ifneq (,$(shell hostname | grep -i gaea))
#      NEMS_COMPILER?=intel
#      $(call add_build_env,gaea.$(NEMS_COMPILER),env/rdhpcs/gaea.$(NEMS_COMPILER).mk)
#    endif
#  endif
#endif
