module tb_spi_master();

/* Local variables and signals */

logic clk, rst_n;
int ok;

logic spi_sck_en, spi_sck;
logic rising_edge, falling_edge;
logic [3:0] divider;

logic spi_en, spi_mosi;
logic [5:0] spi_tx_data;

logic spi_miso, spi_done;
logic [11:0] spi_rx_data;

/* Submodules placement */

sck_generator u_sck_generator (
    .clk,
    .rst_n,
    
    .spi_sck,
    .rising_edge,
    .falling_edge,

    .spi_sck_en,
    .divider
);

spi_master dut (
    .clk,
    .rst_n,
    
    .rising_edge,
    .falling_edge,
    .spi_sck_en,

    .spi_miso,
    .spi_mosi,

    .spi_rx_data,
    .spi_tx_data,

    .spi_en,
    .spi_done
);

/* Tasks and functions definitions */

task reset();
	for (int i = 0; i < 2; i++) begin
		@(negedge clk);
		rst_n = i[0];
	end
endtask

task test_spi_transmitter();
	logic [5:0] w_data;

	divider = 4'h2;
	ok = randomize(spi_tx_data);
	
	reset();
	
	fork
		begin
			spi_en = 1'b1;
		
			@(negedge clk);
			spi_en = 1'b0;
		end
		
		begin		
			for (int i = 0; i < 6; i++) begin
				@(posedge spi_sck);
				w_data[5 - i] = spi_mosi;
			end	
		end
	join
	
	assert (w_data == spi_tx_data) else
		$error("w_data: exp: %h, rcv: %h", spi_tx_data, w_data);
		
	repeat (10)
		@(negedge clk);
		
	spi_tx_data = 6'b0;
	
endtask

task test_spi_receiver();
	logic [11:0] r_data;
	
	divider = 4'h2;
	ok = randomize(r_data);

	reset();
	
	fork
		begin
			spi_en = 1'b1;
		
			@(negedge clk);
			spi_en = 1'b0;
		end
	
		begin
			@(posedge clk);
			spi_miso = r_data[11];	/* dana jest dostępna przed narastającym zboczem sck */
			
			for (int i = 0; i < 11; i++) begin
				@(negedge spi_sck);
				spi_miso = r_data[10 - i];
			end
			
			@(negedge spi_sck);
			spi_miso = 1'b0;
		end
		
		begin
			for (int i = 0; i < 12; i++) begin
				assert (!spi_done) else
					$error("spi_done: exp: %b, rcv: %b", 1'b0, spi_done);
				@(negedge spi_sck);
			end
		end
	join
	
	repeat(2)
		@(negedge clk);
			
	assert ((r_data == spi_rx_data) && spi_done) else
		$error("spi_rx_data: exp: %h, rcv: %h, spi_done: exp: %b, rcv: %b", r_data, spi_rx_data, 1'b1, spi_done);
	
	repeat (10)
		@(negedge clk);
	
endtask

task test_spi_master();
	logic [5:0] w_data;
	logic [11:0] r_data;
	process::self().srandom(60);
	
	ok = randomize(r_data);
	ok = randomize(w_data);
	
	divider = 4'h2;
	
	reset();
	
	fork
		begin
			spi_en = 1'b1;
			
			@(negedge clk);
			spi_en = 1'b0;
		end
		
		begin
			@(posedge clk);
			spi_miso = r_data[11];	/* dana jest dostępna przed narastającym zboczem sck */
			
			for (int i = 0; i < 11; i++) begin
				@(negedge spi_sck);
				spi_miso = r_data[10 - i];
			end
			
			@(negedge spi_sck);
			spi_miso = 1'b0;
		end
		
		begin		
			for (int i = 0; i < 6; i++) begin
				@(posedge spi_sck);
				w_data[5 - i] = spi_mosi;
			end	
		end

		begin
			for (int i = 0; i < 12; i++) begin
				assert (!spi_done) else
					$error("spi_done: exp: %b, rcv: %b", 1'b0, spi_done);
				@(negedge spi_sck);
			end
		end
	join

	repeat(2)
		@(negedge clk);
			
	assert ((r_data == spi_rx_data) && spi_done) else
		$error("spi_rx_data: exp: %h, rcv: %h, spi_done: exp: %b, rcv: %b", r_data, spi_rx_data, 1'b1, spi_done);

	assert (w_data == spi_tx_data) else
		$error("w_data: exp: %h, rcv: %h", spi_tx_data, w_data);
	
	repeat(10)
		@(negedge clk);
	
	spi_tx_data = 6'b0;
	
endtask

/* Clock generarion */

initial begin
	clk = 1'b0;
	
	forever
		clk = #10ns ~clk;	/* 50 MHz clock */
end

/* Test */

initial begin
	rst_n = 1'b1;
	spi_en = 1'b0;
	divider = 4'h0;
	spi_tx_data = 6'b0;
	spi_miso = 1'b0;
	
	//test_spi_transmitter();
	//test_spi_receiver();
	test_spi_master();
	
	$finish();
	
end

endmodule
