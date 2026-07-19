load cell6t
select top cell
drc check
set drc_count [drc list count total]
puts "TOTAL_DRC_ERRORS: $drc_count"
drc catchup
set outf [open "drc_errors.txt" w]
puts $outf "DRC error count: $drc_count"
close $outf
quit -noprompt
