SHELL=/bin/sh
LOCAL_DOCS=$(wildcard *.md) $(wildcard *.dox)
CONTROL_FILES=Makefile prep_inputs.py Doxyfile.IN DoxygenLayout.xml.IN
PYFILES=$(shell cd .. ; find . -name '*.py' )

# Find Doxygen

ifndef DOXYGEN
DOXYGEN=doxygen
endif

ifeq ("$(DOXYGEN)","doxygen")
  $(info Attempting to auto-detect environment.)
  THEIA_DOXYGEN=/scratch3/NCEPDEV/hwrf/save/Samuel.Trahan/doxygen-1.8.10/bin/doxygen
  JET_DOXYGEN=/contrib/doxygen/1.8.10/bin/doxygen
  LUNA_DOXYGEN=/gpfs/hps3/emc/hwrf/noscrub/soft/doxygen-1.8.10/bin/doxygen
  TIDE_DOXYGEN=/hwrf/noscrub/soft/doxygen-1.8.10/bin/doxygen

  ifneq ($(wildcard $(THEIA_DOXYGEN)*),)
    $(info On Theia.)
    DOXYGEN=$(THEIA_DOXYGEN)
    TARGET ?= samuel.trahan@dmzgw.ncep.noaa.gov:/home/www/emc/htdocs/projects/pyprodutil-doc/.
  else ifneq ($(wildcard $(JET_DOXYGEN)*),)
    $(info On Jet.)
    DOXYGEN=$(JET_DOXYGEN)
    TARGET ?= samuel.trahan@dmzgw.ncep.noaa.gov:/home/www/emc/htdocs/projects/pyprodutil-doc/.
  else ifneq ($(wildcard $(LUNA_DOXYGEN)*),)
    $(info on Luna or Surge.)
    DOXYGEN=$(LUNA_DOXYGEN)
    TARGET ?= strahan@emcrzdm:/home/www/emc/htdocs/projects/pyprodutil-doc/.
  else ifneq ($(wildcard $(TIDE_DOXYGEN)*),)
    $(info on Tide or Gyre.)
    DOXYGEN=$(TIDE_DOXYGEN)
    TARGET ?= strahan@emcrzdm:/home/www/emc/htdocs/projects/pyprodutil-doc/.
  else
    $(error Could not detect environment.  You must set TARGET and DOXYGEN manually)
  endif
else
  $(info DOXYGEN set in environment.  Will not set TARGET variable.  You must set it manually.  DOXYGEN=$(DOXYGEN))
endif

TARGET ?= /please/update/TARGET/in/Makefile

default:
	@echo Specify build mode:
	@echo doc        = build documentation just for this directory
	@echo clean      = delete outputs
	@echo deliver    = copy to website
	@echo tar        = make tar.gz archive of website contents
	exit 19

clean:
	rm -rf html webpage.tar.gz repo_info.sh.inc Doxyfile DoxygenLayout.xml *.bak success-flag-file.txt *~ 

doc: clean
	./prep_inputs.py .. $(PYFILES)
	$(DOXYGEN) Doxyfile
	pwd

tar: webpage.tar.gz

webpage.tar.gz: html
	tar -vcpzf webpage.tar.gz html Doxyfile

deliver: html
	cd html && rsync -arv . "$(TARGET)/."

