# Location of the ESMF makefile fragment for this component:
noahmp_mk = $(NOAHMP_BINDIR)/noahmp.mk
all_component_mk_files+=$(noahmp_mk)

# Location of source code and installation
NOAHMP_SRCDIR?=$(ROOTDIR)/NOAHMP
NOAHMP_BINDIR?=$(ROOTDIR)/NOAHMP_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(NOAHMP_SRCDIR),NOAHMP source directory)

NOAHMP_ALL_OPTS= \
  COMP_SRCDIR="$(NOAHMP_SRCDIR)" \
  COMP_BINDIR="$(NOAHMP_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_NOAHMP: $(noahmp_mk)

$(noahmp_mk): configure
	+$(MODULE_LOGIC) ; cd $(NOAHMP_SRCDIR) ; exec $(MAKE)  $(NOAHMP_ALL_OPTS)
	+$(MODULE_LOGIC) ; cd $(NOAHMP_SRCDIR) ; exec $(MAKE)  $(NOAHMP_ALL_OPTS) \
	  DESTDIR=/ "INSTDIR=$(NOAHMP_BINDIR)" install
	test -d "$(NOAHMP_BINDIR)"
	test -s $(noahmp_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_NOAHMP:
	+cd $(NOAHMP_SRCDIR) ; exec $(MAKE) -k clean

distclean_NOAHMP: clean_NOAHMP
	rm -rf $(NOAHMP_BINDIR) $(noahmp_mk)
