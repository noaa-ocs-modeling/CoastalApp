# Location of the ESMF makefile fragment for this component:
nwm_mk = $(NWM_BINDIR)/nwm.mk
all_component_mk_files+=$(nwm_mk)

# Location of source code and installation
NWM_SRCDIR?=$(ROOTDIR)/NWM/trunk/NDHMS
NWM_BINDIR?=$(ROOTDIR)/NWM_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(NWM_SRCDIR),NWM source directory)


# Rule for building this component:
build_NWM: $(nwm_mk)


env_file=$(NWM_SRCDIR)/setEnvar.sh
esmf_env=$(NWM_SRCDIR)/esmf-impi-env.sh
comp_opt=3

# HOW to source env here??
#
NWM_ALL_OPTS= \
  COMP_SRCDIR="$(NWM_SRCDIR)" \
  COMP_BINDIR="$(NWM_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"


$(nwm_mk): configure $(CONFDIR)/configure.nems
	@echo ""
	+$(MODULE_LOGIC) ; cd $(NWM_SRCDIR) ; exec ./compile_nuopc_NoahMP.sh $(env_file) $(esmf_env) $(comp_opt)
	+$(MODULE_LOGIC) ; cd $(NWM_SRCDIR)/CPL/NUOPC_cpl ; exec $(MAKE) -f Makefile nuopcinstall \
	  $(NWM_ALL_OPTS) DESTDIR=/ "INSTDIR=$(NWM_BINDIR)" 
	@echo ""
	test -d "$(NWM_BINDIR)"
	@echo ""
	test -s $(nwm_mk)

# Rule for cleaning the SRCDIR and BINDIR:
clean_NWM:
	@echo ""
	+-cd $(NWM_SRCDIR) ; exec $(MAKE) -f Makefile.nuopc nuopcclean

distclean_NWM: clean_NWM
	@echo ""
	rm -rf $(NWM_BINDIR)

distclean_NUOPC: 
	@echo ""
	+-cd $(NWM_SRCDIR) ; exec $(MAKE) -C CPL/NUOPC_cpl -f Makefile nuopcclean
	rm -rf $(NWM_BINDIR)

