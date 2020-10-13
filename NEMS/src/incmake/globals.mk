# Alias for the empty string.  Do not change:
override empty=

# Aliases for special characters in functions.  Do not change:
override comma=,
override dollar=$$
override percent=%
override semicolon=;
override space=$(empty) $(empty)
override lparen=(
override rparen=)

# Where to find component files
MAKE_INCLUDE_DIRS=$(ROOTDIR)/conf $(NEMSDIR)/src/incmake

# Destination of various configuration files:
CONFDIR=$(NEMSDIR)/src/conf

# Path to NEMS.x is not configurable yet:
NEMS_EXE=$(NEMSDIR)/exe/NEMS.x

# We'll make this temporary file which will contain the new components:
new_components_file=$(NEMSDIR)/src/conf/components.mk

# Two more aliases for special characters.  Do not change.  These are
# last in this file because they can confuse syntax highlighters:
override singlequote='
override doublequote="
