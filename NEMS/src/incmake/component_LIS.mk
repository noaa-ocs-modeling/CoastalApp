# Location of the ESMF makefile fragment for this component:
lis_mk = $(LIS_BINDIR)/lis.mk
all_component_mk_files+=$(lis_mk)

# Location of source code and installation
LIS_SRCDIR?=$(ROOTDIR)/LIS
LIS_BINDIR?=$(ROOTDIR)/LIS_INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(LIS_SRCDIR),LIS source directory)

########################################################################

# LIS Configuration Logic

LIS_CONFIG_FILES=\
  $(LIS_SRCDIR)/make/configure.lis \
  $(LIS_SRCDIR)/make/LIS_misc.h \
  $(LIS_SRCDIR)/make/LIS_NetCDF_inc.h

configure_lis=$(LIS_SRCDIR)/arch/configure.lis.$(MACHINE_ID).debug
LIS_misc_h=$(LIS_SRCDIR)/arch/LIS_misc.h.$(MACHINE_ID)
LIS_NetCDF_inc_h=$(LIS_SRCDIR)/arch/LIS_NetCDF_inc.h.$(MACHINE_ID)

configure_LIS: $(LIS_CONFIG_FILES)

$(LIS_SRCDIR)/make/configure.lis: $(configure_lis)
	cp "$<" "$@"

$(LIS_SRCDIR)/make/LIS_misc.h: $(LIS_misc_h)
	cp "$<" "$@"

$(LIS_SRCDIR)/make/LIS_NetCDF_inc.h: $(LIS_NetCDF_inc_h)
	cp "$<" "$@"

LIS_ALL_OPTS= \
  COMP_SRCDIR="$(LIS_SRCDIR)" \
  COMP_BINDIR="$(LIS_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################

# Rule for building this component:
build_LIS: $(lis_mk)

$(lis_mk): configure $(configure_LIS)
	$(MODULE_LOGIC) ; export $(LIS_ALL_OPTS)                      ; \
	set -xue                                                      ; \
	cd $(LIS_SRCDIR)                                              ; \
	./compile
	+$(MODULE_LOGIC) ; cd "$(LIS_SRCDIR)/runmodes/nuopc_cpl_mode" ; 
	   exec make $(LIS_ALL_OPTS)
	+$(MODULE_LOGIC) ; cd "$(LIS_SRCDIR)/runmodes/nuopc_cpl_mode" ; \
	  exec make $(LIS_ALL_OPTS) DESTDIR=/ "INSTDIR=$(LIS_BINDIR)"   \
	  install
	test -d "$(LIS_BINDIR)"

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:
clean_LIS:
	+-cd $(LIS_SRCDIR)/make ; exec $(MAKE) -k $(LIS_ALL_OPTS) clean

distclean_LIS: clean_LIS
	rm -rf $(LIS_BINDIR) $(lis_mk)
