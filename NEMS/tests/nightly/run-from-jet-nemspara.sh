#! /bin/bash
set -xue

cd $( dirname "$0" )
cd ..

ls
there=/lfs3/projects/hfv3gfs/emc.nemspara/scrub/$1/
mkdir -p "$there"

/usr/bin/env - HOME=$HOME USER=$USER PATH=/bin:/usr/bin \
/bin/bash --login -c "echo bash works"

/usr/bin/env - HOME=$HOME USER=$USER PATH=/bin:/usr/bin \
/bin/bash --login -c "
    set -xue                                    ;
    source /apps/lmod/lmod/init/bash            ;
    module use /apps/lmod/lmod/modulefiles/Core ;
    module use /apps/modules/modulefiles        ;
    module load rocoto hpss                     ;
    which rocotorun                             ;
    which hsi                                   ;
    pwd                                         ;
    ls -l                                       ;
    cat apps.def nightly/nightly.def |          
      ./multi-app-test.sh \"$1\" \"$2\" \"$3\""

