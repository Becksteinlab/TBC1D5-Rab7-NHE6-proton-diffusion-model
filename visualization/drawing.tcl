# created with ChatGTP 5.1's help

proc delete_all {{mol top}} {
    foreach {id} [graphics $mol list] {graphics $mol delete $id}
}

proc draw_rect {mol p1 p2 p3 p4 {color white} {material Transparent}} {
    graphics $mol color $color
    graphics $mol material $material
    graphics $mol triangle $p1 $p2 $p3
    graphics $mol triangle $p1 $p3 $p4
}

proc draw_rectxy {mol c0 Lx Ly {dz 0} {color white} {material Transparent}} {
    # unpack center point
    foreach {cx cy cz} $c0 {}

    # apply z-shift
    set cz [expr {$cz + $dz}]

    # half-lengths
    set hx [expr {$Lx/2.0}]
    set hy [expr {$Ly/2.0}]

    # define four corners in CCW order (normal +z)
    set p1 [list [expr {$cx - $hx}] [expr {$cy - $hy}] $cz]
    set p2 [list [expr {$cx + $hx}] [expr {$cy - $hy}] $cz]
    set p3 [list [expr {$cx + $hx}] [expr {$cy + $hy}] $cz]
    set p4 [list [expr {$cx - $hx}] [expr {$cy + $hy}] $cz]

    # call the provided primitive rectangle drawer
    draw_rect $mol $p1 $p2 $p3 $p4 $color $material
}

proc max_square_length_xy {minmax} {
    set minvec [lindex $minmax 0]
    set maxvec [lindex $minmax 1]
    set dx [expr {abs([lindex $maxvec 0] - [lindex $minvec 0])}]
    set dy [expr {abs([lindex $maxvec 1] - [lindex $minvec 1])}]
    return [expr {$dx > $dy ? $dx : $dy}]
}

proc draw_membrane {mol {selection {"top" "chain A B"}} {thickness 40} {color tan} {material Transparent} {padding 20}} {
    foreach {molsel selectionstring} $selection {}
    # puts "mol=$mol selection=$selection --> 'atomselect $molsel $selectionstring'"
    set sel [atomselect $molsel $selectionstring]
    set minmax [measure minmax $sel]
    set Lmax [expr [max_square_length_xy $minmax] + $padding]
    set center [measure center $sel]
    set dz [expr $thickness/2]

    #puts "Lmax=$Lmax dz=$dz center=$center"
    
    # upper surface and lower surface
    draw_rectxy $mol $center $Lmax $Lmax  $dz $color $material
    draw_rectxy $mol $center $Lmax $Lmax -$dz $color $material

    # info
    set cz [lindex $center 2]
    set z_upper [expr {$cz + $dz}]
    set z_lower [expr {$cz - $dz}]
    puts "membrane: center c0 = $center Å"
    puts "membrane: upper  zu = ${z_upper} Å"
    puts "membrane: lower  zl = ${z_lower} Å"
    puts "membrane: extent Lxy = $Lmax Å"

}

