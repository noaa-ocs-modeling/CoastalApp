########################################################################
#
# Main driver for NOAA WCOSS support
#
########################################################################

ifneq (,$(and $(wildcard /gpfs/hps),$(wildcard /usrx)))
  ifneq (,$(and $(wildcard /usrx),$(wildcard /etc/redhat-release),$(wildcard /etc/prod)))
    # We are on WCOSS Phase 1, 2, or 3
    ifneq (,$(shell readlink /usrx|grep dell 2> /dev/null ))
      # The /usrx is in one of the dell filesystems, so we are on Phase 3
      $(call add_build_env,wcoss_dell_p3,env/wcoss/wcoss_dell_p3.mk)
    else
      #$(info Not on Dell)
      ifeq (,$(shell cat /proc/cpuinfo |grep 'processor.*32' 2>/dev/null))
        # Fewer than 32 fake (hyperthreading) cpus, so Phase 1 is the
        # default.  Phase 2 is also available.
        $(call add_build_env,wcoss_phase1,env/wcoss/wcoss_phase1.mk)
        $(call add_build_env,wcoss_phase2,env/wcoss/wcoss_phase2.mk)
      else
        # We're on Phase 2, so that is the default.  Phase 1 is also available.
        $(call add_build_env,wcoss_phase2,env/wcoss/wcoss_phase2.mk)
        $(call add_build_env,wcoss_phase1,env/wcoss/wcoss_phase1.mk)
      endif
    endif
  else
    # WCOSS Cray
    $(call add_build_env,wcoss_cray,env/wcoss/wcoss_cray.mk)
  endif
endif
