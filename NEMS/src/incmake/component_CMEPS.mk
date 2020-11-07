# Location of the ESMF makefile fragment for this component:
cmeps_mk = $(CMEPS_BINDIR)/cmeps.mk
all_component_mk_files+=$(cmeps_mk)

# Location of source code and installation
CMEPS_SRCDIR?=$(ROOTDIR)/CMEPS
CMEPS_BINDIR?=$(ROOTDIR)/CMEPS_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(CMEPS_SRCDIR),CMEPS source directory)

ifndef CONFIGURE_NEMS_FILE
$(error CONFIGURE_NEMS_FILE not set.)
endif

include $(CONFIGURE_NEMS_FILE)

# Rule for building this component:
build_CMEPS: $(cmeps_mk)

CMEPS_ALL_OPTS=\
  COMP_SRCDIR="$(CMEPS_SRCDIR)" \
  COMP_BINDIR="$(CMEPS_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)" \
  FC="$(FC)" \
  CC="$(CC)" \
  CXX="$(CXX)"

$(cmeps_mk): configure
	$(MODULE_LOGIC) ; export $(CMEPS_ALL_OPTS)         ; \
	set -e                                             ; \
	$(MODULE_LOGIC) ; cd $(CMEPS_SRCDIR)               ; \
	  exec $(MAKE) $(CMEPS_ALL_OPTS)                     \
	  "INSTALLDIR=$(CMEPS_BINDIR)" install
	test -d "$(CMEPS_BINDIR)"
	test -s "$(cmeps_mk)"

# Rule for cleaning the SRCDIR and BINDIR:
clean_CMEPS: 
	$(MODULE_LOGIC) ; export $(CMEPS_ALL_OPTS)         ; \
	set -e                                             ; \
	cd $(CMEPS_SRCDIR)                                 ; \
	exec $(MAKE) clean

distclean_CMEPS: clean_CMEPS
	rm -rf $(CMEPS_BINDIR)
	rm -f $(cmeps_mk)
