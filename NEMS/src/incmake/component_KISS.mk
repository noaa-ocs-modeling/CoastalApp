# Location of the ESMF makefile fragment for this component:
kiss_mk = $(KISS_BINDIR)/kiss.mk
all_component_mk_files+=$(kiss_mk)

# Location of source code and installation
KISS_SRCDIR?=$(ROOTDIR)/KISS
KISS_BINDIR?=$(ROOTDIR)/KISS_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(KISS_SRCDIR),KISS source directory)

KISS_ALL_OPTS= \
  COMP_SRCDIR="$(KISS_SRCDIR)" \
  COMP_BINDIR="$(KISS_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_KISS: $(kiss_mk)

$(kiss_mk): configure
	+$(MODULE_LOGIC) ; cd $(KISS_SRCDIR) ; exec $(MAKE)  $(KISS_ALL_OPTS)
	+$(MODULE_LOGIC) ; cd $(KISS_SRCDIR) ; exec $(MAKE)  $(KISS_ALL_OPTS) \
	  DESTDIR=/ "INSTDIR=$(KISS_BINDIR)" install
	test -d "$(KISS_BINDIR)"
	test -s $(kiss_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_KISS:
	+cd $(KISS_SRCDIR) ; exec $(MAKE) -k clean

distclean_KISS: clean_KISS
	rm -rf $(KISS_BINDIR) $(kiss_mk)

