# Location of the ESMF makefile fragment for this component:
noah_mk = $(NOAH_BINDIR)/noah.mk
all_component_mk_files+=$(noah_mk)

# Location of source code and installation
NOAH_SRCDIR?=$(ROOTDIR)/NOAH
NOAH_BINDIR?=$(ROOTDIR)/NOAH_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(NOAH_SRCDIR),NOAH source directory)

NOAH_ALL_OPTS= \
  COMP_SRCDIR="$(NOAH_SRCDIR)" \
  COMP_BINDIR="$(NOAH_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_NOAH: $(noah_mk)

$(noah_mk): configure
	+$(MODULE_LOGIC) ; cd $(NOAH_SRCDIR) ; exec $(MAKE)  $(NOAH_ALL_OPTS)
	+$(MODULE_LOGIC) ; cd $(NOAH_SRCDIR) ; exec $(MAKE)  $(NOAH_ALL_OPTS) \
	  DESTDIR=/ "INSTDIR=$(NOAH_BINDIR)" install
	test -d "$(NOAH_BINDIR)"
	test -s $(noah_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_NOAH:
	+cd $(NOAH_SRCDIR) ; exec $(MAKE) -k clean

distclean_NOAH: clean_NOAH
	rm -rf $(NOAH_BINDIR) $(noah_mk)
