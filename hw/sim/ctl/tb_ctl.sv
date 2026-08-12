module tb_ctl 
    import csr_pkg::*; 
();

/* Local variables and signals */

logic clk, rst_n;
int ok;

logic [6:0] t_ticks;
logic       t_done, t_load;

logic [11:0] spi_rx_data;
logic [5:0]  spi_tx_data;
logic        spi_en, spi_done, spi_sck, spi_mosi, spi_miso, spi_convst;

logic en, hwclr;
logic fpga_irq;

csr__in_t  csr_in;
csr__out_t csr_out;

/* Submodules placement */

ctl dut (
    .clk,
    .rst_n,

    .en,
    .spi_convst,
    
    .hwclr,
    .spi_rx_data,

    .t_done,
    .t_load,
    .t_ticks,

	.fpga_irq,
	 
    .spi_done,
    .spi_en,

    .csr_in,
	.csr_out
);

timer u_timer (
    .clk,
    .rst_n,

    .t_done,
    .t_load,
    .t_ticks
);

spi u_spi (
    .clk,
    .rst_n,

    .spi_en,
    .spi_done,

    .spi_rx_data,
    .spi_tx_data,

    .spi_sck,

    .spi_mosi,
    .spi_miso
);

/* Tasks and functions definitions */

task reset();
    for (int i = 0; i < 2; i++) begin
        @(negedge clk);
        rst_n = i[0];
    end
endtask

task test_ctl();
	logic [11:0] r_data;
	process::self().srandom(60);

	ok = randomize(r_data);
    ok = randomize(spi_tx_data);

    reset();

    fork
        begin 
            en = 1'b1;

            @(negedge clk);
            en = 1'b0;
        end

        begin
            repeat (76)
                @(negedge clk);
                spi_miso = r_data[11];	/* dana jest dostępna przed narastającym zboczem sck */
                
                for (int i = 0; i < 11; i++) begin
                    @(negedge spi_sck);
                    spi_miso = r_data[10 - i];
                end
                
                @(negedge spi_sck);
                spi_miso = 1'b0;
        end
    join

    wait(spi_done);
    
	repeat(2)
		@(negedge clk);
    assert (csr_in.data.result.next == r_data) else
        $error("adc_data: exp: %h, rcv: %h", r_data, csr_in.data.result.next);

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
    en = 1'b0;
	spi_miso = 1'b0;
    
    test_ctl();
    
    $finish();
end

endmodule
