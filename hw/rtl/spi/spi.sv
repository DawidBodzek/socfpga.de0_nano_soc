module spi (
    input logic         clk,
    input logic         rst_n,

    output logic [11:0] spi_rx_data,
    input  logic [5:0]  spi_tx_data,

    output logic        spi_sck,
    output logic        spi_mosi,
    input  logic        spi_miso,
    
    output logic        spi_done,
    input  logic        spi_en
);

/* Local variables and signals */

logic rising_edge, falling_edge;
logic spi_sck_en;

/* Submodules placements */

spi_master u_spi_master (
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

sck_generator u_sck_generator (
    .clk,
    .rst_n,
    
    .spi_sck,
    .rising_edge,
    .falling_edge,

    .spi_sck_en,
    .divider(4'h2)
);

endmodule
