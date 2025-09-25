read_verilog async_fifo_4x4.v
hierarchy -check -top async_fifo_4x4
synth
dfflibmap -liberty NangateOpenCellLibrary_typical.lib
opt_clean
abc -liberty NangateOpenCellLibrary_typical.lib
opt_clean

write_verilog -noattr synth.v
help write_json
write_json synth.json
