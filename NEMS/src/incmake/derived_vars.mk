override BUILD_TARGET        ?= $(FULL_MACHINE_ID).$(NEMS_COMPILER)

# Do not allow MAKEOPT
ifneq ($(MAKEOPT),)
  define makeopt_bad
The MAKEOPT variable has been removed.  Use NEMS_BUILDOPT instead.
Do not set MAKEOPT
  endef
  $(error $(makeopt_bad))
endif

# Construct the list of build_whatever, distclean_whatever, and
# clean_whatever rules, excluding the ones for NEMS itself:
CLEAN_RULES=$(foreach comp,$(COMPONENTS),clean_$(comp))
DISTCLEAN_RULES=$(foreach comp,$(COMPONENTS),distclean_$(comp))
BUILD_RULES=$(foreach comp,$(COMPONENTS),build_$(comp))

.PHONY: $(CLEAN_RULES) $(BUILD_RULES) $(DISTCLEAN_RULES)
