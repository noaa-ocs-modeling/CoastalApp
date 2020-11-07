# Location of the ESMF makefile fragment for this component:
gsdchem_mk = $(GSDCHEM_BINDIR)/gsdchem.mk
all_component_mk_files+=$(gsdchem_mk)

# Location of source code and installation
GSDCHEM_SRCDIR?=$(ROOTDIR)/GSDCHEM
GSDCHEM_BINDIR?=$(ROOTDIR)/GSDCHEM/GSDCHEM_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(GSDCHEM_SRCDIR),GSDCHEM source directory)

ifneq (,$(findstring DEBUG=Y,$(GSDCHEM_MAKEOPT)))
  override GSDCHEM_CONFOPT += --enable-debug
endif

########################################################################

# Rule for building this component:

build_GSDCHEM: $(gsdchem_mk)

$(gsdchem_mk): configure
	$(MODULE_LOGIC) ; export $(GSDCHEM_ALL_OPTS)                  ; \
	set -e                                                        ; \
	cd $(GSDCHEM_SRCDIR)                                          ; \
	./configure --prefix=$(GSDCHEM_BINDIR)                          \
	  --datarootdir=$(GSDCHEM_BINDIR) --libdir=$(GSDCHEM_BINDIR)    \
          $(GSDCHEM_CONFOPT)
	+$(MODULE_LOGIC) ; cd $(GSDCHEM_SRCDIR) ; exec $(MAKE)
	+$(MODULE_LOGIC) ; cd $(GSDCHEM_SRCDIR) ; exec $(MAKE) install
	test -d "$(GSDCHEM_BINDIR)"

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_GSDCHEM:
	+cd $(GSDCHEM_SRCDIR) ; test -f Makefile && exec $(MAKE) -k distclean || echo "Nothing to clean up"

distclean_GSDCHEM: clean_GSDCHEM
	rm -rf $(GSDCHEM_BINDIR) $(gsdchem_mk)
