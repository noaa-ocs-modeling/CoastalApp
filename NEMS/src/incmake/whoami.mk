
WHOAMI  := $(shell whoami)
CMP_DATE := $(shell date)

SVN_URL := $(shell git remote show -n origin | grep 'Fetch URL:' | sed 's,^[^:]*: ,,g' )
SVN_REV := $(shell git show HEAD | head -1 | cut -f 2 -d ' ' | cut -c1-12 )

ifeq ($(SVN_URL),)
  SVN_REV := $(shell svnversion -n .)
  SVN_URL := $(shell svn info | grep URL | cut -f 2 -d ' ' | head -1 )
endif

CMP_YEAR := $(shell date +"%Y" )
CMP_JD := $(shell date +"%j" )

WHOFLAGS = -D'SVN_INFO="($(WHOAMI)) $(CMP_DATE) r$(SVN_REV) $(SVN_URL)"'

ifdef CMP_YEAR
  WHOFLAGS += -D'CMP_YEAR=$(CMP_YEAR)'
endif
ifdef CMP_JD
  WHOFLAGS += -D'CMP_JD=$(CMP_JD)'
endif
