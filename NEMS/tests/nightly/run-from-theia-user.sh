#! /bin/sh
cd $( dirname "$0" )
cd ..
cat apps.def nightly/nightly.def | ./multi-app-test.sh "$@"
