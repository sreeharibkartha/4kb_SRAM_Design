set gdsdir "$env(OPENRAM_TECH)/sky130/gds_lib"
set outdir "$env(OPENRAM_TECH)/sky130/maglef_lib"

foreach f [glob -directory $gdsdir *.gds] {
    set cellname [file rootname [file tail $f]]
    gds read $f
    load $cellname
    save $outdir/$cellname.mag
}
puts "Conversion complete."
quit -noprompt
