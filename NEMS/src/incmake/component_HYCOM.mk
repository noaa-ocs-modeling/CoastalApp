# Location of the ESMF makefile fragment for this component:
hycom_mk=$(HYCOM_BINDIR)/hycom_nuopc.mk
all_component_mk_files+=$(hycom_mk)

# Location of source code and installation
HYCOM_SRCDIR?=$(ROOTDIR)/HYCOM
HYCOM_BINDIR?=$(ROOTDIR)/HYCOM-INSTALL

ifeq ($(MACHINE_ID),linux_gnu)
  HYCOM_ARCH=Alinux-gnu-relo
else
  HYCOM_ARCH=Aintelrelo
endif

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(HYCOM_SRCDIR),HYCOM source directory)

HYCOM_ALL_OPTS=\
  HYCOM_ARCH=$(HYCOM_ARCH) \
  COMP_BINDIR=$(HYCOM_BINDIR) \
  COMP_SRCDIR=$(HYCOM_SRCDIR)

########################################################################

# Rules for building this component:

$(hycom_mk): configure
	+$(MODULE_LOGIC) ; cd "$(HYCOM_SRCDIR)/sorc" ; exec $(MAKE)         \
	  ARCH="$(HYCOM_ARCH)" TYPE=nuopc nuopc
	+-$(MODULE_LOGIC) ; cd "$(HYCOM_SRCDIR)/sorc" ; exec $(MAKE)        \
	  ARCH="$(HYCOM_ARCH)" TYPE=nuopc DESTDIR=/                         \
	  INSTDIR="$(HYCOM_BINDIR)" nuopcinstall
	test -d "$(HYCOM_BINDIR)"
	test -s "$(hycom_mk)"

# Note that we do not check the return status of nuopcinstall because
# it always fails.  There is a syntax error in one of the makefile
# rules within HYCOM/sorc/Makefile.  The sole purpose of the command
# is to create the $(hycom_mk) so as long as that is there, the
# nuopcinstall succeeded.

build_HYCOM: $(hycom_mk)

########################################################################

# Rules for cleaning the SRCDIR and BINDIR:

clean_HYCOM:
	-+cd $(HYCOM_SRCDIR) ; exec $(MAKE) $(HYCOM_ALL_OPTS)              \
	  ARCH="$$HYCOM_ARCH" TYPE=nuopc clean

distclean_HYCOM: clean_HYCOM
	rm -rf $(HYCOM_BINDIR) $(hycom_mk)
