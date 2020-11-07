# Location of the ESMF makefile fragment for this component:
ccpp_mk=$(CCPP_BINDIR)/ccpp.mk
all_component_mk_files+=$(ccpp_mk)

# Location of source code and installation
CCPP_SRCDIR?=$(ROOTDIR)/FV3/ccpp
CCPP_BINDIR?=$(ROOTDIR)/FV3/ccpp

# Build directory - set to FV3 (later fv3atm) for old make (i.e. in-source) build
CCPP_BUILDDIR?=$(ROOTDIR)/FV3

# Make sure we have a model that supports CCPP:
ifeq (,$(findstring FV3,$(COMPONENTS)))
  $(error CCPP requires FV3)
else
  # Ensure the model is selected.
  override CCPP_CONFOPT += --config=$(CCPP_SRCDIR)/config/ccpp_prebuild_config.py --builddir=$(CCPP_BUILDDIR)
  override CCPP_MAKEOPT ?= $(FV3_MAKEOPT)
  override CCPP_BUILDOPT ?= $(FV3_BUILDOPT)
endif

ifneq (,$(findstring DEBUG=Y,$(FV3_MAKEOPT)))
  override CCPP_CONFOPT += --debug
endif

# Process make options for static CCPP build
ifneq (,$(findstring STATIC=Y,$(FV3_MAKEOPT)))
  ifneq (,$(findstring SUITES=,$(FV3_MAKEOPT)))
    # Extract name of suite definition file for static build using sed;
    # Sam Trahan most likely knows a much better way for doing this!
    # - remove everything leading up to the name of the suite definition file
    # - remove everything following the name of the suite definition file
    SUITES = $(shell echo $(FV3_MAKEOPT) | sed 's/.* SUITES=//' | sed 's/ .*//')
    override CCPP_CONFOPT += --static --suites=$(SUITES)
  else
    $(error Option STATIC=Y requires suites argument as SUITES=xyz,abc,... (where suite xyz corresponds to file suite_xyz.xml))
  endif
endif

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(CCPP_SRCDIR),CCPP source directory)

########################################################################

# Rule for building this component:
build_CCPP: $(ccpp_mk)

$(ccpp_mk): configure
	$(MODULE_LOGIC) ; \
	set -xue                                                        ; \
	export PATH_CCPP="$(CCPP_SRCDIR)"                               ; \
	cd $(ROOTDIR)                                                   ; \
	$$PATH_CCPP/framework/scripts/ccpp_prebuild.py $(CCPP_CONFOPT)  ; \
	cd $$PATH_CCPP                                                  ; \
	./build_ccpp.sh ${BUILD_TARGET} "$$PATH_CCPP" $(ccpp_mk)          \
	  "$(CCPP_MAKEOPT)" NO NO                                       ; \
	test -d "$(CCPP_BINDIR)"/include                                ; \
	test -d "$(CCPP_BINDIR)"/lib

########################################################################

# Rule for cleaning intermediate files
distclean_CCPP: clean_CCPP
	set -xue                                                        ; \
	export PATH_CCPP="$(CCPP_SRCDIR)"                               ; \
	cd $(ROOTDIR)                                                   ; \
	$$PATH_CCPP/framework/scripts/ccpp_prebuild.py $(CCPP_CONFOPT) --clean ; \
	cd $$PATH_CCPP                                                  ; \
	rm -rf "$(CCPP_BINDIR)/lib"                                     ; \
	rm -rf "$(CCPP_BINDIR)/include"                                 ; \
	rm -f $(ccpp_mk)

clean_CCPP:
	set -x                                                          ; \
	cd "$(CCPP_SRCDIR)"                                             ; \
	rm -rf "$(CCPP_SRCDIR)/build"
