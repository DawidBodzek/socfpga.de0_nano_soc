module tb_sck_generator();

/* Local variables and signals */

logic clk, rst_n;
logic ref_clk;

logic spi_sck_en, spi_sck;
logic rising_edge, falling_edge;
logic [3:0] divider;

/* Signals assignments */

assign divider = 4'h2;

/* Submodules placement */

sck_generator dut (
    .clk,
    .rst_n,
    
    .spi_sck,
    .rising_edge,
    .falling_edge,

    .spi_sck_en,
    .divider
);

/* Tasks and functions definitions */

task reset();
	for (int i = 0; i < 2; i++) begin
		@(negedge clk);
		rst_n = i[0];
	end
endtask

task test_disabled_clk_division();
	
	reset();
	spi_sck_en = 1'b0;
	
	for (int i = 0; i < 25; i++) begin
		@(negedge clk);
		assert (!spi_sck) else
			$error("spi_sck: exp: %b, rcv: %b", 1'b0, spi_sck);
	end
endtask

task test_enabled_clk_division();
	
	reset();
	
	@(negedge clk);
	spi_sck_en = 1'b1;
	
	fork 
		begin
			repeat (49)
				@(negedge clk);
			
			spi_sck_en = 1'b0;
		end
		
		begin
			for (int i = 0; i < 50; i++) begin
				assert (spi_sck == ref_clk) else	/* Przesunięte w fazie, ale mają te same wartośći */
					$error("spi_sck: exp: %b, rcv: %b", ref_clk, spi_sck);
				@(negedge clk);
			end
		end
	join
	
	repeat (10)
		@(negedge clk);
	
endtask

/* Clock generarion */

initial begin
	clk = 1'b0;
	
	forever
		clk = #10ns ~clk;	/* 50 MHz clock */
end

initial begin
	ref_clk = 1'b0;
	
	forever
		ref_clk = #(10ns * divider) ~ref_clk;
end

/* Test */

initial begin
	rst_n = 1'b1;
	spi_sck_en = 1'b0;
	
	test_disabled_clk_division();
	test_enabled_clk_division();
	
	$finish();
end

endmodule
