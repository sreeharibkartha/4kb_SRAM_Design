load cell6t
select top cell
extract all
extract do resistance
ext2spice lvs
ext2spice cthresh 0.01
ext2spice rthresh 1
ext2spice -o cell6t_pex.sp
quit -noprompt
