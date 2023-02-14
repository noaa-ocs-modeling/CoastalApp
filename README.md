# CoastalApp

[![tests](https://github.com/noaa-ocs-modeling/CoastalApp/workflows/tests/badge.svg)](https://github.com/noaa-ocs-modeling/CoastalApp/actions?query=workflow%3Atests)
[![build](https://github.com/noaa-ocs-modeling/CoastalApp/workflows/build/badge.svg)](https://github.com/noaa-ocs-modeling/CoastalApp/actions?query=workflow%3Abuild)
[![license](https://img.shields.io/github/license/noaa-ocs-modeling/CoastalApp)](https://creativecommons.org/share-your-work/public-domain/cc0)


### Contacts:
  * [Panagiotis.Velissariou@noaa.gov](mailto:Panagiotis.Velissariou@noaa.gov)
  * [Saeed.Moghimi@noaa.gov](mailto:Saeed.Moghimi@noaa.gov)

## Introduction

***CoastalApp*** is a modeling framework for coastal applications and regional forecasts. It consists of coupled modeling components that link the atmospheric, ocean and terrestrial realms under one common framework. CoastalApp is a flexible and portable modeling system. Flexibility means that additional modeling components can be added with ease and portability means that CoastalApp can be built and run under different computing environments and operating systems.

***CoastalApp*** is based on the ESMF ([https://earthsystemmodeling.org/](https://earthsystemmodeling.org/))
framework for building a [NUOPC](https://earthsystemmodeling.org/nuopc/)/[NEMS](https://www.nws.noaa.gov/ost/CTB/mts-arch/CFSv3-Plan-Mt-082511_files/Lapenta.pdf) coupling application that includes two types of components (a) 1-way and 2-way coupled modeling components (model source + NUOPC Cap) and (b) data components (NUOPC Cap only) that pass forcing data, as needed, via NetCDF files to the various models in CoastalApp. The application is based on its predecessor ESMF application ``ADC-WW3-NWM-NEMS`` (see [Moghimi et. al](#moghimi_1)) developed as part of the [**Coastal Act**](https://vlab.noaa.gov/web/osti-modeling/coastal-act1) coupling project to determine wind versus water percentage losses caused by a Named Storm Event.

The models and modeling components (data components) currently supported in *CoastalApp* are outlined in Table 1.
<a name="table_1"></a>


![](images/coastalapp_models.png)

**Accessing the individual modeling components**

  * ATMESH : [https://github.com/noaa-ocs-modeling/ATMESH](https://github.com/noaa-ocs-modeling/ATMESH)
  * PAHM   : [https://github.com/noaa-ocs-modeling/PaHM](https://github.com/noaa-ocs-modeling/PaHM)
  * ADCIRC : [https://adcirc.org/](https://adcirc.org/),
             [https://github.com/adcirc/adcirc](https://github.com/adcirc/adcirc)
             (requires registration; please send an email request to
             [Crystal Fulcher](mailto:cfulcher@email.unc.edu))
  * SCHISM : [http://ccrm.vims.edu/schismweb/](http://ccrm.vims.edu/schismweb/),
             [https://github.com/schism-dev/schism](https://github.com/schism-dev/schism)
  * FVCOM  : [http://fvcom.smast.umassd.edu/](http://fvcom.smast.umassd.edu/),
             [https://github.com/FVCOM-GitHub](https://github.com/FVCOM-GitHub)
  * BARDATA: [https://github.com/noaa-ocs-modeling/BARDATA](https://github.com/noaa-ocs-modeling/BARDATA)
  * WW3    : [https://github.com/NOAA-EMC/WW3/wiki](https://github.com/NOAA-EMC/WW3/wiki), [https://github.com/NOAA-EMC/WW3](https://github.com/NOAA-EMC/WW3)
  * WW3DATA: [https://github.com/noaa-ocs-modeling/WW3DATA](https://github.com/noaa-ocs-modeling/WW3DATA)

## Downloading *CoastalApp*

*CoastalApp* is hosted in NOAA's Office of Coast Survey github modeling repository: [https://github.com/noaa-ocs-modeling](https://github.com/noaa-ocs-modeling) along with other applications and models. The source code of *CoastalApp* is publicly available from the GitHub repository:
  <a href="https://github.com/noaa-ocs-modeling/CoastalApp"
     TARGET="_BLANK" REL="NOREFERRER">https://github.com/noaa-ocs-modeling/CoastalApp</a>
(binary distributions of *CoastalApp* are not currently available).

The application can be downloaded using the following method:

***Clone the source code from GitHub:***

        git clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git

The source will be downloaded into the target directory CoastalApp. It is assumed
that all subsequent operations are taking place into the CoastalApp directory.

Most of the modeling components in the *CoastalApp* GitHub repository (e.g., ADCIRC, SCHISM, ...) are simply git submodules (pointers) that point to the respective repository of each model. Some models, for example ADCIRC and FVCOM, require that the user is registered with the respective model repository in order to be granted access.
In case, users don't have access to a model and in order to avoid errors and permission issues during the cloning
process of *CoastalApp*, they can exclude the particular modeling component using, for example, commands like:

  * Exclude ADCIRC from cloning using one of the following commands:
    * ``git -c submodule."ADCIRC".update=none clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git``

        OR

    * ``git clone --recurse-submodules=":(exclude)ADCIRC" https://github.com/noaa-ocs-modeling/CoastalApp.git``

  * Exclude multiple components (ADCIRC, PAHM and SCHISM) from cloning using one of the following commands:
    * ``git -c submodule."ADCIRC".update=none -c submodule."PAHM".update=none -c submodule."SCHISM/schism".update=none -c submodule."SCHISM/schism-esmf".update=none clone --recurse-submodules  https://github.com/noaa-ocs-modeling/CoastalApp.git``

        OR

    * ``git  clone --recurse-submodules=':(exclude)ADCIRC' --recurse-submodules=':(exclude)PAHM' --recurse-submodules=":(exclude)SCHISM/*" https://github.com/noaa-ocs-modeling/CoastalApp.git``

***Note:*** The alternative method of downloading the application by fetching the
zip archive via the command:

        wget https://github.com/noaa-ocs-modeling/CoastalApp/archive/refs/heads/main.zip

will download *CoastalApp* but all the model component directories will be empty
as these components are basically pointers to their respective repositories. Only
*CoastalApp's* configuration and build files will be available in this case. If
users are only interested on how *CoastalApp* is configured, they can download
the archive and extract the sources in the CoastalApp directory by issuing the following commands:

        unzip -o main.zip  (the data will be extracted into the CoastalApp-main directory)

        mv CoastalApp-main CoastalApp  (move the extracted files to the CoastalApp directory)

By using the distributed version control system Git, users will be able to follow
the *CoastalApp* development and its updates and furthermore they will be able
to easily merge to new versions of the application.
New Git users are invited to read some of the online guides to get familiar with vanilla Git concepts and commands:

- Basic and advanced guide with the
<a href="https://git-scm.com/book/en/v2/" TARGET="_BLANK" REL="NOREFERRER">Git Book</a>.
- Reference guides with the
<a href="https://git-scm.com/docs/" TARGET="_BLANK" REL="NOREFERRER">Git Reference</a>.
- GitHub reference sheets with the
<a href="https://training.github.com/" TARGET="_BLANK" REL="NOREFERRER">GitHub Reference</a>.
- Manage your GitHub repositories with Git
<a href="https://docs.github.com/en/get-started/using-git/" TARGET="_BLANK" REL="NOREFERRER">Using Git</a>.


## Building *CoastalApp*

The build infrastracture in CoastalApp uses a hybrid "Make" system based on [GNU Make](https://www.gnu.org/software/make/) and [CMake](https://cmake.org/) toolkits that manage building of the source code and the generation of executables and other non-source files of a program. Furthermore, *CostalApp* utilizes environment module systems
like [Lmod](https://lmod.readthedocs.io/en/latest/) (installed in most HPC clusters) or 
[Environment Modules](https://modules.readthedocs.io/en/latest/).

### Requirements

 1. Recent version of CMake (**version &ge; 3.2**).
 2. Recent Fortran/C/C++ compilers: The compilers tested are **Intel &ge; 18**, **GCC &ge; 4.8** and **PGI/NVidia &ge; 20.11**.
 3. Recent MPI implementation: The Message Passing Interface libraries tested are [Intel's MPI](https://www.intel.com/content/www/us/en/developer/tools/oneapi/mpi-library.html#gs.owl7s3), [OpenMPI](https://www.open-mpi.org/) and [MVAPICH](https://mvapich.cse.ohio-state.edu/).
 4. Recent version of the <a href="https://www.unidata.ucar.edu/software/netcdf/" TARGET="_BLANK" REL="NOREFERRER">NetCDF-4</a> libraries: the Network Common Data Form (NetCDF) C and Fortran libraries (usually installed in the host OS).
 5. Recent version of the <a href="https://www.hdfgroup.org/" TARGET="_BLANK" REL="NOREFERRER">HDF5</a> libraries: the High-performance software and Data Format (HDF) libraries (usually installed in the host OS).
 6. Recent version of the <a href="https://earthsystemmodeling.org/" TARGET="_BLANK" REL="NOREFERRER">ESMF</a> libraries: the Earth System Modeling Framework (**version &ge; 8.1**).
 7. <a href="https://github.com/KarypisLab/ParMETIS" TARGET="_BLANK" REL="NOREFERRER">ParMETIS</a> libraries (Optional). This library is required if building WaveWatch III (WW3 component, mandatory) or SCHISM (optional). The library is not shipped with *CoastalApp* and it is the user's responsibility to download the library before compiling *CoastalApp*. The script ``download_parmetis.sh`` in CostalApp/scripts directory is supplied for this reason.

**NOTE:** It is important to note that the user needs to make sure that all the libraries and *CoastalApp* are compiled using exactly the **same compilers** (and possibly versions; you cannot mix compilers and
compiler versions).


### Build System

To build *CoastalApp* the user should run the ***build.sh*** bash script (a link to the
scripts/build.sh) located in the root directory of the downloaded source code.
The build script accepts many options to allow the user to customize the compilation of *CoastalApp*. Running the script as:

        build.sh --help

will bring up a help screen as shown in Table 2 that explains the use of all available options to the script:
<a name="table_2"></a>


![ ](images/coastalapp-usage.png)


### Installing ParMETIS (Optional)

The unstructured WW3 and SCHISM models require the use of ParMETIS/METIS libraries for domain decomposition. While, the installation of this library is mandatory for WW3
(at this point), for SCHISM is optional as the model contains an internal version of ParMETIS (the model can use either the internal or the externally built library or do not use ParMETIS at all). To ease the compilation of the library, *CoastalApp* supplies the script ``scripts/download_parmetis.sh`` to first download the source code of the library and then build the library by supplying the option ``--tp parmetis`` to the build script.
The library source is downloaded into the CoastalApp/thirdparty_open directory.
Assuming that ParMETIS is already downloaded, to build ParMETIS and WW3 run the build
script as follows:

        build.sh -compiler intel -platform=hera --component ww3 --tp=parmetis

The above command will first compile ParMETIS and then will continue with the compilation of WW3 (notice that different formats can be used for the supplied options, all work the same way). ParMETIS libraries will be installed in the CoastalApp/THIRDPARTY_INSTALL direcory (this directory never gets deleted during a clean process).

In the case users want to use a pre-compiled version of ParMETIS (either in THIRDPARTY_INSTALL, or in a system-wide
installation), they can run the build script as:

        PARMETISHOME=FULL_PATH_TO/CostalApp/THIRDPARTY_INSTALL build.sh -compiler intel -platform=hera --component schism

and *CoastalApp* will use the installed ParMETIS in ``CostalApp/THIRDPARTY_INSTALL``. If there is a system wide
installed ParMETIS, users can set the PARMETISHOME variable to point to the system's installed ParMETIS.
In any case, *CoastalApp* tries to find the libraries in ``PARMETISHOME/lib`` and the header files in
``PARMETISHOME/include``.

### Compilation

This section contains some generic instructions of how to build *CoastalApp* (NEMS application).
The following steps will help in building *CoastalApp* on a local machine (desktop or otherwise) or on a HPC cluster.

 1. Make sure that CMake and the NetCDF/HDF5/ESMF libraries are in the user's PATH environment. In a Cluster/HPC system that uses the environment module system, the user should load all the required modules for CMake NetCDF, HDF5 and ESMF before building *CoastalApp* (this is done by setting the --platform option).
 2. Run the ``build.sh`` script as:

          build.sh --compiler COMPILER --platform PLATFORM --component "LIST OF COMPONENTS" --tp parmetis (if needed) 

The option ``--component`` is mandatory as it is indentionally left with no default value. It is up to the
user to supply the list of components to compile (at minimum one component is needed).
All other options are optional and most of them have default values assigned to them (see [Table 2](#table_2)).
If the user chooses a supported platform to compile *CoastalApp* for, the build script will load the appropriate modulefile found in the modulefiles/ directory. In case the application needs to be built for an unsupported
platform, ther user can copy one of the ``modulefiles/envmodules_<COMPILER>.custom`` files, rename it to ``modulefiles/envmodules_<COMPILER>.<USER'S_PLATFORM>`` and then modify the file according to the chosen
platform's configuration.

Upon successful compilation of *CoastalApp*, the binaries and libraries for each component are installed into
its respective ``<COMPONENT>_INSTALL`` directory (e.g., SCHISM_INSTALL).
In addition, all component executables, libraries and other files are also installed (copied) into the ``ALLBIN_INSTALL`` directory. This directory never gets deleted during a complete cleanup of the compiled files and
it is the user's responsibility to delete this directory (if needed).
The final ``NEMS`` executable that contains all model components requested by the user is installed into the ``ALLBIN_INSTALL`` directory as two identical files: ``NEMS-<COMPONENT_LIST>.x`` and ``NEMS.x``.
As a sanity check, the user might want to check that all files were installed properly in the ``ALLBIN_INSTALL`` directory (e.g., check the file sizes).

  * **Example 1** Compile ATMESH and ADCIRC using the Intel compiler for the "tacc" platform:

          build.sh --compiler intel --platform tacc --component "atmesh adcirc"

    In this case, the build script will first load the modulefiles/envmodules_intel.tacc file and
    then will present to the user a list of the configured parameters, waiting for a yes/no to
    continue. Upon successful compilation all component executables, libraries and the ``NEMS*.x``
    executables are installed in the ``ALLBIN_INSTALL`` directory.

  * **Example 2** Build ``NEMS.x`` for PAHM, ATMESH, ADCIRC, WW3 on "hera" using the Intel compiler:
    * First download ParMETIS (as described previously):

        Run: ``scripts/download_parmetis.sh``

    * Next build the application:

          build.sh --compiler intel --platform hera --component "pahm atmesh adcirc ww3" --tp parmetis

    In this case, the build script will first load the modulefiles/envmodules_intel.hera file and
    then will present to the user a list of the configured parameters, waiting for a yes/no to
    continue. Next it will compile and install the ParMETIS/METIS libraries into the
    ``THIRDPARTY_INSTALL`` directory setting all the appropriate ``METIS`` environment variables.
    Finally it will continue with the compilations of all requested components to produce the ``NEMS.x``
    executable.

  * **Example 3** Rebuild ``NEMS.x`` for PAHM, ATMESH, ADCIRC, WW3 on "hera" using the Intel compiler,
    the already installed ParMETIS and cleaning the previously compiled components (the ``ALLBIN_INSTALL``
    directory is not deleted)
    * First run:

        PARMETISHOME=FULL_PATH/THIRDPARTY_INSTALL build.sh --compiler intel --platform hera --component "pahm atmesh adcirc ww3" --clean 2

        This cleans all components (see [Table 2](#table_2)), and deletes all ``COMPONENT_INSTALL`` folders
        except the ``ALLBIN_INSTALL`` directory. This step is required to ensure the integrity of the
        subsequent build.

    * Next build the application:

          PARMETISHOME=FULL_PATH/THIRDPARTY_INSTALL build.sh --compiler intel --platform hera --component "pahm atmesh adcirc ww3"

  * **Example 4** Build ``NEMS.x`` for ATMESH and SCHISM, WW3 on "hera" using the Intel compiler,
    SCHISM's internal ParMETIS and accepting all parameter settings:

        build.sh --compiler intel --platform hera --component "atmesh schism" -y

    In this case, the build script will load the modulefiles/envmodules_intel.hera file and
    it will continue to the compilation without waiting for a yes/no answer.


## Organization / Responsibility

### ``NEMS`` application implementing ESMF / NUOPC coupling
- Saeed Moghimi (**lead**) - saeed.moghimi@noaa.gov
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov

Past Contributors:

- Zachary Burnett - zachary.burnett@noaa.gov
- Andre Van der Westhuysen - andre.vanderwesthuysen@noaa.gov 
- Beheen Trimble - beheenmt@gmail.com

### ESMF / NUOPC Cap for the ``ADCIRC`` model
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Damrongsak Wirasaet - dwirasae@nd.edu
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov

Past Contributors:

- Guoming Ling - gling@nd.edu
- Zachary Burnett - zachary.burnett@noaa.gov

### ESMF / NUOPC Cap for the ``FVCOM`` model
- Jianhua Qi (**lead**) - jqi@umassd.edu
- Saeed Moghimi - saeed.moghimi@noaa.gov

### ESMF / NUOPC Cap for the ``SCHISM`` model
- Carsten Lemmen (**lead**) - carsten.lemmen@hzg.de
- Y. Joseph Zhang - yjzhang@vims.edu

### ESMF / NUOPC Cap for the ``WW3`` model
- Ali Abdolali - ali.abdolali@noaa.gov

Past Contributors:

- Andre Van der Westhuysen - andre.vanderwesthuysen@noaa.gov

### ``PaHM`` model and ESMF / NUOPC Cap for the ``PaHM`` model
- Panagiotis Velissariou (**lead**) - panagiotis.velissariou@noaa.gov

### ``BARDATA`` data component and ESMF / NUOPC Cap for the ``BARDATA`` data component
- Panagiotis Velissariou (**lead**) - panagiotis.velissariou@noaa.gov

### ``ATMESH`` data component and ESMF / NUOPC Cap for the ``ATMESH`` data component
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov

Past Contributors:

- Guoming Ling - gling@nd.edu

### ``WW3DATA`` data component and ESMF / NUOPC Cap for the ``WW3DATA`` data component
- Saeed Moghimi (**lead**) saeed.moghimi@noaa.gov
- Panagiotis Velissariou - panagiotis.velissariou@noaa.gov

Past Contributors:

- Guoming Ling - gling@nd.edu

### ESMF / NUOPC Cap for the ``NWM`` model
- Daniel Rosen (**lead**) - Daniel.Rosen@noaa.gov
- Jason Ducker - jason.ducker@noaa.gov
- Other colleagues from NWS / OWP

Past Contributors:

- Beheen Trimble - beheenmt@gmail.com

## Contributing

Feel free to fork this repository and create a pull request with
contributions.

### Adding a new platform / compiler to compilation script

The environment files are stored in the ``CoastalApp/modulefiles/`` directory following the
filename naming scheme: ``envmodules_<COMPILER>.<PLATFORM>``

To compile *CoastalApp* in your own system you should create a similar file (if the system is not supported),
and then run ``build.sh`` as usual to compile the application.

## Collaboration

To collaborate and contribute to this repository follow below instructions:

1. Go to https://github.com/noaa-ocs-modeling/CoastalApp
2. Create a fork (click `Fork` on the upper right corner), and fork to your account.
3. Clone your forked repository: ``git clone --recursive https://github.com/<ACCOUNT>/CoastalApp``
4. Edit the files locally: ``git status``
5. Commit changes: ``git commit -a -m "describe what you changed"``
6. Push your changes to GitHub: ``git push``
7. Enter your GitHub username/password if asked
8. Create a pull request with descriptions of changes at: ``https://github.com/noaa-ocs-modeling/CoastalApp/compare/<BRANCH>...<ACCOUNT>:<BRANCH>``

## Citations

<a name="moghimi_1"></a>
[1] Moghimi, S., Van der Westhuysen, A., Abdolali, A., Myers, E., Vinogradov, S., 
   Ma, Z., Liu, F., Mehra, A., & Kurkowski, N. (2020). Development of an ESMF 
   Based Flexible Coupling Application of ADCIRC and WAVEWATCH III for High 
   Fidelity Coastal Inundation Studies. Journal of Marine Science and 
   Engineering, 8(5), 308. https://doi.org/10.3390/jmse8050308

<a name="moghimi_2"></a>
[2] Moghimi, S., Vinogradov, S., Myers, E. P., Funakoshi, Y., Van der Westhuysen, 
   A. J., Abdolali, A., Ma, Z., & Liu, F. (2019). Development of a Flexible 
   Coupling Interface for ADCIRC model for Coastal Inundation Studies. NOAA 
   Technical Memorandum, NOS CS(41). 
   https://repository.library.noaa.gov/view/noaa/20609/

<a name="moghimi_3"></a>
[3] Moghimi, S., Westhuysen, A., Abdolali, A., Myers, E., Vinogradov, S., Ma, Z., 
   Liu, F., Mehra, A., & Kurkowski, N. (2020). Development of a Flexible 
   Coupling Framework for Coastal Inundation Studies. 
   https://arxiv.org/abs/2003.12652

