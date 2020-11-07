#! /bin/sh

if [[ ! -s /etc/prod ]] ; then
    echo "Not on WCOSS.  Cannot be on dev WCOSS if you are not on WCOSS.  I refuse to do anything.  Go run some other script." 1>&2
    exit 1
fi

hostchar=$( hostname | head -1 | cut -c1-1 )
prodchar=$( head -1 /etc/prod | cut -c1-1 )

if [[ "$hostchar" == "$prodchar" ]] ; then
    echo "On production machine.  Refusing to do anything.  Go to dev to run this.  You have been a bad $USER and you will get no dessert tonight." 1>&2
    exit 1
fi

#WCOSS_Cray need to load newer git version
if [[ `hostname | cut -c2-6` == "login" ]] ; then
    source /opt/modules/default/init/sh
    module use /usrx/local/dev/modulefiles
    module load git/2.18.0
fi

cd $( dirname "$0" )
cd ..
cat apps.def nightly/nightly.def | ./multi-app-test.sh "$@"
