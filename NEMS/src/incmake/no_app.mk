ifeq ($(app),)
  # User wants to specify arguments manually
  ifeq ($(COMPONENTS),)
    define app_error
No COMPONENTS list and no app specified.
You must either:

1. Specify an appBuilder file: make app=whatever
2. OR specify a component list: make COMPONENTS="FMS FV3 MOM6 CICE WW3"

Give me components
    endef
    ${error $(app_error)}
  endif

  $(info NOTE: Skipping appbuilder.mk creation; no appbuilder file in use.)
endif
