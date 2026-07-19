# Technology
tech_name = "sky130"

# Word size and number of words
word_size = 16
num_words = 16

# Number of banks (keep at 1 for this small test)
num_banks = 1
#ports
num_rw_ports = 1
num_r_ports = 1
num_w_ports = 0

# Output
output_path = "."
output_name = "sram_2x16"

# Enable full checks & characterization (important for your task!)
check_lvsdrc = True

# Number of simulation threads
num_sim_threads = 3

# Simulator
spice_name = "ngspice"
use_nix = False
process_corners = ["TT"]
num_spare_cols = 1
num_spare_rows = 1
