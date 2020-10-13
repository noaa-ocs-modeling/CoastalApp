########################################################################
#
# This is the main entry point to the NEMS build system.  In and of
# itself, it does almost nothing; most of the real work is done in
# src/incmake/*.mk files.  The steps of logic are described in
# extensive detail throughout this file.
#
########################################################################

# The ROOTDIR is the application directory (parent of NEMS).  Do not
# change:
override ROOTDIR=${realpath ${dir ${realpath ${firstword $(MAKEFILE_LIST)}}}/..}

# The NEMSDIR is the NEMS repo clone within the application.  Do not
# change:
override NEMSDIR=$(ROOTDIR)/NEMS

# Makefiles should always use /bin/sh, and you should always specify
# it explicitly to make sure.  Never change this:
override SHELL=/bin/sh

# Set global variables and load utilities:
include $(NEMSDIR)/src/incmake/infinity.mk # Recursion detector
include $(NEMSDIR)/src/incmake/gmsl/gmsl  # GNU Make Standard Library
include $(NEMSDIR)/src/incmake/globals.mk
include $(NEMSDIR)/src/incmake/utils.mk

# Either auto-detect the build environment, or use the one the user specifies.
include $(NEMSDIR)/src/incmake/buildenv.mk

# Allow the application to override decisions about the platform, or
# set defaults for later steps:
-include $(ROOTDIR)/conf/before_components.mk

# Load the component list and various configuration variables.  We get
# this from either the application, or from makefile variables:
include $(NEMSDIR)/src/incmake/app.mk
include $(NEMSDIR)/src/incmake/no_app.mk
include $(NEMSDIR)/src/incmake/confopt.mk

# Rewrite the $(COMPONENTS) variable, which should just contain the
# components in the order that they can be built.  This step removes
# commas, handles %options, and expands dependencies via
# dependencies.mk:
include $(NEMSDIR)/src/incmake/relist_components.mk

# Allow the application to override decisions about components, and
# whatever else, before any further information is derived from these
# variables:
-include $(ROOTDIR)/conf/after_components.mk

# Generate some derived variables needed later:
include $(NEMSDIR)/src/incmake/configure_vars.mk
include $(NEMSDIR)/src/incmake/derived_vars.mk

########################################################################

# The default build rule just dumps the build information and tells
# the user to select a target (build, clean, etc.)  This is maintained
# in the main GNUmakefile, instead of a src/incmake file, to serve as
# documentation of the meanings of key variables.

define variable_dump

-------- NEMS VARIABLES --------
Application Directory -- $(ROOTDIR)
NEMS Directory        -- $(NEMSDIR)
Requested components  -- $(REQUESTED_COMPONENTS)
Components            -- $(COMPONENTS)
Chosen Modulefile     -- $(or $(CHOSEN_MODULE),(none))
configure.nems file   -- $(CONFIGURE_NEMS_FILE)
externals.nems file   -- $(or $(EXTERNALS_NEMS_FILE),(empty file))
NEMS executable       -- $(NEMS_EXE)

------ BUILD ENVIRONMENT -------
Build environment     -- $(BUILD_ENV) ($(BUILD_ENV_SOURCE))
 - all detected       -- $(call list_build_env)
Build Target          -- $(BUILD_TARGET)
Full Machine ID       -- $(FULL_MACHINE_ID)
Machine ID            -- $(MACHINE_ID)
Use modulefiles?      -- $(USE_MODULES)
NEMS compiler         -- $(NEMS_COMPILER)

----- COMPONENT VARIABLES ------
endef

define known_rules

--------- BUILD TARGETS --------
  Build NEMS: build
  Delete intermediate files: clean
  Also delete targets: distclean

  Build one component: $(BUILD_RULES)
  Clean one component: $(CLEAN_RULES)
  Also delete component targets: $(DISTCLEAN_RULES)
  Clean NEMS src, but NOT components: clean_NEMS
  Also remove NEMS executable: distclean_NEMS

  Create module and configuration files: configure
  Delete module and configuration files: unconfigure

  Reset to repo state if possible: armageddon

endef

debug_info:
	$(info $(variable_dump))
	$(if $(strip $(print_component_vars)),,$(info $(space)$(space)(none)))
	$(info $(known_rules))
	$(error Did you mean to "make build?"  Specify a build target)

########################################################################

# Define all Make rules except debug_info (above) and armageddon (below)

# Ensure these targets are treated as not being files:
.PHONY: distclean build debug_info armageddon clean

# Do not compile components in parallel, even if a parallel build (-j)
# is requested.  Submakes will still be parallel.
.NOTPARALLEL:

# Include the component_*.mk files for each enabled component and
# abort with an $(error) if a component lacks its *.mk file:
include $(foreach comp,$(COMPONENTS),$(call locate_incmake_file,component_$(comp).mk))

# Load the rules related to configuring NEMS:
include $(NEMSDIR)/src/incmake/configure_rules.mk

# Load rules related to building or cleaning the NEMS source code
# (NEMS/src) and executable:
include $(NEMSDIR)/src/incmake/NEMS.mk

# The "clean" target deletes all compiler intermediate files:
clean: $(CLEAN_RULES) clean_NEMS

# The "distclean" target also deletes targets and configuration files.
# Only src/conf/components.mk remains:
distclean: $(DISTCLEAN_RULES) distclean_NEMS unconfigure
	-rm -f $(CONFDIR)/components.mk
	-rm -f $(CONFDIR)/test_results.mk

# The "build" target builds all components and the NEMS executable:
build: $(BUILD_RULES) build_NEMS

# The special "FORCE" rule can be used as a dependency to ensure
# a rule is always run regardless of whether its target is up to date.
.PHONY: FORCE
FORCE:

########################################################################

# The "armageddon" target us aptly named.  It attempts to restore the
# entire source tree to the repository state.  This is done
# recursively into all submodules from the application level on down.
# It will discard all local changes, delete untracked files (including
# ones git normally ignores), and delete all untracked directories,
# even if they contain a git repository.  
#
# Certain types of submodule conflicts, or a corrupted git repository,
# can cause this process to fail.
armageddon:
	cd $(ROOTDIR)                                     ; \
	git reset --hard HEAD                             ; \
	git clean -f -f -d -x                             ; \
	git submodule foreach --recursive                   \
	  'git reset --hard HEAD ; git clean -f -f -d -x' ; \
	git submodule update --init --recursive --force     \
	    --checkout ||                                   \
	git submodule update --init --recursive           ; \
	echo                                              ; \
	echo REPOSITORY STATE AFTER ARMAGEDDON            ; \
	echo                                              ; \
	git status -uall --ignored                        ; \
	git submodule foreach --recursive                   \
	    git status -uall --ignored

########################################################################

# Allow the application one last change to override things, after all
# other makefile logic is processed:
-include $(ROOTDIR)/conf/after_everything.mk

