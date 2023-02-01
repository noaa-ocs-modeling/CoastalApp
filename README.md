# CoastalApp

[![tests](https://github.com/noaa-ocs-modeling/CoastalApp/workflows/tests/badge.svg)](https://github.com/noaa-ocs-modeling/CoastalApp/actions?query=workflow%3Atests)
[![build](https://github.com/noaa-ocs-modeling/CoastalApp/workflows/build/badge.svg)](https://github.com/noaa-ocs-modeling/CoastalApp/actions?query=workflow%3Abuild)
[![license](https://img.shields.io/github/license/noaa-ocs-modeling/CoastalApp)](https://creativecommons.org/share-your-work/public-domain/cc0)


### Contacts:
  * [Panagiotis.Velissariou@noaa.gov](mailto:Panagiotis.Velissariou@noaa.gov)
  * [Saeed.Moghimi@noaa.gov](mailto:Saeed.Moghimi@noaa.gov)


***CoastalApp*** is a modeling framework for coastal applications and regional forecasts. It consists of coupled modeling components that link the atmospheric, ocean and terrestrial realms under one common framework. CoastalApp is a flexible and portable modeling system. Flexibility means that additional modeling components can be added with ease and portability means that CoastalApp can be built and run under different computing environments and operating systems.

***CoastalApp*** is an ESMF ([https://earthsystemmodeling.org/](https://earthsystemmodeling.org/)) for building a [NUOPC](https://earthsystemmodeling.org/nuopc/)/[NEMS](https://www.nws.noaa.gov/ost/CTB/mts-arch/CFSv3-Plan-Mt-082511_files/Lapenta.pdf) coupling application that includes two types of components (a) 1-way and 2-way coupled modeling components (model source + NUOPC Cap) and (b) data components (NUOPC Cap only) that pass forcing data, as needed, via NetCDF files to the various models in CoastalApp. The application is based on its predecessor ESMF application `ADC-WW3-NWM-NEMS` developed as part of the [**Coastal Act**](https://vlab.noaa.gov/web/osti-modeling/coastal-act1) coupling project to determine wind versus water percentage losses caused by a Named Storm Event.

The models and modeling components (data components) currently supported in *CoastalApp* are outlined in Table 1.


![](images/coastalapp_models.png)


## Downloading *CoastalApp*

*CoastalApp* is hosted in NOAA's Office of Coast Survey github modeling repository: [https://github.com/noaa-ocs-modeling](https://github.com/noaa-ocs-modeling) along with other applications and models. The source code of *CoastalApp* is publicly available from the GitHub repository:
  <a href="https://github.com/noaa-ocs-modeling/CoastalApp"
     TARGET="_BLANK" REL="NOREFERRER">https://github.com/noaa-ocs-modeling/CoastalApp</a>
(binary distributions of *CoastalApp* are not currently available).

*CoastalApp* can be downloaded using one of the following methods:

   * ***Clone the source code from GitHub using the command:***

     git clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git

    The source will be downloaded into the target directory CoastalApp.

  * ***Download the source archive using the command:***

        wget https://github.com/noaa-ocs-modeling/CoastalApp/archive/refs/heads/main.zip

    and extract the sources in the CoastalApp directory by issuing the following commands:

        unzip -o main.zip  (the data will be extracted into the CoastalApp-main directory)

        mv CoastalApp-main CoastalApp  (move the extracted files to the CoastalApp directory)

In the *CoastalApp* GitHub repository, the included models (e.g., ADCIRC, SCHISM, ...) are simply git submodules (pointers) that point to the respective repository of each model. Some models, for example ADCIRC and FVCOM, require that the user is registered with the respective model repository in order to be granted access. If the user doesn't have access to a model, he/she can exclude particular model components when cloning *CoastalApp* by issuing commands like:

  * Exclude ADCIRC from cloning:

     git -c submodule."ADCIRC".update=none clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git

  * Exclude multiple components (ADCIRC, PAHM and schism/schism-esmf) from cloning:

     git -c submodule."ADCIRC".update=none -c submodule."PAHM".update=none -c submodule."SCHISM/schism".update=none -c submodule."SCHISM/schism-esmf".update=none clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git


## Building *CoastalApp*

### Requirements

![ ](images/coastalapp-usage.png)




#### installing ParMETIS for WW3

Using unstructured WW3 requires an installation of ParMETIS for domain
decomposition.

1. [download the code here](http://glaros.dtc.umn.edu/gkhome/metis/parmetis/download)
2. build ParMETIS
    ```bash
    module purge
    module load intel impi
    setenv CFLAGS -fPIC
    make config cc=mpiicc cxx=mpiicc prefix=/path/to/your/parmetis/ | & tee config.out-rr
    make install | & tee make-install.out-rr
    ```
   This adds `libparmetis.a`
   under `/path/to/your/parmetis/lib/libparmetis.a`.
3. set the path to ParMETIS
    ```bash
    setenv METIS_PATH /path/to/your/parmetis
    ```
## Organization / Responsibility

#### `NEMS` application implementing ESMF / NUOPC coupling
- Saeed Moghimi (**lead**) - saeed.moghimi@noaa.gov
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov

Former Contributors

- Zachary Burnett - zachary.burnett@noaa.gov
- Andre Van der Westhuysen - andre.vanderwesthuysen@noaa.gov 
- Beheen Trimble - beheenmt@gmail.com

#### ESMF / NUOPC cap for `ADCIRC` model
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Guoming Ling - gling@nd.edu
- Damrongsak Wirasaet - dwirasae@nd.edu
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov
- Zachary Burnett - zachary.burnett@noaa.gov
#### ESMF / NUOPC cap for `FVCOM` model
- Jianhua Qi (**lead**) - jqi@umassd.edu
- Saeed Moghimi - saeed.moghimi@noaa.gov
#### ESMF / NUOPC cap for `SCHISM` model
- Carsten Lemmen (**lead**) - carsten.lemmen@hzg.de  
- Y. Joseph Zhang - yjzhang@vims.edu
#### ESMF / NUOPC cap for `WW3` model
- Andre Van der Westhuysen (**lead**) - andre.vanderwesthuysen@noaa.gov
- Ali Abdolali - ali.abdolali@noaa.gov
#### `PaHM` model and ESMF / NUOPC cap for `PaHM` model
- Panagiotis Velissariou (**lead**) - panagiotis.velissariou@noaa.gov
#### `ATMESH` data component and ESMF / NUOPC cap for `ATMESH` data component
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Guoming Ling - gling@nd.edu
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov
#### ESMF / NUOPC cap for `NWM` model
- Daniel Rosen (**lead**) - Daniel.Rosen@noaa.gov
- Beheen Trimble - beheenmt@gmail.com
- Jason Ducker - jason.ducker@noaa.gov
- other colleagues from NWS / OWP

## Compilation

This section contains some generic instructions of how to build the NEMS
application. The contents of this section will change soon.

```bash
./build.sh --help
```

The following example builds `NEMS.x` with ADCIRC, ATMESH, and WW3DATA,
using variables / modules from the Hera environment, compiling with the
Intel compiler, and cleaning before building.

```bash
./build.sh --component "ADCIRC ATMESH WW3DATA" --plat hera --compiler intel --clean -2 
```

### Components

- `--component` can be any combination of
    - `ADCIRC`
    - `ATMESH`
    - `WW3` / `WW3DATA`
    - `NWM`

```bash
./build.sh --component "ADCIRC WW3" --plat hera --compiler intel --clean -2 
```

```bash
./build.sh --component "SCHISM" --plat orion --compiler intel --clean -2
```

### Platforms

- `--plat` can be one of
    - `hera`
    - `stampede`
    - `wcoss`
    - `orion`
    - `jet`
    - `gaea`
    - `cheyenne`
    - `linux`
    - `macosx`
    - `macports`

For MacOS running MacPorts, use the `macports` option.

```bash
./build.sh --component "SCHISM" --plat hera --compiler intel --clean -2
```

```bash
./build.sh --component "SCHISM" --plat orion --compiler intel --clean -2
```

### Compiler

- `--compiler` can be one of
    - `intel`
    - `gnu`
    - `pgi`

```bash
./build.sh --component "SCHISM" --compiler gnu --plat macports
```

```bash
./build.sh --component "SCHISM" --compiler intel --plat hera
```

### Clean

- `--clean` is optional, and can be one of
    - ` ` (`make clean` and exit)
    - `1` (`make clean` and exit)
    - `2` (`make clobber` and exit)
    - `-1` (`make clean` and build)
    - `-2` (`make clobber` and build)

```bash
./build.sh --component "SCHISM" --compiler intel --plat hera --clean
```

```bash
./build.sh --component "SCHISM" --compiler intel --plat hera --clean -1
```

## Contributing

Feel free to fork this repository and create a pull request with
contributions.

#### adding a new platform / compiler to compilation script

Environment files are stored in `modulefiles/` with the
filename `envmodules_<COMPILER>.<PLATFORM>`

To compile in your own system you should create a similar file, then
run `build.sh` to compile.

## Collaboration

To collaborate and contribute to this repository follow below instructions:

1. go to https://github.com/noaa-ocs-modeling/CoastalApp
2. create a fork (click `Fork` on the upper right corner), and fork to your account.
3. clone your forked repository
   ```bash
   git clone --recursive https://github.com/<ACCOUNT>/CoastalApp
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
   https://github.com/noaa-ocs-modeling/CoastalApp/compare/<BRANCH>...<ACCOUNT>:<BRANCH>
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
