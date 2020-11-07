########################################################################
#
# Main driver for supporting build environments in unknown clusters.
# Generally, this uses "uname" to detect the platform.
#
########################################################################

override uname_a=$(shell uname -a)

ifneq (,$(findstring Darwin,$(uname_a)))
  NEMS_COMPILER?=gnu
  $(call add_build_env,macosx.$(NEMS_COMPILER),env/uname/macosx.$(NEMS_COMPILER).mk)
endif

ifneq (,$(findstring Linux,$(uname_a)))
  NEMS_COMPILER?=gnu
  $(call add_build_env,linux.$(NEMS_COMPILER),env/uname/linux.$(NEMS_COMPILER).mk)
endif
