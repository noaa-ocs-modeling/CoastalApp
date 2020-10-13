# Location of the ESMF makefile fragment for this component:
datm_mk = $(DATM_BINDIR)/datm.mk
all_component_mk_files+=$(datm_mk)

# Location of source code and installation
DATM_SRCDIR?=$(ROOTDIR)/DATM
DATM_BINDIR?=$(ROOTDIR)/DATM_INSTALL
DATM_LIBSRCDIR=$(DATM_SRCDIR)LIB

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(DATM_SRCDIR),DATM source directory)

DATM_ALL_FLAGS=\
  COMP_SRCDIR="$(DATM_SRCDIR)" \
  COMP_BINDIR="$(DATM_BINDIR)"

# Rule for building this component:
build_DATM: $(datm_mk)

$(datm_mk): configure
	+$(MODULE_LOGIC) ; cd $(DATM_SRCDIR) ; exec $(MAKE) $(DATM_ALL_FLAGS)
	+$(MODULE_LOGIC) ; cd $(DATM_SRCDIR) ; exec $(MAKE) $(DATM_ALL_FLAGS) \
	    DESTDIR=/ "INSTDIR=$(DATM_BINDIR)" install
	test -d "$(DATM_BINDIR)"

# Rule for cleaning the SRCDIR and BINDIR:
clean_DATM:
	+cd $(DATM_SRCDIR) ; exec $(MAKE) -k clean

distclean_DATM: clean_DATM
	rm -rf $(DATM_BINDIR) $(datm_mk)

