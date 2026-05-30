vlog -sv \
	../../rtl/spi/sck_generator.sv \
	tb_sck_generator.sv
	
vsim -voptargs="+acc" tb_sck_generator

add wave \
	sim:/tb_sck_generator/clk \
	sim:/tb_sck_generator/rst_n \
	sim:/tb_sck_generator/spi_sck_en
	
add wave \
	-divider "generated clock" \
		sim:/tb_sck_generator/spi_sck
	
add wave \
	-divider "edge detection" \
		sim:/tb_sck_generator/rising_edge \
		sim:/tb_sck_generator/falling_edge
	
add wave \
	-divider "internal signals" \
		sim:/tb_sck_generator/dut/counter \
		sim:/tb_sck_generator/dut/state

run -all	
