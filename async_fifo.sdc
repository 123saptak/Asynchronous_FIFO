# ======================================================
# async_fifo_4x4.sdc
# Multi-clock constraints for STA
# ======================================================

# -------------------------
# Clock Definitions
# -------------------------
# Write clock (wr_clk) -> 100 MHz (10 ns period)
create_clock -name wr_clk -period 10.0 [get_ports wr_clk]

# Read clock (rd_clk) -> 83.3 MHz (12 ns period)
create_clock -name rd_clk -period 12.0 [get_ports rd_clk]

# -------------------------
# Clock Groups
# -------------------------
# Declare wr_clk and rd_clk as asynchronous domains
set_clock_groups -asynchronous \
   -group [get_clocks wr_clk] \
   -group [get_clocks rd_clk]

# -------------------------
# Input/Output Delays
# -------------------------
# For synchronous inputs/outputs, define margins
set_input_delay 2.0 -clock wr_clk [all_inputs]
set_output_delay 2.0 -clock wr_clk [all_outputs]

# Apply similar for rd_clk domain
# (adjust delays depending on your environment)

