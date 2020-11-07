# Location of the ESMF makefile fragment for this component:
mom5_mk = $(MOM5_BINDIR)/mom5.mk
all_component_mk_files+=$(mom5_mk)

# Location of source code and installation
MOM5_SRCDIR?=$(ROOTDIR)/MOM5
MOM5_CAPDIR?=$(ROOTDIR)/MOM5_CAP
MOM5_BINDIR?=$(ROOTDIR)/MOM5-INSTALL

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(MOM5_SRCDIR),MOM5 source directory)
$(call require_dir,$(ROOTDIR)/MOM5_CAP,MOM5 cap directory)

# Ensure that Make knows these rules do not correspond to files to be built:
.PHONY: clean_CICE_CAP clean_CICE_SRC

# Rule for building this component:
build_MOM5: $(mom5_mk)

$(mom5_mk): configure
	$(MODULE_LOGIC)                                             ; \
	set -e                                                      ; \
	cd "$(MOM5_SRCDIR)/exp"                                     ; \
	./MOM_compile.csh --platform "$(MACHINE_ID)"                  \
	                  --type MOM_solo --experiment box1
	+$(MODULE_LOGIC) ; cd $(MOM5_CAPDIR) ; exec $(MAKE)           \
	  -f $(MOM5_CAPDIR)/makefile.nuopc                            \
	  "NEMSMOMDIR=$(MOM5_SRCDIR)/exec/$(MACHINE_ID)"              \
	  "INSTALLDIR=$(MOM5_BINDIR)" install
	test -d "$(MOM5_BINDIR)"

# Rule for cleaning the SRCDIR and BINDIR:
clean_MOM5:
	set -e                                                           ; \
	cd $(MOM5_SRCDIR)                                                ; \
	set +e                                                           ; \
	rm -rf exec src/path_names_shared                                ; \
	find . -name '*.o' -o -name '*.mod' -o -name '*.a' | xargs rm -f ; \
	cd $(MOM5_CAPDIR)                                                ; \
	find . -name '*.o' -o -name '*.mod' -o -name '*.a' | xargs rm -f

distclean_MOM5:
	rm -rf $(MOM5_BINDIR) $(mom5_mk)
	rm -f $(MOM5_CAPDIR)/mom5.mk.install
