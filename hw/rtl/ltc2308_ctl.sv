module ltc2308_ctl import csr_pkg::*; (
    input logic         clk,
    input logic         rst_n,

    output logic        spi_sck,
    output logic        spi_mosi,
    output logic        convst,

    output logic [31:0] avalon_readdata,
    output logic        avalon_readdatavalid,
    output logic        avalon_waitrequest,

    input  logic        spi_miso,

    input  logic [31:0] avalon_writedata,
    input  logic [3:0]  avalon_byteenable,
    input  logic [1:0]  avalon_address,
    input  logic        avalon_read,
    input  logic        avalon_write
);

/* Local variables and signals */

csr__in_t hwif_in;
csr__out_t hwif_out;

logic [11:0] spi_rx_data;
logic spi_en, spi_done;

logic t_done, t_load;
logic [6:0] t_ticks;

/* Submodules placements */

spi u_spi (
    .clk,
    .rst_n,

    .spi_en,
    .spi_done,

    .spi_rx_data,
    .spi_tx_data({hwif_out.cfg.single_ended.value, 
                  hwif_out.cfg.odd.value, 
                  hwif_out.cfg.channel_addr.value,
                  hwif_out.cfg.unipolar.value,
                  hwif_out.cfg.sleep.value}),
    .spi_sck,

    .spi_mosi,
    .spi_miso
);

ctl u_ctl (
    .clk,
    .rst_n,

    .en(hwif_out.ctrl.start_conv.value),

    .t_done,
    .t_load,
    .t_ticks,

    .spi_done,
    .spi_en,
    .spi_rx_data,

    .convst,
    .adc_data(hwif_in)
);

timer u_timer (
    .clk,
    .rst_n,

    .t_done,
    .t_load,
    .t_ticks
);

csr u_csr (
	.clk,
	.arst_n(rst_n),

	.avalon_read,
	.avalon_write,
	.avalon_waitrequest,
	.avalon_address,
	.avalon_writedata,
	.avalon_byteenable,
	.avalon_readdatavalid,
	.avalon_writeresponsevalid(),
	.avalon_readdata,
	.avalon_response(),

	.hwif_in,
	.hwif_out
);

endmodule
