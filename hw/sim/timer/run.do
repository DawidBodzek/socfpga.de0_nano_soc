vlog -sv \
	../../rtl/timer.sv \
	tb_timer.sv
	
vsim -voptargs="+acc" tb_timer

add wave \
	sim:/tb_timer/clk \
	sim:/tb_timer/rst_n 
	
add wave \
	-divider "load timer" \
		sim:/tb_timer/t_load \
        sim:/tb_timer/t_ticks
	
add wave \
	-divider "timer done" \
		sim:/tb_timer/t_done
	
add wave \
	-divider "internal signals" \
		sim:/tb_timer/dut/counter 

run -all	
