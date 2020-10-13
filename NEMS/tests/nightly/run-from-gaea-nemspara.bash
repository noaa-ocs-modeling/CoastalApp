#!/bin/bash --login
cd `dirname $0`
cd ..
source ../src/conf/module-setup.sh.inc
cat apps.def nightly/nightly.def | ./multi-app-test.sh "$@"
