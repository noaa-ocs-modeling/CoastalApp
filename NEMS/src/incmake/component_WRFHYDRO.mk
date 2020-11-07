# Location of the ESMF makefile fragment for this component:
wrfhydro_mk = $(WRFHYDRO_BINDIR)/wrfhydro.mk
all_component_mk_files+=$(wrfhydro_mk)

# Location of source code and installation
WRFHYDRO_SRCDIR?=$(ROOTDIR)/WRFHYDRO
WRFHYDRO_BINDIR?=$(ROOTDIR)/WRFHYDRO_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(WRFHYDRO_SRCDIR),WRFHYDRO source directory)

# Rule for building this component:
build_WRFHYDRO: $(wrfhydro_mk)

WRFHYDRO_ALL_OPTS= \
  HYDRO_D=1 \
  WRF_HYDRO=1 \
  COMP_SRCDIR="$(WRFHYDRO_SRCDIR)" \
  COMP_BINDIR="$(WRFHYDRO_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

$(wrfhydro_mk): configure
	+$(MODULE_LOGIC) ; cd $(WRFHYDRO_SRCDIR) ; exec $(MAKE)         \
	  $(WRFHYDRO_ALL_OPTS) nuopc
	+$(MODULE_LOGIC) ; cd $(WRFHYDRO_SRCDIR) ; exec $(MAKE)         \
	  $(WRFHYDRO_ALL_OPTS) DESTDIR=/ "INSTDIR=$(WRFHYDRO_BINDIR)"   \
	  nuopcinstall
	test -d "$(WRFHYDRO_BINDIR)"

# Rule for cleaning the SRCDIR and BINDIR:
clean_WRFHYDRO:
	+-cd $(WRFHYDRO_SRCDIR) ; exec $(MAKE) -k nuopcclean

distclean_WRFHYDRO: clean_WRFHYDRO
	rm -rf $(WRFHYDRO_BINDIR) $(wrfhydro_mk)
