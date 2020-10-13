# Location of the ESMF makefile fragment for this component:
gsm_mk=$(GSM_BINDIR)/gsm.mk
all_component_mk_files+=$(gsm_mk)

# Location of source code and installation
GSM_SRCDIR?=$(ROOTDIR)/GSM
GSM_BINDIR?=$(ROOTDIR)/GSM-INSTALL

# Make sure the source directory exists and is non-empty
$(call require_dir,$(GSM_SRCDIR),GSM source directory)

GSM_CONFIGURATION=gsm_$(NEMS_COMPILER)_$(MACHINE_ID)

ifneq (,$(findstring GOCART,$(GSM_MAKEOPT)))
  $(warning GOCART enabled for GSM.  Adding GOCART_MODE=full to NEMS_MAKEOPT.)
  override GSM_MAKEOPT  := $(filter-out GOCART,$(GSM_MAKEOPT))
  override NEMS_MAKEOPT += GOCART_MODE=full
  $(warning GSM_MAKEOPT=($(GSM_MAKEOPT)) NEMS_MAKEOPT=($(NEMS_MAKEOPT)))
endif

# Rule for building this component:
build_GSM: $(gsm_mk)

$(gsm_mk): configure
	$(MODULE_LOGIC) ; \
	set -e                                                      ; \
	cd "$(GSM_SRCDIR)"                                          ; \
	./configure $(GSM_CONFIGURATION)                            ; \
	test -s conf/configure.nems
	+$(MODULE_LOGIC) ; cd $(GSM_SRCDIR)                         ; \
	  exec $(MAKE) GSM_DIR=$(GSM_SRCDIR)                          \
	  $(GSM_BUILDOPT) DESTDIR= INSTDIR=$(GSM_BINDIR) nuopcinstall

# Rule for cleaning the SRCDIR and BINDIR:
clean_GSM:
	set -e                                                      ; \
	cd "$(GSM_SRCDIR)"                                          ; \
	set +e                                                      ; \
	./configure gsm_$(GSM_CONFIGURATION)
	+-cd $(GSM_SRCDIR) ; exec $(MAKE) -k GSM_DIR=$(GSM_SRCDIR)    \
	  nuopcdistclean

distclean_GSM: clean_GSM
	rm -rf $(GSM_BINDIR) $(gsm_mk)
