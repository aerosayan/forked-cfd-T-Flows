!==============================================================================!
  logical function Results_Mod_Time_To_Save(n)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  integer :: n  ! current time step
!==============================================================================!

  Results_Mod_Time_To_Save = mod(n, result % interval) .eq. 0

  end function
