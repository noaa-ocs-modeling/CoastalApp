# Location of the ESMF makefile fragment for this component:
cice_mk=$(CICE_BINDIR)/cice.mk
all_component_mk_files+=$(cice_mk)

# Location of source code and installation
CICE_SRCDIR?=$(ROOTDIR)/CICE
CICE_BINDIR?=$(ROOTDIR)/CICE/CICE_INSTALL

CICE_CAPDIR?=$(ROOTDIR)/CICE_CAP

# NEMS_GRID was found in CICE and defaults to a low-res GSM grid
# This is obsolete and perhaps should be removed.
NEMS_GRID?=T126_mx5

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(CICE_SRCDIR),CICE source directory)
$(call require_dir,$(ROOTDIR)/CICE_CAP,CICE cap directory)

ifneq (,$(findstring CMEPS,$(COMPONENTS)))
CPPCMEPS = -DCMEPS
else
CPPCMEPS =
endif

CICE_ALL_OPTS=\
  COMP_SRCDIR=$(CICE_SRCDIR) \
  COMP_BINDIR=$(CICE_BINDIR) \
  SITE="NEMS.$(MACHINE_ID)" \
  SYSTEM_USERDIR="$(CICE_SRCDIR)" \
  SRCDIR="$(CICE_SRCDIR)" \
  EXEDIR="$(CICE_SRCDIR)" \
  CPPCMEPS="$(CPPCMEPS)"  \
  NEMS_GRID="$(NEMS_GRID)"

########################################################################

# Rules for building this component:
$(cice_mk): configure
	$(MODULE_LOGIC)                                                   ; \
	set -eu                                                           ; \
	export $(CICE_ALL_OPTS) $(CICE_MAKEOPT)                           ; \
	cd $(CICE_SRCDIR)                                                 ; \
	./comp_ice.backend
	+$(MODULE_LOGIC) ; cd $(CICE_CAPDIR) ; exec $(MAKE) -f makefile.nuopc    \
	  $(CICE_ALL_OPTS)                                                  \
	  "LANLCICEDIR=$(CICE_SRCDIR)" "INSTALLDIR=$(CICE_BINDIR)" install
	test -f $(cice_mk)

build_CICE: $(cice_mk)

########################################################################

# Rules for cleaning the SRCDIR and BINDIR:

clean_CICE_CAP:
	+cd $(CICE_CAPDIR) ; export ESMFMKFILE=/dev/null                  ; \
	  exec $(MAKE) -f makefile.nuopc clean 
	set -e ; cd $(CICE_CAPDIR) ; set +e                               ; \
	find . -name '*.a' -o -name '*.mod' -o -name '*.o' | xargs rm -f  ; \
	rm -rf cice.mk.install $(CICE_BINDIR)

clean_CICE_SRC:
	set -e ; cd $(CICE_SRCDIR) ; set +e                               ; \
	rm -rf history compile restart *.a                                ; \
	find . -name '*.a' -o -name '*.mod' -o -name '*.o' | xargs rm -f

clean_CICE: clean_CICE_CAP clean_CICE_SRC
distclean_CICE: clean_CICE
	rm -rf $(CICE_BINDIR) $(cice_mk)
