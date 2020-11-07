
$(CONFDIR)/test-results.mk:
	+$(MAKE) -f $(NEMSDIR)/src/incmake/tests.mk    \
	      MODULE_LOGIC="$(MODULE_LOGIC)"           \
	      TARGET="$(CONFDIR)/test-results.mk" TEST
	$(eval include $(CONFDIR)/test-results.mk)

########################################################################

# Copy the configure.nems, externals.nems, and ESMFVersionDefine.h

$(CONFDIR)/configure.nems: $(CONFIGURE_NEMS_FILE)
	cp $(CONFIGURE_NEMS_FILE) $@

ifneq ($(EXTERNALS_NEMS_FILE),)
$(CONFDIR)/externals.nems: $(EXTERNALS_NEMS_FILE)
	cp $(EXTERNALS_NEMS_FILE) $@
else
$(CONFDIR)/externals.nems:
	cat /dev/null > $@
endif

$(NEMSDIR)/src/ESMFVersionDefine.h:
	cp $(ESMF_VERSION_DEFINE) $@

########################################################################

# Copy modules.nems and figure out how to load them.  Put that
# information into modules.nems.sh, modules.nems.csh, and
# $(MODULE_LOGIC)

ifneq ($(CHOSEN_MODULE),)
$(CONFDIR)/modules.nems: $(MODULE_DIR)/$(CHOSEN_MODULE)
	cp $(MODULE_DIR)/$(CHOSEN_MODULE) $@
else
$(CONFDIR)/modules.nems:
	cat /dev/null > $@
endif

ifeq ($(USE_MODULES),YES)
# Generate scripts to load modules via the "module" command.
$(CONFDIR)/modules.nems.sh:
	( echo '. $(CONFDIR)/module-setup.sh.inc' ; \
	echo 'module use $(CONFDIR)' ; \
	echo 'module load modules.nems' ) > "$@"
$(CONFDIR)/modules.nems.csh:
	( echo 'source $(CONFDIR)/module-setup.csh.inc' ; \
	echo 'module use $(CONFDIR)' ; \
	echo 'module load modules.nems' ) > "$@"
else
# Generate scripts that source the module files.
$(CONFDIR)/modules.nems.sh:
	( echo '. $(CONFDIR)/modules.nems' ) > "$@"
$(CONFDIR)/modules.nems.csh:
	( echo 'source $(CONFDIR)/modules.nems' ) > "$@"
endif

########################################################################

# Top-level rules

# configure_NEMS: Generate NEMS configuration files
configure_NEMS: $(NEMS_CONF_FILES)

# unconfigure: Delete all NEMS configuration files
unconfigure_NEMS:
	rm -f $(NEMS_CONF_FILES)

# Test the module support.
module_test: $(CONFDIR)/modules.nems
	$(MODULE_LOGIC) ; \
	env | grep ESMF

# configure: Generate all configuration files
configure: configure_NEMS

# unconfigure: delete all configuration files
unconfigure: unconfigure_NEMS

.PHONY: configure_NEMS unconfigure_NEMS module_test configure unconfigure
