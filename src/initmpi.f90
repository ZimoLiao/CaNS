module mod_initmpi
  use mpi
  use decomp_2d
  use mod_common_mpi, only: comm_cart,ierr,halo,ipencil
  use mod_types
  implicit none
  private
  public initmpi
  contains
  subroutine initmpi(ng,dims,bc,lo,hi,n,n_x_fft,n_y_fft,lo_z,hi_z,n_z,nb,is_bound)
    implicit none
    integer, intent(in   ), dimension(3) :: ng
    integer, intent(inout), dimension(2) :: dims
    character(len=1), intent(in), dimension(0:1,3) :: bc
    integer, intent(out), dimension(3    ) :: lo,hi,n,n_x_fft,n_y_fft,lo_z,hi_z,n_z
    integer, intent(out), dimension(0:1,3) :: nb
    logical, intent(out), dimension(0:1,3) :: is_bound
    logical, dimension(3) :: periods
    integer :: l,ipencil_t(2)
    !
    periods(:) = .false.
    where(bc(0,:)//bc(1,:) == 'PP') periods(:) = .true.
    call decomp_2d_init(ng(1),ng(2),ng(3),dims(1),dims(2),periods)
    if(any(dims(:) == 0)) dims(:) = dims_auto(:)
    n_z(:) = zsize(:)
#if !defined(_DECOMP_Y) && !defined(_DECOMP_Z)
    ipencil=1
    comm_cart = DECOMP_2D_COMM_CART_X
    lo(:) = xstart(:)
    hi(:) = xend(:)
#elif defined(_DECOMP_Y)
    ipencil=2
    comm_cart = DECOMP_2D_COMM_CART_Y
    lo(:) = ystart(:)
    hi(:) = yend(:)
#elif defined(_DECOMP_Z)
    ipencil=3
    comm_cart = DECOMP_2D_COMM_CART_Z
    lo(:) = zstart(:)
    hi(:) = zend(:)
#endif
    n(:)       = hi(:)-lo(:)+1
    n_x_fft(:) = xsize(:)
    n_y_fft(:) = ysize(:)
    lo_z(:)    = zstart(:)
    hi_z(:)    = zend(:)
    n_z(:)     = zsize(:)
    nb(:,ipencil) = MPI_PROC_NULL
    ipencil_t(:) = pack([1,2,3],[1,2,3] /= ipencil)
    call MPI_CART_SHIFT(comm_cart,0,1,nb(0,ipencil_t(1)),nb(1,ipencil_t(1)),ierr)
    call MPI_CART_SHIFT(comm_cart,1,1,nb(0,ipencil_t(2)),nb(1,ipencil_t(2)),ierr)
    is_bound(:,:) = .false.
    where(nb(:,:) == MPI_PROC_NULL) is_bound(:,:) = .true.
    do l=1,3
      call makehalo(l,1,n(:),halo(l))
    end do
  end subroutine initmpi
  !
  subroutine makehalo(idir,nh,n,halo)
    implicit none
    integer, intent(in ) :: idir,nh
    integer, intent(in ), dimension(3) :: n
    integer, intent(out) :: halo
    integer, dimension(3) :: nn
    nn(:) = n(:) + 2*nh
    select case(idir)
    case(1)
      call MPI_TYPE_VECTOR(nn(2)*nn(3),nh            ,nn(1)            ,MPI_REAL_RP,halo,ierr)
    case(2)
      call MPI_TYPE_VECTOR(      nn(3),nh*nn(1)      ,nn(1)*nn(2)      ,MPI_REAL_RP,halo,ierr)
    case(3)
      call MPI_TYPE_VECTOR(          1,nh*nn(1)*nn(2),nn(1)*nn(2)*nn(3),MPI_REAL_RP,halo,ierr)
    end select
    call MPI_TYPE_COMMIT(halo,ierr)
  end subroutine makehalo
end module mod_initmpi
