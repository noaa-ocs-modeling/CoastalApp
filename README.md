# ADC-WW3-NWM-NEMS

[![tests](https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS/workflows/tests/badge.svg)](https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS/actions?query=workflow%3Atests)
[![license](https://img.shields.io/github/license/noaa-ocs-modeling/ADC-WW3-NWM-NEMS)](https://creativecommons.org/share-your-work/public-domain/cc0)

ESMF application for building a NUOPC / NEMS application coupling ADCIRC, ATMESH, WW3 / WW3DATA, and NWM.

`ADC-WW3-NWM-NEMS` is an ESMF application developed as part of the Coastal Act coupling project to determine wind versus water percentage loss caused by a Named Storm Event. 

```bash
git clone --recursive https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS
cd ADC-WW3-NWM-NEMS
```

## Organization / Responsibility

#### `CoastalApp` - overall NEMS application
- Saeed Moghimi (**lead**) - saeed.moghimi@noaa.gov
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov
- Zachary Burnett - zachary.burnett@noaa.gov
- Beheen Trimble - beheenmt@gmail.com
#### NEMS cap for `ADCIRC` model
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Guoming Ling - gling@nd.edu
- Damrongsak Wirasaet - dwirasae@nd.edu
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov
- Zachary Burnett - zachary.burnett@noaa.gov
#### NEMS cap for `FVCOM` model
- Jianhua Qi (**lead**) - jqi@umassd.edu
- Saeed Moghimi - saeed.moghimi@noaa.gov
#### NEMS cap for `SCHISM` model
- Carsten Lemmen (**lead**) - carsten.lemmen@hzg.de  
- Y. Joseph Zhang - yjzhang@vims.edu
#### NEMS cap for `WW3`
- Andre Van der Westhuysen (**lead**) - andre.vanderwesthuysen@noaa.gov
- Ali Abdolali - ali.abdolali@noaa.gov
#### `PaHM` model and NEMS cap for `PaHM`
- Panagiotis Velissariou (**lead**) - panagiotis.velissariou@noaa.gov
#### `ATMESH` data component and NEMS cap for `ATMESH`
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Guoming Ling - gling@nd.edu
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov
#### NEMS cap for `NWM`
- Daniel Rosen (**lead**) - Daniel.Rosen@noaa.gov
- Beheen Trimble - beheenmt@gmail.com
- Jason Ducker - jason.ducker@noaa.gov
- other colleagues from NWS / OWP

## Compilation

```bash
./build.sh --component "ADCIRC ATMESH WW3DATA" --plat hera --compiler intel --clean -2 
```

- `--component` can be any combination of
    - `ADCIRC`
    - `ATMESH`
    - `WW3` / `WW3DATA`
    - `NWM`
- `--plat` can be any combination of
    - `hera`
    - `stampede`
    - `wcoss`
    - `orion`
    - `jet`
    - `gaea`
    - `cheyenne`
    - `linux`
    - `macosx`
- `--compiler` can be one of
    - `intel`
    - `gnu`
    - `pgi`
- `--clean` is optional, and can be one of
    - ` ` (`make clean` and exit)
    - `1` (`make clean` and exit)
    - `2` (`make clobber` and exit)
    - `-1` (`make clean` and build)
    - `-2` (`make clobber` and build)

#### adding a new platform / compiler to compilation script

Environment files are stored in `modulefiles/` with the filename `envmodules_<COMPILER>.<PLATFORM>`

To compile in your own system you should create a similar file, then run `build.sh` to compile.

## Requirements

#### installing ParMETIS for WW3

Using unstructured WW3 requires an installation of ParMETIS for domain decomposition.

1. [download the code here](http://glaros.dtc.umn.edu/gkhome/metis/parmetis/download)
2. build ParMETIS
    ```bash
    module purge
    module load intel impi
    setenv CFLAGS -fPIC
    make config cc=mpiicc cxx=mpiicc prefix=/path/to/your/parmetis/ | & tee config.out-rr
    make install | & tee make-install.out-rr
    ```
   This adds `libparmetis.a` under `/path/to/your/parmetis/lib/libparmetis.a`.
3. set the path to ParMETIS
    ```bash
    setenv METIS_PATH /path/to/your/parmetis
    ```

## Collaboration

To collaborate and contribute to this repository follow below instructions:

1. go to https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS
2. create a fork (click `Fork` on the upper right corner), and fork to your account.
3. clone your forked repository
   ```bash
   git clone --recursive https://github.com/<ACCOUNT>/ADC-WW3-NWM-NEMS
   ```
4. edit the files locally
   ```bash
   git status
   ```
5. commit changes
   ```bash
   git commit -a -m "describe what you changed"
   ```
6. push your changes to GitHub
   ```bash
   git push
   ```
7. enter your GitHub username/password if asked
8. create a pull request with descriptions of changes at
   ```
   https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS/compare/<BRANCH>...<ACCOUNT>:<BRANCH>
   ```

## Citations

```
Moghimi, S., Van der Westhuysen, A., Abdolali, A., Myers, E., Vinogradov, S., 
   Ma, Z., Liu, F., Mehra, A., & Kurkowski, N. (2020). Development of an ESMF 
   Based Flexible Coupling Application of ADCIRC and WAVEWATCH III for High 
   Fidelity Coastal Inundation Studies. Journal of Marine Science and 
   Engineering, 8(5), 308. https://doi.org/10.3390/jmse8050308

Moghimi, S., Vinogradov, S., Myers, E. P., Funakoshi, Y., Van der Westhuysen, 
   A. J., Abdolali, A., Ma, Z., & Liu, F. (2019). Development of a Flexible 
   Coupling Interface for ADCIRC model for Coastal Inundation Studies. NOAA 
   Technical Memorandum, NOS CS(41). 
   https://repository.library.noaa.gov/view/noaa/20609/

Moghimi, S., Westhuysen, A., Abdolali, A., Myers, E., Vinogradov, S., Ma, Z., 
   Liu, F., Mehra, A., & Kurkowski, N. (2020). Development of a Flexible 
   Coupling Framework for Coastal Inundation Studies. 
   https://arxiv.org/abs/2003.12652
```
