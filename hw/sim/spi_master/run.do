vlog -sv \
	../../rtl/spi/spi_master.sv \
	../../rtl/spi/sck_generator.sv \
	tb_spi_master.sv
	
vsim -voptargs="+acc" tb_spi_master

add wave \
	sim:/tb_spi_master/clk \
	sim:/tb_spi_master/rst_n 
	
add wave \
	-divider "sck" \
		sim:/tb_spi_master/spi_sck
add wave \
	-divider "enable spi" \
		sim:/tb_spi_master/spi_en
	
add wave \
	-divider "transmitter" \
		sim:/tb_spi_master/spi_mosi \
		sim:/tb_spi_master/spi_tx_data 

add wave \
	-divider "receiver" \
		sim:/tb_spi_master/spi_miso \
		sim:/tb_spi_master/spi_rx_data \
		sim:/tb_spi_master/spi_done
	
add wave \
	-divider "internal signals" \
		sim:/tb_spi_master/dut/shift_reg \
		sim:/tb_spi_master/dut/counter \
		sim:/tb_spi_master/dut/state

run -all	
