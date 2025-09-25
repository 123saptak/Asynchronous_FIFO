 # Define write clock (100 MHz)
create_clock -name wr_clk -period 10 [get_ports wr_clk]

# Define read clock (71.4 MHz)
create_clock -name rd_clk -period 14 [get_ports rd_clk]

# Tell STA tool wr_clk and rd_clk are asynchronous
set_clock_groups -asynchronous -group {wr_clk} -group {rd_clk}

# Optional: define input/output delays (example values)
set_input_delay 2 -clock wr_clk [get_ports wr_en]
set_input_delay 2 -clock wr_clk [get_ports wr_data*]
set_output_delay 2 -clock rd_clk [get_ports rd_data*]
set_output_delay 2 -clock rd_clk [get_ports rd_en]