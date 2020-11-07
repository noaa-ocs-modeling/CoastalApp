#!/bin/tcsh
cd `dirname $0`
cd ..
cat apps.def nightly/nightly.def | ./multi-app-test.sh "$1" "$2" "$3"
