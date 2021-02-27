!ifort  -convert big_endian test_sst.f90  -lnetcdf -lnetcdff
!pgf90 -I/home/metctm1/array/soft/netcdf-474c453f-pgi20/include -byteswapio test_sst.f90 -L/home/metctm1/array/soft/netcdf-474c453f-pgi20/lib -lnetcdf -lnetcdff
program nc2wps
    implicit none
    !include '/home/metctm1/array/soft/netcdf-474c453f-pgi20//include/netcdf.inc'
    include '/home/metctm1/array/soft/netcdf-474c453f-intel20/include/netcdf.inc'

    character (len=2)  :: dtemp
    character (len=1)  :: dmth,czero

    integer :: ncid
    integer, parameter :: NDIMS = 2, NRECS = 3 
    integer, parameter :: NLVLS = 33, NLATS = 181, NLONS = 360 
    character (len = *), parameter :: LVL_NAME = 'plev'
    character (len = *), parameter :: LAT_NAME = 'lat'
    character (len = *), parameter :: LON_NAME = 'lon'
    character (len = *), parameter :: REC_NAME = 'time'
    integer :: lvl_dimid, lon_dimid, lat_dimid, rec_dimid

    integer :: start(NDIMS), count(NDIMS)

    real :: lats(NLATS), lons(NLONS), plvls(NLVLS)
    integer :: lon_varid, lat_varid, lvl_varid
    integer :: dimids(NDIMS),status

    integer, parameter :: maxvar = 1
    character (len =9), dimension(maxvar) :: fieldname  = ' '
    character (LEN =9), dimension(maxvar) :: flnm  = ' '

    character (LEN=25), dimension(maxvar) :: unitout = ' '
    character (LEN=46), dimension(maxvar) :: descout = ' '

    integer :: var_varid
    real, dimension(NLONS, NLATS, NLVLS) :: var


    ! We recommend that each variable carry a 'units' attribute.
    character (len = 25), parameter :: LAT_UNITS = 'degrees_north'
    character (len = 25), parameter :: LON_UNITS = 'degrees_east'

    ! Loop indices
    integer :: ilvl, lat, lon, rec, i,j,ij,imm,mm
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer, parameter :: IUNIT = 10
    integer, parameter :: IFV=5
    character(len=24) :: HDATE= '2020-12-19_12:00:00:0000'
    real, parameter :: XFCST=0
    character(len=9) :: FIELD
    character(len=25) :: UNITS
    character(len=46) :: DESC
    character(len=32) :: MAP_SOURCE ='CMIP6'
    real :: XLVL
    integer, parameter :: NX=NLONS
    integer, parameter :: NY=NLATS
    real :: DX
    real :: DY
    real, dimension(NX,NY) :: slab
    

    ! ----------------------------------------------------------  
    flnm(1)='GHT'       
    fieldname(1)='zg'
    unitout(1)='m'
    descout(1)='3-d geopotential height'

    !  write(czero,'(I1)' ) 0


    open(IUNIT, file='GHT:2020-12-19_12', form='unformatted')

    ! Read 1 record of NLVLS*NLATS*NLONS values, starting at the beginning 
    ! of the record (the (1, 1, 1, rec) element in the netCDF file).
    count = (/ NLONS, NLATS/)
    start = (/ 1, 1/)
    !  print *, dimfile(i)
    !  status=nf_open(DIR//dimfile(i)//'.nc', nf_nowrite, ncid) 
    status=nf_open('./output/zg_2020-12-19_12.nc', nf_nowrite, ncid) 
    !  status=nf_open('/home/metctm1/array/data/cmip6/cmip6-mpi-esm-hr/ts_6hrPlevPt_MPI-ESM1-2-HR_ssp585_r1i1p1f1_gn_204001010600-204501010000.nc', nf_nowrite, ncid) 
    if(status/=nf_noerr) call handle_err(status)

    ! Get the varids of the latitude and longitude coordinate variables.
    status=nf_inq_varid(ncid, LAT_NAME, lat_varid) 
    if(status/=nf_noerr) call handle_err(status)
    status=nf_inq_varid(ncid, LON_NAME, lon_varid) 
    if(status/=nf_noerr) call handle_err(status)
    status=nf_inq_varid(ncid, LVL_NAME, lvl_varid) 
    if(status/=nf_noerr) call handle_err(status)
    ! Read the latitude and longitude data.
    status=nf_get_var_real(ncid, lat_varid, lats) 
    if(status/=nf_noerr) call handle_err(status)
    status=nf_get_var_real(ncid, lon_varid, lons) 
    if(status/=nf_noerr) call handle_err(status)
    status=nf_get_var_real(ncid, lvl_varid, plvls) 
    if(status/=nf_noerr) call handle_err(status)
    !! ----------------------------------------------------- 
    status=nf_inq_varid(ncid, fieldname(1), var_varid)  
    if(status/=nf_noerr) call handle_err(status)
    status=nf_get_var_real(ncid, var_varid, var)
    if(status/=nf_noerr) call handle_err(status)

    field=flnm(1)
    units=unitout(1)
    desc =descout(1)


    do ilvl=1,NLVLS
        do lon=1,NX
            do lat=1,NY
                slab(lon,lat) = var(lon,lat, ilvl)
            end do
        end do
        call output(hdate, map_source,field,units,desc,plvls(ilvl),slab,nx,ny)
    end do
    ! Close the file. This frees up any internal netCDF resources
    ! associated with the file.
    status=nf_close(ncid)
    if(status/=nf_noerr) call handle_err(status)
    ! If we got this far, everything worked as expected. Yipee! 
    print *,'*** SUCCESS reading example file', '!'

end

subroutine handle_err(status)
    include '/home/metctm1/array/soft/netcdf-474c453f-intel20/include/netcdf.inc'
    !include '/home/metctm1/array/soft/netcdf-474c453f-pgi20/include/netcdf.inc'
    integer:: status    
    
    if(status /= nf_noerr) then 
        print *, nf_strerror(status)
        stop 'Stopped'
    end if

end

subroutine output(hdate, map_source,field,units,desc,xlvl,slab,nx,ny)
!-------------------------------------------------------------------
! You need to allocate SLAB (this is a 2D array) and place each 2D slab here before  !
! you can write it out to into the intermadiate file format                          !
!                                                                                    !
! Other information you need to know about your data:                                !
!    Time at which data is valid                                                     !
!    Forecast time of the data                                                       !
!    Source of data - you can make something up, it is never used                    !
!    Field name - NOTE THEY NEED TO MATCH THOSE EXPECTED BY METGRID                  !
!    Units of field                                                                  !
!    Description of data                                                             !
!    Level of data - Pa, 200100 Pa is used for surface, and 201300 Pa is used        !
!          for sea-level pressure                                                    !
!    X dimension                                                                     !
!    Y dimension                                                                     !
!    Data projection - only recognize                                                !
!         0:  Cylindrical Equidistant (Lat/lon) projection.                          !
!         1:  Mercator projection.                                                   !
!         3:  Lambert-conformal projection.                                          !
!         4:  Gaussian projection.                                                   !
!         5:  Polar-stereographic projection.                                        !
!    Start location of data - "CENTER", "SWCORNER". "SWCORNER" is typical            !
!    Start lat & long of data                                                        !
!    Lat/Lon increment                                                               !
!    Number of latitudes north of equator (for Gaussian grids)                       !
!    Grid-spacing in x/y                                                             !
!    Center long                                                                     !
!    truelat1/2                                                                      !
!    Has the winds been rotated                                                      !
!====================================================================================!
    implicit none

! Declarations:

    integer, parameter :: IUNIT = 10
    integer :: ierr
    integer, parameter :: IFV=5
    character(len=24) ::  HDATE
    real, parameter :: XFCST=0
    character(len=8), parameter :: STARTLOC='SWCORNER'
    character(len=9) :: FIELD
    character(len=25) :: UNITS
    character(len=46) :: DESC
    character(len=32) :: MAP_SOURCE
    real :: XLVL
    integer :: NX
    integer :: NY
    integer, parameter :: IPROJ=0
    real, parameter :: STARTLAT=-90.
    real, parameter :: STARTLON=0.
    real, parameter :: DELTALON=1.
    real, parameter :: DELTALAT=1.
    real :: DX
    real :: DY
    real :: XLONC
    real :: TRUELAT1
    real :: TRUELAT2
    real, parameter :: EARTH_RADIUS = 6371.229 
    logical :: IS_WIND_EARTH_REL = .FALSE.
    real, dimension(NX,NY) :: slab

    write (IUNIT, IOSTAT=IERR) IFV
    write (IUNIT) HDATE, XFCST, MAP_SOURCE, FIELD, UNITS, DESC, XLVL, NX, NY, IPROJ
    print*, HDATE//"  ", XLVL, FIELD       
    !WRITE (IUNIT) STARTLOC, STARTLAT, STARTLON, NY/2, DELTALON, EARTH_RADIUS ! Gaussian projection
    WRITE (IUNIT) STARTLOC, STARTLAT, STARTLON, DELTALAT, DELTALON, EARTH_RADIUS ! Cylindrical equidistant

    WRITE (IUNIT) IS_WIND_EARTH_REL
    write (*,*) slab(50,50)
    WRITE (IUNIT) slab

    ! Loop back to read/write the next field.
end subroutine output

