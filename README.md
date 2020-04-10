ADC-WW3-NWM-NEMS repository is a place holder for the models
used in the COASTAL ACT coupling project.

To use this repository follow below instructions:

One time step:
While in github repo GUI (i.e. https://github.com/moghimis/ADC-WW3-NWM-NEMS):
1)   pulldown the "Branch: master" menu button and type a nem branch name (i.e. nwm_dev)
     and then press the "Create branch <nwm_dev> from master" button.
2)   hit the "Fork" button on the upper right corner of the GUI to your own github.
     note: your github user name displays under the "Fork" button to hit and to
           execute the "Fork". Your should see the new branch and the code in your own 
           github repository with the same name as the forked reop.

While in directory, where you want to clone the newely forked repo:
3)  (i.e. cd /scratch2/COASTAL/coastal/save/NAMED_STORMS/NEMS_APP)
4)  git clone --recursive https://github.com/<your_github_repo_name>/ADC-WW3-NWM-NEMS <DIR_NAME_OF_YOUR_CHOICE>
5)  do your edition and when finished 
6)  git add .
7)  git commit -m "describe what you changed"
8)  git status -- at this time you are in oring/master branch of your github repo
9)  git checkout <branch_name> -- this is the same name as in 1)(i.e. <nwm_dev>)
10) git push origin <branch_name>

While in your github repo
11) make sure you are in <branch_name> branch
12) push the "New pull request" button - your should be redirected to "Comparing changes"
    page on the original repo (i.e. moghimis/ADC-WW3-NWM-NEMS)
13) at this time see the changes made between the two repositories:
    "base repository ..." versus "head repository ..."
note: if there is no conflicts the pull request, atomatically, gets merged.
 

To compile the source codes, after reading the HOWTO, do:
./build.sh

