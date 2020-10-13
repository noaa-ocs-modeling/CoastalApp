
# Location of the ESMF makefile fragment for this component:
ww3data_mk = $(WW3DATA_BINDIR)/ww3data.mk
all_component_mk_files+=$(ww3data_mk)

# Location of source code and installation
WW3DATA_SRCDIR?=$(ROOTDIR)/WW3DATA
WW3DATA_BINDIR?=$(ROOTDIR)/WW3DATA_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(WW3DATA_SRCDIR),WW3data source directory)

WW3_ALL_OPTS= \
  COMP_SRCDIR="$(WW3DATA_SRCDIR)" \
  COMP_BINDIR="$(WW3DATA_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_WW3DATA: $(ww3data_mk)

$(ww3data_mk): configure
	+$(MODULE_LOGIC) ; cd $(WW3DATA_SRCDIR) ; exec $(MAKE) -f makefile.ww3data.nuopc nuopc
	+$(MODULE_LOGIC) ; cd $(WW3DATA_SRCDIR) ; exec $(MAKE) -f makefile.ww3data.nuopc \
	  DESTDIR=/ "INSTDIR=$(WW3DATA_BINDIR)" nuopcinstall
	test -d "$(WW3DATA_BINDIR)"
	test -s $(ww3data_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_WW3DATA:
	+cd $(WW3DATA_SRCDIR) ; exec $(MAKE) -f makefile.ww3data.nuopc nuopcclean

distclean_WW3DATA: clean_WW3DATA
	rm -rf $(WW3DATA_BINDIR)
