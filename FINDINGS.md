# Week 5 — OpenRAM + SKY130 Debugging Log

## Setup issues found and fixed
1. Duplicate/broken environment variables in .bashrc
2. Wrong OpenRAM entry point assumed (openram.py vs sram_compiler.py)
3. PDK_ROOT pointed to placeholder path; corrected to volare install path
4. Nix auto-bootstrap failure — disabled via use_nix=False in config
5. fet_models/fet_libraries key mismatch in OpenRAM sky130 tech.py — bug in OpenRAM itself, worked around via explicit process_corners
6. Single-port bitcell (sram_sp_cell_opt1) not present in open SKY130 PDK — only dual-port cells are openly distributed. Switched target to dual-port (num_r_ports=1) SRAM.
7. Bitcell pin-order mismatch: OpenRAM's tech.py port_order did not match its own bundled sp_lib/sky130_fd_bd_sram__openram_dp_cell.sp (alphabetized vs positional) — fixed port_order in tech.py
8. maglef_lib missing entirely — required for Magic DRC blackbox cells. Generated via GDS->maglef batch conversion in Magic
9. OPENRAM_MAGICRC was unset, causing Magic to silently load "minimum" tech instead of sky130A
10. PDKPATH not set for magicrc

## Remaining issue (unresolved, root-caused)
GDS->maglef conversion (via default sky130A.tech cifinput style) silently drops certain
GDS layers ("Unknown layer/datatype in boundary" warnings) for many SRAM primitive cells.
Confirmed via LVS report: extracted sky130_fd_bd_sram__openram_dp_cell layout is missing
all 4 PMOS pass transistors and has a disconnected VDD node vs. the golden SPICE netlist.
Result: DRC fails with 39,097 errors, LVS fails with device/net mismatches on bitcell_array.

Next step: investigate sky130A-GDS.tech as an alternate cifinput style, or determine
whether OpenRAM should trust vendor-provided GDS/mag views directly rather than
re-extracting through a generic conversion script.
