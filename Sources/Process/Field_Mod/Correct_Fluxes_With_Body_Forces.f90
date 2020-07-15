!==============================================================================!
  subroutine Field_Mod_Correct_Fluxes_With_Body_Forces(flow, sol)
!------------------------------------------------------------------------------!
!   Calculates body forces (Only due to buoyancy for the time being)           !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Work_Mod, only: t_face_delta => r_face_01
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Field_Type),  target :: flow
  type(Solver_Type), target :: sol
!-----------------------------------[Locals]-----------------------------------!
  type(Grid_Type),   pointer :: grid
  type(Var_Type),    pointer :: t
  type(Matrix_Type), pointer :: a
  real, contiguous,  pointer :: b(:)
  real,              pointer :: u_relax
  integer                    :: c1, c2, s
  real                       :: xc1, yc1, zc1, xc2, yc2, zc2
  real                       :: gravity_source, dotprod, factor
!==============================================================================!

  ! Take aliases
  grid    => flow % pnt_grid
  t       => flow % t
  u_relax => flow % u_rel_corr
  call Solver_Mod_Alias_System (sol,  a, b)

  !-------------------------------!
  !   For Boussinesq hypothesis   !
  !-------------------------------!
  if(buoyancy) then
    do s = 1, grid % n_faces
      c1 = grid % faces_c(1,s)
      c2 = grid % faces_c(2,s)
      t_face_delta(s) = t % n(c1) * grid % f(s)          &
                      + t % n(c2) * (1.0 - grid % f(s))
      t_face_delta(s) = t_face_delta(s) - t_ref
    end do
  else
    t_face_delta(1:grid % n_faces) = 1.0
    flow % beta                    = 1.0  ! also default from control file
  end if

  ! Correct for Gravity
  if(sqrt(grav_x ** 2 + grav_y ** 2 + grav_z ** 2) >= TINY) then

    do s = 1, grid % n_faces
      c1 = grid % faces_c(1,s)
      c2 = grid % faces_c(2,s)

      if(c2 > 0) then
        xc1 = grid % xc(c1)
        yc1 = grid % yc(c1)
        zc1 = grid % zc(c1)
        xc2 = grid % xc(c1) + grid % dx(s)
        yc2 = grid % yc(c1) + grid % dy(s)
        zc2 = grid % zc(c1) + grid % dz(s)

        ! Interpolate gradients
        dotprod = 0.5 * (  flow % body_fx(c1) / grid % vol(c1)                 &
                         + flow % body_fx(c2) / grid % vol(c2)) * grid % dx(s) &
                + 0.5 * (  flow % body_fy(c1) / grid % vol(c1)                 &
                         + flow % body_fy(c2) / grid % vol(c2)) * grid % dy(s) &
                + 0.5 * (  flow % body_fz(c1) / grid % vol(c1)                 &
                         + flow % body_fz(c2) / grid % vol(c2)) * grid % dz(s)

        gravity_source =  &
          (  (grid % xf(s) - xc1) * grav_x * flow % beta * t_face_delta(s)   &
           + (grid % yf(s) - yc1) * grav_y * flow % beta * t_face_delta(s)   &
           + (grid % zf(s) - zc1) * grav_z * flow % beta * t_face_delta(s))  &
             * flow % density(c1)                                            &
         -(  (grid % xf(s) - xc2) * grav_x * flow % beta * t_face_delta(s)   &
           + (grid % yf(s) - yc2) * grav_y * flow % beta * t_face_delta(s)   &
           + (grid % zf(s) - zc2) * grav_z * flow % beta * t_face_delta(s))  &
             * flow % density(c2)

        factor = u_relax * 0.5 * (  grid % vol(c1) / a % sav(c1)     &
                                  + grid % vol(c2) / a % sav(c2) )

        gravity_source =  factor * a % fc(s) * (gravity_source - dotprod)

        flow % m_flux % n(s) = flow % m_flux % n(s) + gravity_source

        b(c1) = b(c1) - gravity_source
        b(c2) = b(c2) + gravity_source

      end if  ! c2 > 0

    end do

  end if

  end subroutine