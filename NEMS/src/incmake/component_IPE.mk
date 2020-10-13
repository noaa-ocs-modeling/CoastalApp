# Location of the ESMF makefile fragment for this component:
ipe_mk = $(IPE_BINDIR)/ipe.mk
all_component_mk_files+=$(ipe_mk)

# Location of source code and installation
IPE_SRCDIR?=$(ROOTDIR)/IPE
IPE_BINDIR?=$(ROOTDIR)/IPE_INSTALL
IPE_LIBSRCDIR=$(IPE_SRCDIR)LIB

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(IPE_SRCDIR),IPE source directory)

# Rule for building this component:
build_IPE: $(ipe_mk)

IPE_CONFIGURATION=$(MACHINE_ID)_$(NEMS_COMPILER)_parallel

IPE_ALL_OPTS= \
  COMP_SRCDIR="$(IPE_SRCDIR)" \
  COMP_LIBSRCDIR="$(IPE_LIBSRCDIR)" \
  COMP_BINDIR="$(IPE_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

$(ipe_mk): configure
	set -xue                                                     ; \
	cd "$(IPE_LIBSRCDIR)"                                        ; \
	mkdir -p include lib bin
	+$(MODULE_LOGIC) ; cd $(IPE_LIBSRCDIR) ; exec $(MAKE)          \
	  $(IPE_ALL_OPTS) $(IPE_CONFIGURATION)
	+$(MODULE_LOGIC) ; cd $(IPE_SRCDIR) ; exec $(MAKE)             \
	  $(IPE_ALL_OPTS) IPE="$(IPE_LIBSRCDIR)" nuopc
	+$(MODULE_LOGIC) ; cd $(IPE_SRCDIR) ; exec $(MAKE)             \
	  $(IPE_ALL_OPTS) IPE="$(IPE_LIBSRCDIR)"                       \
	  IPE="$(IPE_LIBSRCDIR)" DESTDIR=/ "INSTDIR=$(IPE_BINDIR)"     \
	    nuopcinstall
	test -d "$(IPE_BINDIR)"
	test -s "$(ipe_mk)"

# Rule for cleaning the SRCDIR and BINDIR:
clean_IPE:
	+-cd $(IPE_LIBSRCDIR) ; exec $(MAKE) -k clean
	+-cd $(IPE_SRCDIR)    ; exec $(MAKE) -k clean

distclean_IPE: clean_IPE
	rm -rf $(IPE_BINDIR) $(ipe_mk)
