# This is a self-contained make include file that has the generic
# logic for getting the list of components.  The actual dependencies
# are in components.mk

# Self-contained, other than the standard library:
include $(NEMSDIR)/src/incmake/gmsl/gmsl

# And the constants and utilties:
include $(NEMSDIR)/src/incmake/globals.mk
include $(NEMSDIR)/src/incmake/utils.mk

prepend_component=$(eval override COMPONENTS=$(1) $(COMPONENTS))
replace_component=$(eval override COMPONENTS=$(foreach comp,$(COMPONENTS),$(if $(seq $(comp),$(1)),$(2),$(comp))))

COMPONENTS: $(TARGET)

$(TARGET): $(COMPONENTS)
	echo '$(call uniq,$(COMPONENTS))' > "$@"

########################################################################

# Find all known components:

component_for_file=$(subst component_,,$(basename $(notdir $(1))))
component_files=$(call wildcard_in,component_*.mk,$(MAKE_INCLUDE_DIRS))
KNOWN_COMPONENTS=$(foreach file,$(component_files),$(call component_for_file,$(file)))

.PHONY: $(KNOWN_COMPONENTS) COMPONENTS

########################################################################

# Detect unknown components:

is_known=$(strip $(foreach known,$(KNOWN_COMPONENTS),$(if $(call seq,$(1),$(known)),$(known))))
warn_if_unknown=$(if $(call is_known,$(1)),,$(warning $(1): unknown component)$(1))
UNKNOWN_COMPONENTS=$(strip $(foreach comp,$(COMPONENTS),$(call warn_if_unknown,$(comp))))

$(and $(UNKNOWN_COMPONENTS),$(warning allowed components: $(KNOWN_COMPONENTS)))
$(and $(UNKNOWN_COMPONENTS),$(error Unknown component specified))
