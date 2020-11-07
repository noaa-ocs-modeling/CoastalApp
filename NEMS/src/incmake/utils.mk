define nems_missing_directory_text
$(warning Missing or empty $(2): $(1))
$(error Cannot find $(2))
endef

# $(call require_dir,/dir/path,what)
#     => empty string            if dir exists
#     => $(error ...$(what)...)  if dir does not exist
require_dir=$(if $(wildcard $(1)),,$(call nems_missing_directory_text,$(1),$(2)))

# $(call if_nonempty,str1,str2)
#     => str1   if str1 is the empty string
#     => str2   if str1 is not empty
if_nonempty=$(if $(call seq,$(1),$(empty)),$(1),$(2))

# $(call abspath2,path1,path2)
# Converts a path to an absolute path, if it isn't already.
# The empty string is treated as "no path should be set" and
# is preserved as the empty string.
#     => empty string   if path1 is the empty string
#     => path1          if path1 starts with a /
#     => path2          otherwise
abspath2=$(call if_nonempty,$(1),$(if $(call seq,$(call substr,$(1),1,1),/),$(1),$(2)))

# $(call split,char,text)
# Replaces all instances of char with a space in the text, resulting in
# a list of space-separated strings.
split=$(subst $(1),$(space),$(2))

# $(call locate_file_in,FILE,DIRS)
# Searches the DIRS in order for FILE.  The first instance of FILE
# found is returned.  If no FILE is found, the empty string is
# returned.
locate_file_in=$(word 1,$(foreach dir,$(2),$(if $(wildcard $(dir)/$(1)),$(dir)/$(1))))

# $(wildcard_in *wildcard*,DIRS)
# For each directory, the wildcard is applied, and all matches are
# returned.
wildcard_in=$(foreach dir,$(2),$(wildcard $(dir)/$(1)))

# $(call locate_incmake_file,FILE.mk)
# Finds the FILE.mk in either the directories listed in
# $(MAKE_INCLUDE_DIRS) If no such file exists, gives an explanitory
# $(error).
locate_incmake_file=$(or $(call locate_file_in,$(1),$(MAKE_INCLUDE_DIRS)),$(error $(1): no $(1) in $(MAKE_INCLUDE_DIRS)))

# $(call locate_component_file,FOO)
# Finds the component_FOO.mk file or gives an $(error) if no file exists.
locate_component_file=$(call incmake_file,component_$(1).mk)

# $(call startswith,string,prefix)
# Returns T if the string begins with the prefix, and the empty string otherwise
#    $(call startswith ABC,AB) => T
#    $(call startswith ABC,DEF) =>
#    $(call startswith ABC,ABCDEF) =>
startswith=$(if $(call seq,$(2),$(call substr,$(1),1,$(call strlen,$(2)))),T)

# $(call action_single_double,string,none,single,double,error_for_both)
# Checks for single quotes and double quotes in the string.  Action
# depends on whether each is present:
#  $(2) = none - neither single nor double quotes
#  $(3) = single - single quotes but no double
#  $(4) = double - double quotes but no single
#  $(warning $(5)) - both single and double quotes are present
action_single_double=$(if $(findstring $(singlequote),$(1)),$(if $(findstring $(doublequote),$(1)),$(warning $(5)),$(3)),$(if $(findstring $(doublequote),$(1)),$(4),$(2)))

# q_quote_var - helper function for quote_var.  Do not call directly.
q_quote_var=$(if $(call seq,$(empty),$(2)),,$(call $(3),$(1),$(2)))

# $(call quote_var,varname,function,warning)
# Does one of three things depending on the value of the specified variable:
#   $(call $(2),$(singlequote)) -- if there are double quotes in the value of $(1)
#   $(call $(2),$(doublequote)) -- if there are single quotes in the value of $(1)
#   $(warning $(3)) -- if there are both single- and double-quotes
quote_var=$(call q_quote_var,$(1),$(call action_single_double,$($(1)),$(doublequote),$(doublequote),$(singlequote),$(3)),$(2))

