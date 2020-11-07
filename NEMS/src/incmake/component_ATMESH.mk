
# Location of the ESMF makefile fragment for this component:
atmesh_mk = $(ATMESH_BINDIR)/atmesh.mk
all_component_mk_files+=$(atmesh_mk)

# Location of source code and installation
ATMESH_SRCDIR?=$(ROOTDIR)/ATMESH
ATMESH_BINDIR?=$(ROOTDIR)/ATMESH_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(ATMESH_SRCDIR), ATMESH source directory)

WW3_ALL_OPTS= \
  COMP_SRCDIR="$(ATMESH_SRCDIR)" \
  COMP_BINDIR="$(ATMESH_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_ATMESH: $(atmesh_mk)

$(atmesh_mk): configure
	+$(MODULE_LOGIC) ; cd $(ATMESH_SRCDIR) ; exec $(MAKE) -f makefile.atmesh.nuopc nuopc
	+$(MODULE_LOGIC) ; cd $(ATMESH_SRCDIR) ; exec $(MAKE) -f makefile.atmesh.nuopc \
	  DESTDIR=/ "INSTDIR=$(ATMESH_BINDIR)" nuopcinstall
	test -d "$(ATMESH_BINDIR)"
	test -s $(atmesh_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_ATMESH:
	+cd $(ATMESH_SRCDIR) ; exec $(MAKE) -f makefile.atmesh.nuopc nuopcclean

distclean_ATMESH: clean_ATMESH
	rm -rf $(ATMESH_BINDIR)

