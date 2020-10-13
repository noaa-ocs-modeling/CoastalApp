# Location of the ESMF makefile fragment for this component:
imp_mk = $(IMP_BINDIR)/imp.mk
all_component_mk_files+=$(imp_mk)

# Location of source code and installation
IMP_SRCDIR?=$(ROOTDIR)/IMP
IMP_BINDIR?=$(ROOTDIR)/IMP_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(IMP_SRCDIR),IMP source directory)

IMP_ALL_OPTS= \
  COMP_SRCDIR="$(IMP_SRCDIR)" \
  COMP_BINDIR="$(IMP_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_IMP: $(imp_mk)

$(imp_mk): configure
	+$(MODULE_LOGIC) ; cd $(IMP_SRCDIR) ; exec $(MAKE)  $(IMP_ALL_OPTS)
	+$(MODULE_LOGIC) ; cd $(IMP_SRCDIR) ; exec $(MAKE)  $(IMP_ALL_OPTS) \
	  DESTDIR=/ "INSTDIR=$(IMP_BINDIR)" install
	test -d "$(IMP_BINDIR)"
	test -s $(imp_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_IMP:
	+cd $(IMP_SRCDIR) ; exec $(MAKE) -k clean

distclean_IMP: clean_IMP
	rm -rf $(IMP_BINDIR) $(imp_mk)

