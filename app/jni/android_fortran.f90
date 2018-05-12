module android_fortran

use iso_c_binding

! add enumerators

! set up interfaces to all of the c functions
  interface

    subroutine fortran_process_events(my_app) bind(c,name="fortran_process_events")
       use iso_c_binding
       type(c_ptr), value :: my_app
    end subroutine fortran_process_events

  end interface

end module android_fortran

