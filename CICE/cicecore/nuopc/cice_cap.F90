!--------------- CICE6 NUOPC CAP -----------------
! This is the CICE model cap component that's NUOPC compiant.
! 
! The cap was adapted from https://github.com/feiliuesmf/lanl_cice_cap 
! for CICE6 and use in coupling with ADIRC and WW3
! 
! Currently it allows only one block per processor (i.e. nblocks=1), 
! which should be fixed later.
! 20210816 Ayumi Fujisaki-Manome, ayumif@umich.edu


module cice_cap_mod

  use ice_blocks, only: nx_block, ny_block, nblocks_tot, block, get_block, &
                        get_block_parameter
  use ice_domain_size, only: max_blocks, nx_global, ny_global
  use ice_domain, only: nblocks, blocks_ice, halo_info, distrb_info
  use ice_distribution, only: ice_distributiongetblockloc
  use icepack_parameters, only: Tffresh, rad_to_deg, c0, depressT
  use ice_calendar,  only: dt
  use ice_flux
  use ice_grid, only: TLAT, TLON, ULAT, ULON, hm, tarea, ANGLET, ANGLE, &
                      dxt, dyt, t2ugrid_vector
  use ice_constants, only: field_loc_center, field_loc_NEcorner, field_type_scalar, field_type_vector
  use ice_boundary, only: ice_HaloUpdate

  use ice_state
  use ice_communicate, only : my_task ! am 20210809
  use ice_arrays_column, only : Cdn_atm ! afm 20210806

  use CICE_RunMod
  use CICE_InitMod
  use CICE_FinalMod 

  use ESMF
  use NUOPC
  use NUOPC_Model, &
    model_routine_SS      => SetServices, &
    model_label_SetClock  => label_SetClock, &
    model_label_Advance   => label_Advance, &
    model_label_Finalize  => label_Finalize

  implicit none
  private
  public SetServices

  type cice_internalstate_type
  end type

  type cice_internalstate_wrapper
    type(cice_internalstate_type), pointer :: ptr
  end type

  integer   :: import_slice = 0
  integer   :: export_slice = 0

  type fld_list_type
    character(len=64) :: stdname
    character(len=64) :: shortname
    character(len=64) :: transferOffer
    logical           :: assoc    ! is the farrayPtr associated with internal data
    real(ESMF_KIND_R8), dimension(:,:), pointer :: farrayPtr
  end type fld_list_type

  integer,parameter :: fldsMax = 100
  integer :: fldsToIce_num = 0
  type (fld_list_type) :: fldsToIce(fldsMax)
  integer :: fldsFrIce_num = 0
  type (fld_list_type) :: fldsFrIce(fldsMax)

  integer :: lsize    ! local number of gridcells for coupling
  character(len=256) :: tmpstr
  character(len=2048):: info
  logical :: isPresent
  integer :: dbrc     ! temporary debug rc value

  type(ESMF_Grid), save :: ice_grid_i
  logical :: write_diagnostics = .false.
  logical :: overwrite_timeslice = .false.
  logical :: profile_memory = .false.
  logical :: grid_attach_area = .false.
  ! local helper flag for halo debugging
  logical :: HaloDebug = .false.


  contains
  !-----------------------------------------------------------------------
  !------------------- CICE code starts here -----------------------
  !-----------------------------------------------------------------------

  subroutine SetServices(gcomp, rc)

    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    character(len=*),parameter  :: subname='(cice_cap:SetServices)'

    rc = ESMF_SUCCESS
    
    ! the NUOPC model component will register the generic methods
    call NUOPC_CompDerive(gcomp, model_routine_SS, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    ! switching to IPD versions
    call ESMF_GridCompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
      userRoutine=InitializeP0, phase=0, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    ! set entry point for methods that require specific implementation
    call NUOPC_CompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
      phaseLabelList=(/"IPDv01p1"/), userRoutine=InitializeAdvertise, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call NUOPC_CompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
      phaseLabelList=(/"IPDv01p3"/), userRoutine=InitializeRealize, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    ! attach specializing method(s)
    ! No need to change clock settings
    call ESMF_MethodAdd(gcomp, label=model_label_SetClock, &
      userRoutine=SetClock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    
    call ESMF_MethodAdd(gcomp, label=model_label_Advance, &
      userRoutine=ModelAdvance_slow, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call NUOPC_CompSpecialize(gcomp, specLabel=model_label_Finalize, &
      specRoutine=cice_model_finalize, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call CICE_FieldsSetup()

  end subroutine SetServices

  !-----------------------------------------------------------------------------

  subroutine InitializeP0(gcomp, importState, exportState, clock, rc)
    type(ESMF_GridComp)   :: gcomp
    type(ESMF_State)      :: importState, exportState
    type(ESMF_Clock)      :: clock
    integer, intent(out)  :: rc
    
    character(len=10)     :: value
    type(ESMF_VM)         :: vm
    integer               :: lpet

    character(240)        :: msgString
    rc = ESMF_SUCCESS

    ! Switch to IPDv01 by filtering all other phaseMap entries
    call NUOPC_CompFilterPhaseMap(gcomp, ESMF_METHOD_INITIALIZE, &
      acceptStringList=(/"IPDv01p"/), rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_GridCompGet(gcomp, vm=vm, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_VMGet(vm, localPet=lpet, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
     write(msgString,'(a12,i8)')'CICE lpet = ',lpet
     call ESMF_LogWrite(trim(msgString), ESMF_LOGMSG_INFO)

    call ESMF_AttributeGet(gcomp, name="DumpFields", value=value, defaultValue="true", &
      convention="NUOPC", purpose="Instance", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    write_diagnostics=(trim(value)=="true")
    write(msgString,'(A,l6)')'CICE_CAP: Dumpfields = ',write_diagnostics
    call ESMF_LogWrite(trim(msgString), ESMF_LOGMSG_INFO, rc=rc)

    call ESMF_AttributeGet(gcomp, name="OverwriteSlice", value=value, defaultValue="true", &
      convention="NUOPC", purpose="Instance", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    overwrite_timeslice=(trim(value)/="false")
    write(msgString,'(A,l6)')'CICE_CAP: OverwriteSlice = ',overwrite_timeslice
    call ESMF_LogWrite(trim(msgString), ESMF_LOGMSG_INFO, rc=rc)

    call ESMF_AttributeGet(gcomp, name="ProfileMemory", value=value, defaultValue="true", &
      convention="NUOPC", purpose="Instance", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    profile_memory=(trim(value)/="false")
    write(msgString,'(A,l6)')'CICE_CAP: Profile_memory = ',profile_memory
    call ESMF_LogWrite(trim(msgString), ESMF_LOGMSG_INFO, rc=rc)

    call ESMF_AttributeGet(gcomp, name="GridAttachArea", value=value, defaultValue="false", &
      convention="NUOPC", purpose="Instance", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    grid_attach_area=(trim(value)=="true")
    write(msgString,'(A,l6)')'CICE_CAP: GridAttachArea = ',grid_attach_area
    call ESMF_LogWrite(trim(msgString), ESMF_LOGMSG_INFO, rc=rc)

  end subroutine InitializeP0
  
  !-----------------------------------------------------------------------------

  subroutine InitializeAdvertise(gcomp, importState, exportState, clock, rc)

    type(ESMF_GridComp)                    :: gcomp
    type(ESMF_State)                       :: importState, exportState
    type(ESMF_Clock)                       :: clock
    integer, intent(out)                   :: rc

    ! Local Variables
    type(ESMF_VM)                          :: vm
    integer                                :: mpi_comm
    character(len=*),parameter  :: subname='(cice_cap:InitializeAdvertise)'

    rc = ESMF_SUCCESS

    call ESMF_VMGetCurrent(vm, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_VMGet(vm, mpiCommunicator=mpi_comm, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call CICE_Initialize(mpi_comm)
    
    call CICE_AdvertiseFields(importState, fldsToIce_num, fldsToIce, rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call CICE_AdvertiseFields(exportState, fldsFrIce_num, fldsFrIce, rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    write(info,*) trim(subname),' --- initialization phase 1 completed --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)

  end subroutine InitializeAdvertise
  
  !-----------------------------------------------------------------------------

  subroutine InitializeRealize(gcomp, importState, exportState, clock, rc)
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: importState, exportState
    type(ESMF_Clock)     :: clock
    integer, intent(out) :: rc

    ! Local Variables
    type(ESMF_VM)                          :: vm
    type(ESMF_Grid)                        :: gridIn
    type(ESMF_Grid)                        :: gridOut
    type(ESMF_DistGrid)                    :: distgrid
    integer                                :: npet
    integer                                :: i,j,iblk, n, i1,j1, DE
    integer                                :: ilo,ihi,jlo,jhi
    integer                                :: ig,jg,cnt
    integer                                :: peID,locID
    integer, pointer                       :: indexList(:)
    integer, pointer                       :: deLabelList(:)
    integer, pointer                       :: deBlockList(:,:,:)
    integer, pointer                       :: petMap(:)
    integer, pointer                       :: i_glob(:),j_glob(:)
    integer                                :: lbnd(2),ubnd(2)
    type(block)                            :: this_block
    type(ESMF_DELayout)                    :: delayout
    real(ESMF_KIND_R8), pointer            :: tarray(:,:)     
    real(ESMF_KIND_R8), pointer :: coordXcenter(:,:)
    real(ESMF_KIND_R8), pointer :: coordYcenter(:,:)
    real(ESMF_KIND_R8), pointer :: coordXcorner(:,:)
    real(ESMF_KIND_R8), pointer :: coordYcorner(:,:)
    integer(ESMF_KIND_I4), pointer :: gridmask(:,:)
    real(ESMF_KIND_R8), pointer :: gridarea(:,:)
    character(len=*),parameter  :: subname='(cice_cap:InitializeRealize)'

    rc = ESMF_SUCCESS

    ! We can check if npet is 4 or some other value to make sure
    ! CICE is configured to run on the correct number of processors.

    ! create a Grid object for Fields
    ! we are going to create a single tile displaced pole grid from a gridspec
    ! file. We also use the exact decomposition in CICE so that the Fields
    ! created can wrap on the data pointers in internal part of CICE

    write(tmpstr,'(a,2i8)') trim(subname)//' ice nx,ny = ',nx_global,ny_global
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

! nblocks- actual number of blocks on this processor
! nblocks_tot - total number of blocks in decomposition

    allocate(deBlockList(2,2,nblocks_tot))
    allocate(petMap(nblocks_tot))
    allocate(deLabelList(nblocks_tot))



    write(tmpstr,'(a,2i8)') trim(subname)//'nblocls_tot, nblocks =' &
        ,nblocks_tot, nblocks
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
    do n = 1, nblocks_tot
       deLabelList(n) = n
       call get_block_parameter(n,ilo=ilo,ihi=ihi,jlo=jlo,jhi=jhi, &
          i_glob=i_glob,j_glob=j_glob)
       deBlockList(1,1,n) = i_glob(ilo)
       deBlockList(1,2,n) = i_glob(ihi)
       deBlockList(2,1,n) = j_glob(jlo)
       deBlockList(2,2,n) = j_glob(jhi)
       call ice_distributionGetBlockLoc(distrb_info,n,peID,locID)
! afm 20210124 
! add exception for peID = 0. peID = 0 is eliminited part from distribution
! see create_distrb_cart in ice_distribution.F90
! this caused -1 in petMap resulting in an seg fault at ESMG_DeLayoutCreate later
       !petMap(n) = peID 
       if (peID > 0 ) then
       petMap(n) = peID - 1 
       else
       petMap(n) = peID 
       endif       
 
       write(tmpstr,'(a,3i8)') trim(subname)//' IDs  = ',n,peID, my_task
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
       write(tmpstr,'(a,3i8)') trim(subname)//' iglo = ',n,deBlockList(1,1,n),deBlockList(1,2,n)
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
       write(tmpstr,'(a,3i8)') trim(subname)//' jglo = ',n,deBlockList(2,1,n),deBlockList(2,2,n)
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

       write(tmpstr,'(a,3i8)') trim(subname)//' petMap = ',n,petMap(n),nblocks
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

        
    enddo


    delayout = ESMF_DELayoutCreate(petMap, rc=rc)

    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return


    distgrid = ESMF_DistGridCreate(minIndex=(/1,1/), maxIndex=(/nx_global,ny_global/), &
        deBlockList=deBlockList, &
        delayout=delayout, &
        rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

    deallocate(deLabelList)
    deallocate(deBlockList)
    deallocate(petMap)

    call ESMF_DistGridGet(distgrid=distgrid, localDE=0, elementCount=cnt, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    allocate(indexList(cnt))
    write(tmpstr,'(a,i8)') trim(subname)//' distgrid cnt= ',cnt
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
    call ESMF_DistGridGet(distgrid=distgrid, localDE=0, seqIndexList=indexList, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    write(tmpstr,'(a,4i8)') trim(subname)//' distgrid list= ',indexList(1),indexList(cnt),minval(indexList), maxval(indexList)

    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
    deallocate(IndexList)

    gridIn = ESMF_GridCreate(distgrid=distgrid, &
       coordSys = ESMF_COORDSYS_SPH_DEG, &
       gridEdgeLWidth=(/0,0/), gridEdgeUWidth=(/0,1/), &
       rc = rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

    call ESMF_GridAddCoord(gridIn, staggerLoc=ESMF_STAGGERLOC_CENTER, rc=rc) 
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    call ESMF_GridAddCoord(gridIn, staggerLoc=ESMF_STAGGERLOC_CORNER, rc=rc) 
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    call ESMF_GridAddItem(gridIn, itemFlag=ESMF_GRIDITEM_MASK, itemTypeKind=ESMF_TYPEKIND_I4, &
       staggerLoc=ESMF_STAGGERLOC_CENTER, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

    ! Attach area to the Grid optionally. By default the cell areas are computed.
    if(grid_attach_area) then
      call ESMF_GridAddItem(gridIn, itemFlag=ESMF_GRIDITEM_AREA, itemTypeKind=ESMF_TYPEKIND_R8, &
         staggerLoc=ESMF_STAGGERLOC_CENTER, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, &
        file=__FILE__)) &
        return  ! bail out
    endif

    do iblk = 1,nblocks
       DE = iblk-1
       this_block = get_block(blocks_ice(iblk),iblk)
       ilo = this_block%ilo
       ihi = this_block%ihi
       jlo = this_block%jlo
       jhi = this_block%jhi

       call ESMF_GridGetCoord(gridIn, coordDim=1, localDE=DE, &
           staggerloc=ESMF_STAGGERLOC_CENTER, &
           computationalLBound=lbnd, computationalUBound=ubnd, &
           farrayPtr=coordXcenter, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
       call ESMF_GridGetCoord(gridIn, coordDim=2, localDE=DE, &
           staggerloc=ESMF_STAGGERLOC_CENTER, &
           farrayPtr=coordYcenter, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

       write(tmpstr,'(a,5i8)') trim(subname)//' iblk center bnds ',iblk,lbnd,ubnd
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
       if (lbnd(1) /= 1 .or. lbnd(2) /= 1 .or. ubnd(1) /= ihi-ilo+1 .or. ubnd(2) /= jhi-jlo+1) then
          write(tmpstr,'(a,5i8)') trim(subname)//' iblk bnds ERROR '
          call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, line=__LINE__, file=__FILE__, rc=dbrc)
          rc = ESMF_FAILURE
          return
       endif

       call ESMF_GridGetItem(gridIn, itemflag=ESMF_GRIDITEM_MASK, localDE=DE, &
           staggerloc=ESMF_STAGGERLOC_CENTER, &
           farrayPtr=gridmask, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

      if(grid_attach_area) then
       call ESMF_GridGetItem(gridIn, itemflag=ESMF_GRIDITEM_AREA, localDE=DE, &
            staggerloc=ESMF_STAGGERLOC_CENTER, &
            farrayPtr=gridarea, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
       do j1 = lbnd(2),ubnd(2)
       do i1 = lbnd(1),ubnd(1)
          i = i1 + ilo - lbnd(1)
          j = j1 + jlo - lbnd(2)
          gridarea(i1,j1) = tarea(i,j,iblk)
       enddo
       enddo
       write(tmpstr,'(a,5i8)') trim(subname)//' setting ESMF_GRIDITEM_AREA using tarea '
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, line=__LINE__, file=__FILE__, rc=dbrc)
      endif

       do j1 = lbnd(2),ubnd(2)
       do i1 = lbnd(1),ubnd(1)
          i = i1 + ilo - lbnd(1)
          j = j1 + jlo - lbnd(2)
          coordXcenter(i1,j1) = TLON(i,j,iblk) * rad_to_deg
          coordYcenter(i1,j1) = TLAT(i,j,iblk) * rad_to_deg
          gridmask(i1,j1) = nint(hm(i,j,iblk))
       enddo
       enddo

       call ESMF_GridGetCoord(gridIn, coordDim=1, localDE=DE, &
           staggerloc=ESMF_STAGGERLOC_CORNER, &
           computationalLBound=lbnd, computationalUBound=ubnd, &
           farrayPtr=coordXcorner, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
       call ESMF_GridGetCoord(gridIn, coordDim=2, localDE=DE, &
           staggerloc=ESMF_STAGGERLOC_CORNER, &
           farrayPtr=coordYcorner, rc=rc)
       if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

       write(tmpstr,'(a,5i8)') trim(subname)//' iblk corner bnds ',iblk,lbnd,ubnd
       call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

       ! ULON and ULAT are upper right hand corner from TLON and TLAT
       ! corners in ESMF need to be defined lon lower left corner from center
       ! ULON and ULAT have ghost cells, leverage that to fill corner arrays
       do j1 = lbnd(2),ubnd(2)
       do i1 = lbnd(1),ubnd(1)
          i = i1 + ilo - lbnd(1)
          j = j1 + jlo - lbnd(2)
          coordXcorner(i1,j1) = ULON(i-1,j-1,iblk) * rad_to_deg
          coordYcorner(i1,j1) = ULAT(i-1,j-1,iblk) * rad_to_deg
       enddo
       enddo

    enddo

    call ESMF_GridGetCoord(gridIn, coordDim=1, localDE=0,  &
       staggerLoc=ESMF_STAGGERLOC_CENTER, farrayPtr=tarray, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    write(tmpstr,'(a,2g15.7)') trim(subname)//' gridIn center1 = ',minval(tarray),maxval(tarray)
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

    call ESMF_GridGetCoord(gridIn, coordDim=2, localDE=0,  &
       staggerLoc=ESMF_STAGGERLOC_CENTER, farrayPtr=tarray, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    write(tmpstr,'(a,2g15.7)') trim(subname)//' gridIn center2 = ',minval(tarray),maxval(tarray)
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

    call ESMF_GridGetCoord(gridIn, coordDim=1, localDE=0,  &
       staggerLoc=ESMF_STAGGERLOC_CORNER, farrayPtr=tarray, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    write(tmpstr,'(a,2g15.7)') trim(subname)//' gridIn corner1 = ',minval(tarray),maxval(tarray)
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

    call ESMF_GridGetCoord(gridIn, coordDim=2, localDE=0,  &
       staggerLoc=ESMF_STAGGERLOC_CORNER, farrayPtr=tarray, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    write(tmpstr,'(a,2g15.7)') trim(subname)//' gridIn corner2 = ',minval(tarray),maxval(tarray)
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

    gridOut = gridIn ! for now out same as in
    ice_grid_i = gridIn

    call CICE_RealizeFields(importState, gridIn , fldsToIce_num, fldsToIce, "Ice import", rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call CICE_RealizeFields(exportState, gridOut, fldsFrIce_num, fldsFrIce, "Ice export", rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call state_reset(ExportState, value=-99._ESMF_KIND_R8, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out


    write(tmpstr,'(a,3i8)') trim(subname)//' nx_block, ny_block, nblocks = ',nx_block,ny_block,nblocks
    call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)

    write(info,*) trim(subname),' --- initialization phase 2 completed --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, line=__LINE__, file=__FILE__, rc=dbrc)

  end subroutine InitializeRealize
  
  !-----------------------------------------------------------------------------

  ! CICE model uses same clock as parent gridComp
  subroutine SetClock(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    
    ! local variables
    type(ESMF_Clock)              :: clock
    type(ESMF_TimeInterval)       :: stabilityTimeStep, timestep
    character(len=*),parameter  :: subname='(cice_cap:SetClock)'

    rc = ESMF_SUCCESS
    
    ! query the Component for its clock, importState and exportState
    call ESMF_GridCompGet(gcomp, clock=clock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    ! tcraig: dt is the cice thermodynamic timestep in seconds
    call ESMF_TimeIntervalSet(timestep, s=nint(dt), rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_ClockSet(clock, timestep=timestep, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
      
    ! initialize internal clock
    ! here: parent Clock and stability timeStep determine actual model timeStep
    call ESMF_TimeIntervalSet(stabilityTimeStep, s=nint(dt), rc=rc) 
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call NUOPC_CompSetClock(gcomp, clock, stabilityTimeStep, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    
  end subroutine SetClock

  !-----------------------------------------------------------------------------

  subroutine ModelAdvance_slow(gcomp, rc)
    type(ESMF_GridComp)                    :: gcomp
    integer, intent(out)                   :: rc
    
    ! local variables
    type(ESMF_Clock)                       :: clock
    type(ESMF_State)                       :: importState, exportState
    type(ESMF_Time)                        :: currTime
    type(ESMF_TimeInterval)                :: timeStep
    type(ESMF_Field)                       :: lfield,lfield2d
    type(ESMF_Grid)                        :: grid
    real(ESMF_KIND_R8), pointer            :: fldptr(:,:)
    real(ESMF_KIND_R8), pointer            :: fldptr2d(:,:)
    type(block)                            :: this_block
    character(len=64)                      :: fldname
    integer                                :: i,j,iblk,n,i1,i2,j1,j2
    integer                                :: ilo,ihi,jlo,jhi
    real(ESMF_KIND_R8)                     :: ue, vn, ui, vj
    real(ESMF_KIND_R8)                     :: sigma_r, sigma_l, sigma_c
    type(ESMF_StateItem_Flag)              :: itemType
    ! imports
    real(ESMF_KIND_R8), pointer :: dataPtr_ocncz(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_ocncm(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_pbot(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_zlvl(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_ubot(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_vbot(:,:)
    ! exports
    real(ESMF_KIND_R8), pointer :: dataPtr_ifrac(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_vice(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_iuvel(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_ivvel(:,:)
    real(ESMF_KIND_R8), pointer :: dataPtr_icdan(:,:)

    character(240)              :: import_timestr, export_timestr
    character(240)              :: fname
    character(240)              :: msgString
    character(len=*),parameter  :: subname='(cice_cap:ModelAdvance_slow)'

    rc = ESMF_SUCCESS
    if(profile_memory) call ESMF_VMLogMemInfo("Entering CICE Model_ADVANCE: ")
    write(info,*) trim(subname),' --- run phase 1 called --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)
    
    ! query the Component for its clock, importState and exportState
    call ESMF_GridCompGet(gcomp, clock=clock, importState=importState, &
      exportState=exportState, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    ! HERE THE MODEL ADVANCES: currTime -> currTime + timeStep
    
    ! Because of the way that the internal Clock was set in SetClock(),
    ! its timeStep is likely smaller than the parent timeStep. As a consequence
    ! the time interval covered by a single parent timeStep will result in 
    ! multiple calls to the ModelAdvance() routine. Every time the currTime
    ! will come in by one internal timeStep advanced. This goes until the
    ! stopTime of the internal Clock has been reached.
    
    call ESMF_ClockPrint(clock, options="currTime", &
      preString="------>Advancing CICE from: ", unit=msgString, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call ESMF_LogWrite(msgString, ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    
    call ESMF_ClockGet(clock, currTime=currTime, timeStep=timeStep, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    
    call ESMF_TimePrint(currTime + timeStep, &
      preString="--------------------------------> to: ", &
      unit=msgString, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out
    call ESMF_LogWrite(msgString, ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_TimeGet(currTime,          timestring=import_timestr, rc=rc)
    call ESMF_TimeGet(currTime+timestep, timestring=export_timestr, rc=rc)

  if(write_diagnostics) then
    call state_diagnose(importState, 'cice_import', rc)

    fname = 'field_ice_import_'//trim(import_timestr)//'.nc'
    do i = 1,fldsToice_num
      fldname = fldsToice(i)%shortname
      call ESMF_StateGet(importState, itemName=trim(fldname), itemType=itemType, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, &
        file=__FILE__)) &
        return  ! bail out
      if (itemType /= ESMF_STATEITEM_NOTFOUND) then
        call ESMF_StateGet(importState, itemName=trim(fldname), field=lfield, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        call ESMF_FieldGet(lfield,grid=grid,rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

        ! create a copy of the 3d data in lfield but in a 2d array, lfield2d
        lfield2d = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, indexflag=ESMF_INDEX_DELOCAL, &
          name=trim(fldname), rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out

        call ESMF_FieldGet(lfield  , farrayPtr=fldptr  , rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        call ESMF_FieldGet(lfield2d, farrayPtr=fldptr2d, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        fldptr2d(:,:) = fldptr(:,:)

        call ESMF_FieldWrite(lfield2d, fileName=trim(fname), &
          timeslice=1, overwrite=overwrite_timeslice, rc=rc) 
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out

        call ESMF_FieldDestroy(lfield2d, noGarbage=.true., rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out

      endif
    enddo
    endif  ! write_diagnostics 

    ! afm 20210807 add below. 
    ! when not coupled, the 'associated' fuction occasioanlly returns true.
    nullify(dataPtr_ubot, dataPtr_vbot, dataPtr_pbot)
    nullify(dataPtr_zlvl, dataPtr_ocncz, dataPtr_ocncm)

    call State_GetFldPtr(importState,'izwh10m',dataPtr_ubot,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(importState,'imwh10m',dataPtr_vbot,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(importState,'pmsl',dataPtr_pbot,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return

    call State_GetFldPtr(importState,'zeta',dataPtr_zlvl,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return 
    call State_GetFldPtr(importState,'velx',dataPtr_ocncz,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(importState,'vely',dataPtr_ocncm,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return


! afm 20210424 - should use fld_list_type%assoc? revisit later.
!    do i = 1, fldsToIce_num
!       if ( fldsToIce(i)%assoc ) .....
!    end do 
! ocean import
 

    if (associated( dataPtr_ocncz ) .or. &
        associated( dataPtr_ocncm ) )  then
        !associated(dataPtr_zlvl) )  then
!print*, 'shape ocncz', shape(dataPtr_ocncz ), shape(dataPtr_ocncm)


    do iblk = 1,nblocks
       this_block = get_block(blocks_ice(iblk),iblk)
       ilo = this_block%ilo
       ihi = this_block%ihi
       jlo = this_block%jlo
       jhi = this_block%jhi

       do j = jlo,jhi
       do i = ilo,ihi
          i1 = i - ilo + 1
          j1 = j - jlo + 1
!          i1 = this_block%i_glob(i)
!          j1 = this_block%j_glob(j)
!print*, 'index',i,j, i1,j1
          uocn   (i,j,iblk) = dataPtr_ocncz(i1,j1)
          vocn   (i,j,iblk) = dataPtr_ocncm(i1,j1)
!          to-do: need to calculate sea surface tilt force from zeta
!          ss_tltx(i,j,iblk) = dataPtr_sssz   (i1,j1,iblk)
!          ss_tlty(i,j,iblk) = dataPtr_sssm   (i1,j1,iblk)
       enddo
       enddo
    enddo
    end if


! atmos import 
    if (associated( dataPtr_ubot ) .or. &
        associated(dataPtr_vbot) )  then
!if ( associated(dataPtr_pbot ) then
    do iblk = 1,nblocks
       this_block = get_block(blocks_ice(iblk),iblk)
       ilo = this_block%ilo
       ihi = this_block%ihi
       jlo = this_block%jlo
       jhi = this_block%jhi
       do j = jlo,jhi
       do i = ilo,ihi
          i1 = i - ilo + 1
          j1 = j - jlo + 1
          uatm   (i,j,iblk) = dataPtr_ubot   (i1,j1)
          vatm   (i,j,iblk) = dataPtr_vbot   (i1,j1)
          !! ... = dataPtr_pbot(i1,j1) to-do:  pmsl, need to assign
       enddo
       enddo
    enddo
    end if
           


    do iblk = 1, nblocks
       do j = 1,ny_block
          do i = 1,nx_block
          ! ocean
          ue = uocn(i,j,iblk)
          vn = vocn(i,j,iblk)
          uocn(i,j,iblk) =  ue*cos(ANGLET(i,j,iblk)) + vn*sin(ANGLET(i,j,iblk))  ! x ocean current
          vocn(i,j,iblk) = -ue*sin(ANGLET(i,j,iblk)) + vn*cos(ANGLET(i,j,iblk))  ! y ocean current

! below needs to be activated when sea surface tilt force is included.
!          ue = ss_tltx(i,j,iblk)
!          vn = ss_tlty(i,j,iblk)
!          ss_tltx(i,j,iblk) =  ue*cos(ANGLET(i,j,iblk)) + vn*sin(ANGLET(i,j,iblk))  ! x ocean surface slope
!          ss_tlty(i,j,iblk) = -ue*sin(ANGLET(i,j,iblk)) + vn*cos(ANGLET(i,j,iblk))  ! y ocean surface slope
!
!          ! atm
          ue = uatm(i,j,iblk)
          vn = vatm(i,j,iblk)
          uatm(i,j,iblk) =  ue*cos(ANGLET(i,j,iblk)) + vn*sin(ANGLET(i,j,iblk))  ! x wind
          vatm(i,j,iblk) = -ue*sin(ANGLET(i,j,iblk)) + vn*cos(ANGLET(i,j,iblk))  ! y wind
          wind(i,j,iblk) = sqrt(uatm(i,j,iblk)**2 + vatm(i,j,iblk)**2)
         enddo !i
       enddo !j
    enddo !iblk

! Interpolate ocean dynamics variables from T-cell centers to
! U-cell centers.
! Atmosphere variables are needed in T cell centers in
! subroutine stability and are interpolated to the U grid
! later as necessary.
! note: t2ugrid call includes HaloUpdate at location center
! followed by call to move the vectors
! halos are returned as zeros

       call t2ugrid_vector(uocn)
       call t2ugrid_vector(vocn)
! afm 20210807 uncomment below when tilt forces are included.
!       call t2ugrid_vector(ss_tltx)
!       call t2ugrid_vector(ss_tlty)

    write(info,*) trim(subname),' --- run phase 2 called --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)
    if(profile_memory) call ESMF_VMLogMemInfo("Before CICE_Run")
    call CICE_Run
    if(profile_memory) call ESMF_VMLogMemInfo("Afterr CICE_Run")
    write(info,*) trim(subname),' --- run phase 3 called --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)

    !---- local modifications to coupling fields -----


    call State_GetFldPtr(ST=exportState,fldname='seaice',fldptr=dataPtr_ifrac,rc=rc)
    !call State_GetFldPtr(ST=exportState,fldname='sea_ice_concentration',fldptr=dataPtr_ifrac,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(exportState,'mean_ice_volume',dataPtr_vice,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(exportState,'sea_ice_u_velocity',dataPtr_iuvel,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(exportState,'sea_ice_v_velocity',dataPtr_ivvel,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return
    call State_GetFldPtr(exportState,'air-ice_neutral_drag_coefficient',dataPtr_icdan,rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) return


! need to figure out a way to unpack to multiple blocks from one processor
! below is a tentative way. only allows one block per processor (i.e. nblocks=1)

    ! pack and send exported fields
   if ( associated( dataPtr_ifrac ) ) dataPtr_ifrac = aice(:,:,1)   ! ice fraction (0-1)
   if ( associated( dataPtr_vice ) )  dataPtr_vice  = vice(:,:,1)   ! ice fraction (0-1)
   if ( associated( dataPtr_iuvel ) ) dataPtr_iuvel = uvel(:,:,1)   ! ice fraction (0-1)
   if ( associated( dataPtr_ivvel ) ) dataPtr_ivvel = vvel(:,:,1)   ! ice fraction (0-1)
   if ( associated( dataPtr_icdan ) ) dataPtr_icdan = Cdn_atm(:,:,1)   ! ice fraction (0-1)


!    if ( associated( dataPtr_ifrac ) .or. &
!         associated( dataPtr_vice ) .or.  &
!         associated( dataPtr_iuvel ) .or.  &
!         associated( dataPtr_ivvel ) .or.  &
!         associated( dataPtr_icdan ) ) then

!    do iblk = 1,nblocks
!       this_block = get_block(blocks_ice(iblk),iblk)
!       ilo = this_block%ilo
!       ihi = this_block%ihi
!      jlo = this_block%jlo
!       jhi = this_block%jhi
!       do j = jlo,jhi
!       do i = ilo,ihi
!          i1 = i - ilo + 1
!          j1 = j - jlo + 1
!          dataPtr_ifrac   (i1,j1) = aice(i,j,iblk)   ! ice fraction (0-1)
!          dataPtr_vice    (i1,j1) = vice(i,j,iblk)   ! ice volume per area (m)
!          dataPtr_iuvel   (i1,j1) = uvel(i,j,iblk)   ! ice u velocity
!          dataPtr_ivvel   (i1,j1) = vvel(i,j,iblk)   ! ice v velocity
!          dataPtr_icdan  (i1,j1) = Cdn_atm(i,j,iblk) ! air-ice neutral drag coeff.
!       enddo
!       enddo
!    enddo
!    endif
   
   
    !-------------------------------------------------

  if(write_diagnostics) then
    call state_diagnose(exportState, 'cice_export', rc)

    fname = 'field_ice_export_'//trim(export_timestr)//'.nc'
    do i = 1,fldsFrIce_num
      fldname = fldsFrIce(i)%shortname
      call ESMF_StateGet(exportState, itemName=trim(fldname), itemType=itemType, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, &
        file=__FILE__)) &
        return  ! bail out
      if (itemType /= ESMF_STATEITEM_NOTFOUND) then
        call ESMF_StateGet(exportState, itemName=trim(fldname), field=lfield, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        call ESMF_FieldGet(lfield,grid=grid,rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

        ! create a copy of the 3d data in lfield but in a 2d array, lfield2d
        lfield2d = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, indexflag=ESMF_INDEX_DELOCAL, &
          name=trim(fldname), rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out

        call ESMF_FieldGet(lfield  , farrayPtr=fldptr  , rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        call ESMF_FieldGet(lfield2d, farrayPtr=fldptr2d, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
        fldptr2d(:,:) = fldptr(:,:)

        call ESMF_FieldWrite(lfield2d, fileName=trim(fname), &
          timeslice=1, overwrite=overwrite_timeslice,rc=rc) 
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out

        call ESMF_FieldDestroy(lfield2d, noGarbage=.true., rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out
      endif
    enddo
  endif  ! write_diagnostics 
    write(info,*) trim(subname),' --- run phase 4 called --- ',rc
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)

! Dump out all the cice internal fields to cross-examine with those connected with mediator
! This will help to determine roughly which fields can be hooked into cice

   !import_slice = import_slice + 1
   !call dumpCICEInternal(ice_grid_i, import_slice, "air_density_height_lowest", "will provide", rhoa)
   !call dumpCICEInternal(ice_grid_i, import_slice, "inst_zonal_wind_height10m", "will provide", strax)
   !call dumpCICEInternal(ice_grid_i, import_slice, "inst_merid_wind_height10m", "will provide", stray)
   !call dumpCICEInternal(ice_grid_i, import_slice, "inst_pres_height_surface" , "will provide", zlvl)
   !call dumpCICEInternal(ice_grid_i, import_slice, "ocn_current_zonal", "will provide", uocn)
   !call dumpCICEInternal(ice_grid_i, import_slice, "ocn_current_merid", "will provide", vocn)
   !call dumpCICEInternal(ice_grid_i, import_slice, "sea_surface_slope_zonal", "will provide", ss_tltx)
   !call dumpCICEInternal(ice_grid_i, import_slice, "sea_surface_slope_merid", "will provide", ss_tlty)
   !call dumpCICEInternal(ice_grid_i, import_slice, "sea_surface_salinity", "will provide", sss)
   !call dumpCICEInternal(ice_grid_i, import_slice, "sea_surface_temperature", "will provide", sst)

!--------- export fields from Sea Ice -------------

   !export_slice = export_slice + 1
   !call dumpCICEInternal(ice_grid_i, export_slice, "ice_fraction"                    , "will provide", aice)
   !call dumpCICEInternal(ice_grid_i, export_slice, "stress_on_air_ice_zonal"         , "will provide", strairxT)
   !call dumpCICEInternal(ice_grid_i, export_slice, "stress_on_air_ice_merid"         , "will provide", strairyT)
   !call dumpCICEInternal(ice_grid_i, export_slice, "stress_on_ocn_ice_zonal"         , "will provide", strocnxT)
   !call dumpCICEInternal(ice_grid_i, export_slice, "stress_on_ocn_ice_merid"         , "will provide", strocnyT)
   !call dumpCICEInternal(ice_grid_i, export_slice, "mean_sw_pen_to_ocn"              , "will provide", fswthru)
   if(profile_memory) call ESMF_VMLogMemInfo("Leaving CICE Model_ADVANCE: ")

  end subroutine ModelAdvance_slow 


  !-----------------------------------------------------------------------------

  subroutine cice_model_finalize(gcomp, rc)

    ! input arguments
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    
    ! local variables
    type(ESMF_Clock)     :: clock
    type(ESMF_Time)                        :: currTime
    character(len=*),parameter  :: subname='(cice_cap:cice_model_finalize)'

    rc = ESMF_SUCCESS

    write(info,*) trim(subname),' --- finalize called --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)

    call NUOPC_ModelGet(gcomp, modelClock=clock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call ESMF_ClockGet(clock, currTime=currTime, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, &
      file=__FILE__)) &
      return  ! bail out

    call CICE_Finalize

    write(info,*) trim(subname),' --- finalize completed --- '
    call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)

  end subroutine cice_model_finalize

!-----------------------------------------------------------------------------
  subroutine CICE_AdvertiseFields(state, nfields, field_defs, rc)

    type(ESMF_State), intent(inout)             :: state
    integer,intent(in)                          :: nfields
    type(fld_list_type), intent(inout)          :: field_defs(:)
    integer, intent(inout)                      :: rc

    integer                                     :: i
    character(len=*),parameter  :: subname='(cice_cap:CICE_AdvertiseFields)'

    rc = ESMF_SUCCESS

    do i = 1, nfields

      call ESMF_LogWrite('Advertise: '//trim(field_defs(i)%stdname), ESMF_LOGMSG_INFO, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, &
        file=__FILE__)) &
        return  ! bail out

      call NUOPC_Advertise(state, &
        standardName=field_defs(i)%stdname, &
        name=field_defs(i)%shortname, &
        rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, &
        file=__FILE__)) &
        return  ! bail out

    enddo

  end subroutine CICE_AdvertiseFields

!-----------------------------------------------------------------------------
  subroutine CICE_RealizeFields(state, grid, nfields, field_defs, tag, rc)

    type(ESMF_State), intent(inout)             :: state
    type(ESMF_Grid), intent(in)                 :: grid
    integer, intent(in)                         :: nfields
    type(fld_list_type), intent(inout)          :: field_defs(:)
    character(len=*), intent(in)                :: tag
    integer, intent(inout)                      :: rc

    integer                                     :: i
    type(ESMF_Field)                            :: field
    integer                                     :: npet, nx, ny, pet, elb(2), eub(2), clb(2), cub(2), tlb(2), tub(2)
    type(ESMF_VM)                               :: vm
    character(len=*),parameter  :: subname='(cice_cap:CICE_RealizeFields)'
 
    rc = ESMF_SUCCESS

    do i = 1, nfields

      if (field_defs(i)%assoc) then

        write(info, *) trim(subname), tag, ' Field ', trim(field_defs(i)%shortname), ':', &
          lbound(field_defs(i)%farrayPtr,1), ubound(field_defs(i)%farrayPtr,1), &
          lbound(field_defs(i)%farrayPtr,2), ubound(field_defs(i)%farrayPtr,2)!, &
        call ESMF_LogWrite(trim(info), ESMF_LOGMSG_INFO, rc=dbrc)
        field = ESMF_FieldCreate(grid=grid, &
          farray=field_defs(i)%farrayPtr, indexflag=ESMF_INDEX_DELOCAL, &
          name=field_defs(i)%shortname, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out
      else
        field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, indexflag=ESMF_INDEX_DELOCAL, &
          name=field_defs(i)%shortname, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out
      endif

      if (NUOPC_IsConnected(state, fieldName=field_defs(i)%shortname)) then
        call NUOPC_Realize(state, field=field, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out
        call ESMF_LogWrite(trim(subname) // tag // " Field "// trim(field_defs(i)%stdname) // " is connected.", &
          ESMF_LOGMSG_INFO, &
          line=__LINE__, &
          file=__FILE__, &
          rc=dbrc)
      else
        call ESMF_LogWrite(trim(subname) // tag // " Field "// trim(field_defs(i)%stdname) // " is not connected.", &
          ESMF_LOGMSG_INFO, &
          line=__LINE__, &
          file=__FILE__, &
          rc=dbrc)
        ! TODO: Initialize the value in the pointer to 0 after proper restart is setup
        !if(associated(field_defs(i)%farrayPtr) ) field_defs(i)%farrayPtr = 0.0
        ! remove a not connected Field from State
        call ESMF_StateRemove(state, (/field_defs(i)%shortname/), rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, &
          file=__FILE__)) &
          return  ! bail out
      endif

    enddo

  end subroutine CICE_RealizeFields

!-----------------------------------------------------------------------------

  subroutine state_diagnose(State, string, rc)
    ! ----------------------------------------------
    ! Diagnose status of state
    ! ----------------------------------------------
    type(ESMF_State), intent(inout) :: State
    character(len=*), intent(in), optional :: string
    integer, intent(out), optional  :: rc

    ! local variables
    integer                     :: i,j,n
    integer                     :: fieldCount
    character(len=64) ,pointer  :: fieldNameList(:)
    character(len=64)           :: lstring
    real(ESMF_KIND_R8), pointer :: dataPtr(:,:)
    integer                     :: lrc
    character(len=*),parameter  :: subname='(cice_cap:state_diagnose)'

    lstring = ''
    if (present(string)) then
       lstring = trim(string)
    endif

    call ESMF_StateGet(State, itemCount=fieldCount, rc=lrc)
    if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    allocate(fieldNameList(fieldCount))
    call ESMF_StateGet(State, itemNameList=fieldNameList, rc=lrc)
    if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    do n = 1, fieldCount
      call State_GetFldPtr(State, fieldNameList(n), dataPtr, rc=lrc)
      if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
      write(tmpstr,'(A,3g14.7)') trim(subname)//' '//trim(lstring)//':'//trim(fieldNameList(n))//'  ', &
        minval(dataPtr),maxval(dataPtr),sum(dataPtr)
!      write(tmpstr,'(A)') trim(subname)//' '//trim(lstring)//':'//trim(fieldNameList(n))
      call ESMF_LogWrite(trim(tmpstr), ESMF_LOGMSG_INFO, rc=dbrc)
    enddo
    deallocate(fieldNameList)

    if (present(rc)) rc = lrc

  end subroutine state_diagnose

!-----------------------------------------------------------------------------

  subroutine state_reset(State, value, rc)
    ! ----------------------------------------------
    ! Set all fields to value in State
    ! If value is not provided, reset to 0.0
    ! ----------------------------------------------
    type(ESMF_State), intent(inout) :: State
    real(ESMF_KIND_R8), intent(in), optional :: value
    integer, intent(out), optional  :: rc

    ! local variables
    integer                     :: i,j,k,n
    integer                     :: fieldCount
    character(len=64) ,pointer  :: fieldNameList(:)
    real(ESMF_KIND_R8)          :: lvalue
    real(ESMF_KIND_R8), pointer :: dataPtr(:,:)
    character(len=*),parameter :: subname='(cice_cap:state_reset)'

    if (present(rc)) rc = ESMF_SUCCESS

    lvalue = 0._ESMF_KIND_R8
    if (present(value)) then
      lvalue = value
    endif

    call ESMF_StateGet(State, itemCount=fieldCount, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    allocate(fieldNameList(fieldCount))
    call ESMF_StateGet(State, itemNameList=fieldNameList, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    do n = 1, fieldCount
      call State_GetFldPtr(State, fieldNameList(n), dataPtr, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

      do j=lbound(dataPtr,2),ubound(dataPtr,2)
      do i=lbound(dataPtr,1),ubound(dataPtr,1)
         dataPtr(i,j) = lvalue
      enddo
      enddo

    enddo
    deallocate(fieldNameList)

  end subroutine state_reset

  !-----------------------------------------------------------------------------

  subroutine State_GetFldPtr(ST, fldname, fldptr, rc)
    type(ESMF_State), intent(in) :: ST
    character(len=*), intent(in) :: fldname
    real(ESMF_KIND_R8), pointer, intent(in) :: fldptr(:,:)
    integer, intent(out), optional :: rc

    ! local variables
    type(ESMF_Field) :: lfield
    integer :: lrc
    character(len=*),parameter :: subname='(cice_cap:State_GetFldPtr)'

    call ESMF_StateGet(ST, itemName=trim(fldname), field=lfield, rc=lrc)
    if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    call ESMF_FieldGet(lfield, farrayPtr=fldptr, rc=lrc)
    if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return

    if (present(rc)) rc = lrc

  end subroutine State_GetFldPtr

  !-----------------------------------------------------------------------------
  logical function FieldBundle_FldChk(FB, fldname, rc)
    type(ESMF_FieldBundle), intent(in) :: FB
    character(len=*)      ,intent(in) :: fldname
    integer, intent(out), optional :: rc

    ! local variables
    integer :: lrc
    character(len=*),parameter :: subname='(module_MEDIATOR:FieldBundle_FldChk)'

    if (present(rc)) rc = ESMF_SUCCESS

    FieldBundle_FldChk = .false.

    call ESMF_FieldBundleGet(FB, fieldName=trim(fldname), isPresent=isPresent, rc=lrc)
    if (present(rc)) rc = lrc
    if (ESMF_LogFoundError(rcToCheck=lrc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__)) return
    if (isPresent) then
       FieldBundle_FldChk = .true.
    endif

  end function FieldBundle_FldChk

  !-----------------------------------------------------------------------------


  subroutine CICE_FieldsSetup
    character(len=*),parameter  :: subname='(cice_cap:CICE_FieldsSetup)'

    integer :: rc

    rc = ESMF_SUCCESS

!--------- import fields to Sea Ice -------------

! tcraig, don't point directly into cice data YET (last field is optional in interface)
! instead, create space for the field when it's "realized".
! afm 20210130 to be compatible with ADCIRD export
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="sea_surface_height_above_sea_level",  shortname= "zeta" )
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="surface_eastward_sea_water_velocity", shortname= "velx" )
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="surface_northward_sea_water_velocity", shortname= "vely" )
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="air_pressure_at_sea_level",  shortname= "pmsl" )
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="inst_zonal_wind_height10m", shortname= "izwh10m" )
    call fld_list_add(num=fldsToIce_num, fldlist=fldsToIce, stdname="inst_merid_wind_height10m", shortname= "imwh10m" )



!--------- export fields from Sea Ice -------------

! afm 20201205
    call fld_list_add(fldsFrIce_num, fldsFrIce, stdname = "sea_ice_concentration", shortname = "seaice")
    call fld_list_add(fldsFrIce_num, fldsFrIce, stdname = "mean_ice_volume", shortname = "ivol")

    ! add iuvel
     if (.not.NUOPC_FieldDictionaryHasEntry( "sea_ice_u_velocity")) then
        call NUOPC_FieldDictionaryAddEntry( standardName="sea_ice_u_velocity", canonicalUnits="m s-1", rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__))  return  
      endif
   ! add ivvel
     if (.not.NUOPC_FieldDictionaryHasEntry( "sea_ice_v_velocity")) then
        call NUOPC_FieldDictionaryAddEntry( standardName="sea_ice_v_velocity", canonicalUnits="m s-1", rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__))  return 
      endif
   ! add icdan
     if (.not.NUOPC_FieldDictionaryHasEntry("air-ice_neutral_bulk_drag_coefficient")) then
        call NUOPC_FieldDictionaryAddEntry( standardName="air-ice_neutral_bulk_drag_coefficient",canonicalUnits="1", rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, line=__LINE__, file=__FILE__))  return 
      endif

    call fld_list_add(fldsFrIce_num, fldsFrIce, stdname = "sea_ice_u_velocity", shortname = "iuvel")
    call fld_list_add(fldsFrIce_num, fldsFrIce, stdname = "sea_ice_v_velocity", shortname = "ivvel")
    call fld_list_add(fldsFrIce_num, fldsFrIce, stdname = "air-ice_neutral_bulk_drag_coefficient", shortname = "icdan")


  end subroutine CICE_FieldsSetup

!  !-----------------------------------------------------------------------------
!
  subroutine fld_list_add(num, fldlist, stdname, data, shortname)
    ! ----------------------------------------------
    ! Set up a list of field information
    ! ----------------------------------------------
    integer,             intent(inout)  :: num
    type(fld_list_type), intent(inout)  :: fldlist(:)
    character(len=*),    intent(in)     :: stdname
    real(ESMF_KIND_R8), dimension(:,:), optional, target :: data
    character(len=*),    intent(in),optional :: shortname

    ! local variables
    integer :: rc
    character(len=*), parameter :: subname='(cice_cap:fld_list_add)'

    ! fill in the new entry

    num = num + 1
    if (num > fldsMax) then
      call ESMF_LogWrite(trim(subname)//": ERROR num gt fldsMax"//trim(stdname), &
        ESMF_LOGMSG_ERROR, line=__LINE__, file=__FILE__, rc=rc)
      return
    endif

    fldlist(num)%stdname        = trim(stdname)
    if (present(shortname)) then
       fldlist(num)%shortname   = trim(shortname)
    else
       fldlist(num)%shortname   = trim(stdname)
    endif

    if (present(data)) then
      fldlist(num)%assoc        = .true.
      fldlist(num)%farrayPtr    => data
    else
              fldlist(num)%assoc        = .false.
            endif

        !    if (present(unit)) then
        !       fldlist(num)%unit        = unit
        !    endif


            write(info,*) subname,' --- Passed--- '
            !print *,      subname,' --- Passed --- '
          end subroutine fld_list_add

          !-----------------------------------------------------------------------------

          subroutine dumpCICEInternal(grid, slice, stdname, nop, farray)

            type(ESMF_Grid)          :: grid
            integer, intent(in)      :: slice
            character(len=*)         :: stdname
            character(len=*)         :: nop
            real(ESMF_KIND_R8), dimension(:,:,:), target :: farray

            type(ESMF_Field)         :: field
            real(ESMF_KIND_R8), dimension(:,:), pointer  :: f2d
            integer                  :: i,j,rc

            if(.not. write_diagnostics) return ! remove this line to debug field connection

            field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
              indexflag=ESMF_INDEX_DELOCAL, &
              name=stdname, rc=rc)
            if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
              line=__LINE__, &
              file=__FILE__)) &
              return  ! bail out

            call ESMF_FieldGet(field, farrayPtr=f2d, rc=rc)
            if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
              line=__LINE__, &
              file=__FILE__)) &
              return  ! bail out

            do j = lbound(f2d,2),ubound(f2d,2)
             do i = lbound(f2d,1),ubound(f2d,1)
              f2d(i,j) = farray(i+1,j+1,1)
             enddo
            enddo

            call ESMF_FieldWrite(field, fileName='field_ice_internal_'//trim(stdname)//'.nc', &
              timeslice=slice, overwrite=overwrite_timeslice, rc=rc) 
            if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
              line=__LINE__, &
              file=__FILE__)) &
              return  ! bail out

            call ESMF_FieldDestroy(field, noGarbage=.true., rc=rc)
            if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
              line=__LINE__, &
              file=__FILE__)) &
              return  ! bail out
            
          end subroutine

          !-----------------------------------------------------------------------------
end module cice_cap_mod
