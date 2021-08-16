# ESMF self-describing build dependency makefile fragment
#
# ESMF_DEP_FRONT     = adc_cap
# ESMF_DEP_INCPATH   = /mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC/cpl/nuopc /mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC_INSTALL 
# ESMF_DEP_CMPL_OBJS = 
# ESMF_DEP_LINK_OBJS =  -L/mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC_INSTALL -ladc /mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC_INSTALL/libadc_cap.a  -L/mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC/work/  /mnt/projects/hpc/fujisaki/NEMS/test1/ADC-WW3-NWM-NEMS/ADCIRC/work/libadc.a  
#
#
#



# ESMF self-describing build dependency makefile fragment
 #
 ESMF_DEP_FRONT     = cice_cap_mod
 ESMF_DEP_INCPATH   = /mnt/projects/hpc/fujisaki/NEMS/test_cice/ADC-WW3-NWM-NEMS/CICE/wak_nems/run/compile/
 #ESMF_DEP_INCPATH   = /mnt/projects/hpc/fujisaki/cice/CICE/wak_esmf/run/compile/
 ESMF_DEP_CMPL_OBJS = 
 ESMF_DEP_LINK_OBJS = /mnt/projects/hpc/fujisaki/NEMS/test_cice/ADC-WW3-NWM-NEMS/CICE/wak_nems/run/compile/libcice.a
 #

