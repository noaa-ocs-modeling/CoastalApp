########################################################################
#
# This is the main driver for the build environment decision logic.
# It walks throught the known build environments (WCOSS Phase 3, Linux
# GNU, Hera + Intel compiler, etc.)  For each one, if the environment
# is detected on this machine, it is added to the known list.  The
# first detected is chosen as the default, unless the user chooses one
# through the BUILD_ENV variable.
#
########################################################################


# ----------------------------------------------------------------------

# Utility functions and internal variables:

# default_build_env: Default build environment if none is specified.
# This is set to the first environment sent to $(call add_build_env).
override default_build_env=

# ordered_build_env: build environment names in the order they are detected
override ordered_build_env=

# $(call list_build_env): a list of the names of all detected build
# environments.
list_build_env=$(strip $(ordered_build_env))

# $(call add_build_env,name,include_file)
# Adds a build environment with the specified name to the list of
# known build environments.  The include_file is used by
# load_build_env to select that build environment.
add_build_env=$(and $(call set,detected_build_env,$(1),$(2))$(if $(default_build_env),,$(eval override default_build_env=$(1)))$(eval override ordered_build_env += $(1)),)

# $(call build_env_include,name)
# Returns the include file for the specified build environment.
build_env_include=$(call get,detected_build_env,$(1))

# $(call ULIMIT_MODULE_LOGIC,kilobytes)
# Generates a sequence of shell commands that will:
#   1. Set the stack soft limit to the specified size.
#   2. Obtain the module command.
#   3. Load the nems modules.
#   4. Restore the stack soft limit.
define ULIMIT_MODULE_LOGIC
  . $(CONFDIR)/module-setup.sh.inc ; \
  stack=`ulimit -S -s`                  ; \
  ulimit -S -s $(1)                     ; \
  module use $(CONFDIR)                 ; \
  module load modules.nems              ; \
  module list                           ; \
  ulimit -S -s $$stack
endef

define SOURCE_MODULE_LOGIC
  . $(CONFDIR)/modules.nems
endef

# ----------------------------------------------------------------------

# Detect available build environments.

include $(call locate_incmake_file,env/app_extras/detect.mk)
include $(call locate_incmake_file,env/ndcrc/detect.mk)
include $(call locate_incmake_file,env/wcoss/detect.mk)
include $(call locate_incmake_file,env/rdhpcs/detect.mk)
include $(call locate_incmake_file,env/cisl/detect.mk)
include $(call locate_incmake_file,env/intel/detect.mk)
include $(call locate_incmake_file,env/tacc/detect.mk)
include $(call locate_incmake_file,env/lrz/detect.mk)
include $(call locate_incmake_file,env/uname/detect.mk)


ifeq (,$(list_build_env))
  $(error No build environment detected.  You must add or update the build enviornment logic in NEMS/src/incmake/env .)
endif

# ----------------------------------------------------------------------

# Decide which build environment to use, and load its settings:

ifeq (,$(BUILD_ENV))
  # User did not specify a build environment, so we'll use the first detected.
  BUILD_ENV=$(default_build_env)
  BUILD_ENV_SOURCE=default
else
  BUILD_ENV_SOURCE=manually specified
endif

ifeq (,$(call defined,detected_build_env,$(BUILD_ENV)))
  $(error $(BUILD_ENV): no such build environment.  Available build environments: $(call list_build_env))
else
  include $(call locate_incmake_file,$(call build_env_include,$(BUILD_ENV)))
endif

# ----------------------------------------------------------------------

# Set reasonable default values:

PEX?=na

# Defaults for MACHINE_ID and FULL_MACHINE_ID are each other:
ifeq (,$(MACHINE_ID))
  ifeq (,$(FULL_MACHINE_ID))
    $(error $(BUILD_ENV): Neither MACHINE_ID nor FULL_MACHINE_ID were set by this build environment.  Please update $(call build_env_include,$(BUILD_ENV)) or specify those variables manually.)
  else
    override MACHINE_ID=$(FULL_MACHINE_ID)
  endif
else
  ifeq (,$(FULL_MACHINE_ID))
    override FULL_MACHINE_ID=$(MACHINE_ID)
  endif
endif

BUILD_TARGET?=$(FULL_MACHINE_ID).$(NEMS_COMPILER)

ifeq ($(true),$(call and,$(call sne,$(USE_MODULES),YES),$(call sne,$(USE_MODULES),NO)))
  $(error $(BUILD_ENV): The USE_MODULES variable must be set to YES or NO (is set to "$(USE_MODULES)" instead).  Please update $(call build_env_include,$(BUILD_ENV)) or specify the USE_MODULES flag manually.)
endif

# ----------------------------------------------------------------------

# Derived information:

MACHINE_ID_DOT=$(subst _,.,$(MACHINE_ID))
MACHINE_ID_UNDER=$(subst .,_,$(MACHINE_ID))

FULL_MACHINE_ID_DOT=$(subst _,.,$(FULL_MACHINE_ID))
FULL_MACHINE_ID_UNDER=$(subst .,_,$(FULL_MACHINE_ID))

