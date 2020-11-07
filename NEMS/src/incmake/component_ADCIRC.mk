########################################################################

# Location of the ESMF makefile fragment for this component:
adcirc_mk = $(ADCIRC_BINDIR)/adcirc.mk
all_component_mk_files+=$(adcirc_mk)

# Location of source code and installation
ADCIRC_SRCDIR?=$(ROOTDIR)/ADCIRC
ADCIRC_BINDIR?=$(ROOTDIR)/ADCIRC_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(ADCIRC_SRCDIR),ADCIRC source directory)

# ENV for ADCIRC - exchange with NEMS ENV
esmf_env=$(ADCIRC_SRCDIR)/work/esmf-impi-env.sh   # this is same as configure.nems, should be removed!
comp_option=intel                       

ADCIRC_ALL_OPTS= \
  COMP_SRCDIR="$(ADCIRC_SRCDIR)" \
  COMP_BINDIR="$(ADCIRC_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:

build_ADCIRC: $(adcirc_mk)


$(adcirc_mk): configure $(CONFDIR)/configure.nems   
	+$(MODULE_LOGIC) ; cd $(ADCIRC_SRCDIR)/work; exec ./make_nuopc.sh $(esmf_env) $(comp_option)
	+$(MODULE_LOGIC) ; cd $(ADCIRC_SRCDIR)/thirdparty/nuopc ; exec $(MAKE) $(ADCIRC_ALL_OPTS) -f makefile.adc_cap.nuopc nuopcinstall \
          DESTDIR=/ "INSTDIR=$(ADCIRC_BINDIR)"
#	+$(MODULE_LOGIC) ; cd $(ADCIRC_SRCDIR)/cpl/nuopc ; exec $(MAKE) $(ADCIRC_ALL_OPTS) -f makefile.adc_cap.nuopc nuopcinstall \
#          DESTDIR=/ "INSTDIR=$(ADCIRC_BINDIR)"
	@echo ""
	test -d "$(ADCIRC_BINDIR)"
	@echo ""
	test -s $(adcirc_mk)
	@echo ""

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_ADCIRC:
#	+cd $(ADCIRC_SRCDIR)/work ; exec $(MAKE) -k clean
	+cd $(ADCIRC_SRCDIR)/work ; exec $(MAKE) -k clobber
	@echo ""

distclean_ADCIRC: clean_ADCIRC
	rm -rf $(ADCIRC_BINDIR)
	@echo ""

distclean_NUOPC:
	+cd $(ADCIRC_SRCDIR)/thirdparty/nuopc ; exec rm -f *.o *.mod libadc_cap.a adcirc.mk
	rm -rf $(ADCIRC_BINDIR)
	@echo ""
#	+cd $(ADCIRC_SRCDIR)/cpl/nuopc ; exec rm -f *.o *.mod libadc_cap.a adcirc.mk
#	rm -rf $(ADCIRC_BINDIR)
#	@echo ""