proc draw_hemisphere {mol c0 r {nlat 12} {nlon 36} {color tan} {material Transparent} {upper 1} {cap 0}} {
    # mol      - "top" or molecule id
    # c0       - center {cx cy cz}
    # r        - radius
    # nlat     - number of latitude bands (pole->equator)
    # nlon     - number of longitude slices
    # color    - color name/id
    # material - material name
    # upper    - 1 => +z hemisphere (flat face at z = cz), 0 => -z hemisphere
    # cap      - 0 no cap, 1 draw equator cap (filled disk)

    foreach {cx cy cz} $c0 break
    set pi [expr {acos(-1.0)}]

    # theta runs 0 -> pi/2 (pole -> equator)
    set theta_min 0.0
    set theta_max [expr {$pi/2.0}]

    graphics $mol color $color
    graphics $mol material $material

    # upper or lower hemisphere
    set sign_z [expr {$upper > 0 ? 1 : -1}]
    
    # build vertex table vt(i,j) stored with keys "$i,$j"
    array unset vt
    for {set i 0} {$i <= $nlat} {incr i} {
        set theta [expr {$theta_min + $i * ($theta_max - $theta_min) / double($nlat)}]
        set sinth [expr {sin($theta)}]
        set costh [expr {cos($theta)}]

        for {set j 0} {$j < $nlon} {incr j} {
            set phi [expr {$j * (2.0 * $pi / double($nlon))}]
	    
            set x [expr {$cx + $r * $sinth * cos($phi)}]
            set y [expr {$cy + $r * $sinth * sin($phi)}]
	    set z [expr {$cz + $sign_z * $r * $costh}]

            set vt($i,$j) [list $x $y $z]
        }
    }

    # create triangles for curved surface
    for {set i 0} {$i < $nlat} {incr i} {
        set ip1 [expr {$i + 1}]
        for {set j 0} {$j < $nlon} {incr j} {
            set jnext [expr {($j + 1) % $nlon}]

            set v00 $vt($i,$j)
            set v01 $vt($i,$jnext)
            set v10 $vt($ip1,$j)
            set v11 $vt($ip1,$jnext)

            # two triangles per quad
            graphics $mol triangle $v00 $v10 $v11
            graphics $mol triangle $v00 $v11 $v01
        }
    }

    # optionally draw a filled cap at the equator (z = cz)
    if {$cap} {
        # cap center is at the equator plane (same as sphere center's z)
        set cap_center [list $cx $cy $cz]

        # equator ring is stored at i = nlat
        # fan from cap_center to each adjacent pair on equator ring
        for {set j 0} {$j < $nlon} {incr j} {
            set jnext [expr {($j + 1) % $nlon}]
            set vj  $vt($nlat,$j)
            set vj1 $vt($nlat,$jnext)

            # triangle orientation: choose winding to make normals point outward
            # For the upper hemisphere (flat face at +z) the outward normal of the cap is +z,
            # so use (cap_center, vj1, vj) to get normal roughly +z. For lower, reverse winding.
            if {$upper} {
                graphics $mol triangle $cap_center $vj1 $vj
            } else {
                graphics $mol triangle $cap_center $vj $vj1
            }
        }
    }
}


proc point_along {x0 x1 L} {
    # x0, x1 are 3-element lists {x y z}
    # L is the distance from x0 toward x1

    # unpack vectors
    foreach {x0x x0y x0z} $x0 break
    foreach {x1x x1y x1z} $x1 break

    # direction vector n = x1 - x0
    set nx [expr {$x1x - $x0x}]
    set ny [expr {$x1y - $x0y}]
    set nz [expr {$x1z - $x0z}]

    # length of n
    set norm [expr {sqrt($nx*$nx + $ny*$ny + $nz*$nz)}]
    if {$norm == 0} {
        error "point_along: x0 and x1 are identical; direction undefined"
    }

    # scale factor
    set s [expr {$L / $norm}]

    # x2 = x0 + s*n
    set x2x [expr {$x0x + $s*$nx}]
    set x2y [expr {$x0y + $s*$ny}]
    set x2z [expr {$x0z + $s*$nz}]

    return [list $x2x $x2y $x2z]
}


proc draw_cylinder_along {mol x0 x1 L radius {resolution 16} {color pink} {material BlownGlass}} {
    set x2 [point_along $x0 $x1 $L]
    graphics $mol color $color
    graphics $mol material $material
    graphics $mol cylinder $x0 $x2 radius $radius resolution $resolution filled yes
}


proc distance {x0 x1} {
    foreach {x0x x0y x0z} $x0 break
    foreach {x1x x1y x1z} $x1 break

    set dx [expr {$x1x - $x0x}]
    set dy [expr {$x1y - $x0y}]
    set dz [expr {$x1z - $x0z}]

    return [expr {sqrt($dx*$dx + $dy*$dy + $dz*$dz)}]
}
