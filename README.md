# ADC-WW3-NWM-NEMS

ESMF application for building a NUOPC / NEMS application coupling
circulation models (ADCIRC, SCHISM) with forcing models (WW3, NWM) or
even file forcings (ATMESH, WW3DATA).

`ADC-WW3-NWM-NEMS` is an ESMF application developed as part of the
Coastal Act coupling project to determine wind versus water percentage
loss caused by a Named Storm Event.

```bash
git clone --recursive https://github.com/noaa-ocs-modeling/ADC-WW3-NWM-NEMS
cd ADC-WW3-NWM-NEMS
```

## Requirements

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

## Publications

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
