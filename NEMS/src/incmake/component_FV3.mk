# Location of the ESMF makefile fragment for this component:
fv3_mk=$(FV3_BINDIR)/fv3.mk
all_component_mk_files+=$(fv3_mk)

# Location of source code and installation
FV3_SRCDIR?=$(ROOTDIR)/FV3
FV3_BINDIR?=$(ROOTDIR)/FV3/FV3_INSTALL

# Make sure the source directory exists and is non-empty
$(call require_dir,$(FV3_SRCDIR),FV3 source directory)

# Make sure we're setting CCPP=Y if CCPP is enabled:
ifneq (,$(findstring CCPP,$(COMPONENTS)))
  ifeq (,$(findstring CCPP=Y,$(FV3_MAKEOPT)))
    $(warning Adding CCPP=Y to FV3 make options because CCPP is listed as a component.)
    override FV3_MAKEOPT += CCPP=Y
  endif
  ifeq (,$(findstring PATH_CCPP=,$(FV3_MAKEOPT)))
    $(warning Adding PATH_CCPP to FV3 make options because CCPP is listed as a component.)
    override FV3_MAKEOPT += PATH_CCPP="$(CCPP_BINDIR)"
  endif
endif

FV3_FULL_OPTS=\
  COMP=FV3 \
  COMP_SRCDIR=$(FV3_SRCDIR) \
  COMP_BINDIR=$(FV3_BINDIR) \
  MACHINE_ID=$(MACHINE_ID) \
  FMS_DIR=$(FMS_BINDIR) \
  $(FV3_MAKEOPT)

# Rule for building this component:
build_FV3: $(fv3_mk)

$(fv3_mk): $(fms_mk) configure
	cp -fp $(NEMSDIR)/src/conf/configure.nems \
	       "$(FV3_SRCDIR)"/conf/configure.fv3
	cp -fp $(NEMSDIR)/src/conf/modules.nems   \
	       "$(FV3_SRCDIR)"/conf/modules.fv3
	$(info Compiling $(FV3_MAKEOPT) into $(FV3_BINDIR) on $(MACHINE_ID))
	+$(MODULE_LOGIC) ; cd $(FV3_SRCDIR) ; \
	  exec $(MAKE) $(FV3_FULL_OPTS) nemsinstall
	test -d $(FV3_BINDIR)

# Rule for cleaning the SRCDIR and BINDIR:
clean_FV3:
	cat /dev/null > $(FV3_SRCDIR)/conf/configure.fv3
	cat /dev/null > $(FV3_SRCDIR)/conf/modules.fv3
	+cd $(FV3_SRCDIR) ; exec $(MAKE) $(FV3_FULL_OPTIONS)         \
	  -k cleanall FMS_DIR=/dev/null
	rm -rf nems_dir FV3_INSTALL $(FV3_SRCDIR)/conf/configure.fv3 \
	    $(FV3_SRCDIR)/conf/modules.fv3

distclean_FV3: clean_FV3
	rm -rf $(FV3_BINDIR) $(fv3_mk)
