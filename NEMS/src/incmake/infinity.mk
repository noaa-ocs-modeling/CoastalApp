# A missing "cd" in a build or clean rule for a component can lead to
# infinite recursion in the NEMS/GNUmakefile.  This safeguard detects
# that and gives an informative error message

ifeq ($(_NEMS_MAKE_RECURSION_DETECT),X X)
$(error Erroneous make recursion detected.  Check for a missing "cd" in a rule before a call to make)
endif

override _NEMS_MAKE_RECURSION_DETECT+=X
export _NEMS_MAKE_RECURSION_DETECT
