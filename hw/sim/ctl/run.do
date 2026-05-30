vlog -sv \
   	../../rtl/csr/csr_pkg.sv \
	../../rtl/spi/spi_master.sv \
	../../rtl/spi/sck_generator.sv \
	../../rtl/spi/spi.sv \
	../../rtl/timer.sv \
	../../rtl/ctl.sv \
	tb_ctl.sv
	
vsim -voptargs="+acc" tb_ctl

add wave \
	sim:/tb_ctl/clk \
	sim:/tb_ctl/rst_n 
	
add wave \
	-divider "convst" \
		sim:/tb_ctl/convst
		
add wave \
	-divider "timer" \
		sim:/tb_ctl/dut/t_load \
		sim:/tb_ctl/dut/t_done

add wave \
	-divider "sck" \
		sim:/tb_ctl/spi_sck
add wave \
	-divider "enable spi" \
		sim:/tb_ctl/spi_en
	
add wave \
	-divider "transmitter" \
		sim:/tb_ctl/spi_mosi \
		sim:/tb_ctl/spi_tx_data 

add wave \
	-divider "receiver" \
		sim:/tb_ctl/spi_miso \
		sim:/tb_ctl/adc_data \
		sim:/tb_ctl/spi_done
	
add wave \
	-divider "internal signals" \
		sim:/tb_ctl/dut/state

run -all	
