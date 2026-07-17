module ltc2308_ctl 
    import csr_pkg::*; 
(
    input logic         clk,
    input logic         rst_n,

    output logic 	    fpga_irq,
	 
    output logic        spi_sck,
    output logic        spi_mosi,
    output logic        spi_convst,
    input  logic        spi_miso,

    output logic [31:0] avalon_readdata,
    output logic        avalon_readdatavalid,
    input  logic        avalon_read,

    input  logic [31:0] avalon_writedata,
    input  logic        avalon_write,

    output logic [1:0]  avalon_response,
    output logic        avalon_writeresponsevalid,

    output logic        avalon_waitrequest,
    input  logic [3:0]  avalon_byteenable,
    input  logic [1:0]  avalon_address
);

/* Local variables and signals */

csr__out_t csr_out;
csr__in_t  csr_in;

logic [11:0] spi_rx_data;
logic        spi_en, spi_done;

logic [6:0] t_ticks;
logic       t_done, t_load;

/* Submodules placements */

spi u_spi (
    .clk,
    .rst_n,

    .spi_en,
    .spi_done,

    .spi_rx_data,
    .spi_tx_data({csr_out.cfg.single_ended.value, 
                  csr_out.cfg.odd.value, 
                  csr_out.cfg.channel_addr.value,
                  csr_out.cfg.unipolar.value,
                  csr_out.cfg.sleep.value}),
    .spi_sck,

    .spi_mosi,
    .spi_miso
);

ctl u_ctl (
    .clk,
    .rst_n,

    .en(csr_out.ctrl.start_conv.value),
    .spi_convst,
    
    .hwclr(csr_out.data.result.swacc),
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

csr_wrapper u_csr_wrapper (
	.clk,
	.rst_n,

	.avalon_readdata,
    .avalon_readdatavalid,
	.avalon_read,

    .avalon_writedata,
	.avalon_write,

    .avalon_response,
	.avalon_writeresponsevalid,

	.avalon_waitrequest,
	.avalon_byteenable,
    .avalon_address,

	.csr_out,
    .csr_in
);

endmodule
