# Location of the ESMF makefile fragment for this component:
fms_mk=$(FMS_BINDIR)/fms.mk
all_component_mk_files+=$(fms_mk)

# Location of source code and installation
FMS_SRCDIR?=$(ROOTDIR)/FMS
FMS_BINDIR?=$(ROOTDIR)/FMS/FMS_INSTALL

# Make sure the source directory exists and is non-empty
$(call require_dir,$(FMS_SRCDIR),FMS source directory)

# Default make options are the same as FV3's if FV3 is included:
ifneq (,$(findstring FV3,$(COMPONENTS)))
  $(info Adding FV3 makeopts to FMS makeopts)
  FMS_MAKEOPT ?= $(FV3_MAKEOPT)
endif

# There is a bug in the FMS/fv3gfs/makefile: it uses $PWD to get the
# current working directory.  That variable is not updated when using
# the make "-C" option.  This leads to FMS_INSTALL being in the wrong
# place.  The workaround is to explicitly "cd" instead of "-C"

########################################################################

# Rule for building this component:
build_FMS: $(fms_mk)

$(fms_mk): configure
	+$(MODULE_LOGIC) ; cd $(FMS_SRCDIR)/fv3gfs                      ; \
	exec $(MAKE) $(FMS_MAKEOPT) all
	test -d $(FMS_BINDIR)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:
clean_FMS:
	cat $(FMS_SRCDIR)/fv3gfs/makefile | sed 's,^include,#include,g'   \
	  > $(FMS_SRCDIR)/fv3gfs/makefile.temp.clean
	+-cd $(FMS_SRCDIR)/fv3gfs                                       ; \
	    exec $(MAKE) $(FMS_MAKEOPT) -f makefile.temp.clean clean

distclean_FMS: clean_FMS
	rm -rf $(FMS_BINDIR) $(fms_mk) $(FMS_SRCDIR)/fv3gfs/makefile.temp.clean
