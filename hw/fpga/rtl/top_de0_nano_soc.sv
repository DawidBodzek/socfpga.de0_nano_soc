/* Copyright (C) 2026  AGH University of Krakow */

module top_de0_nano_soc (
    input logic         CLOCK_50,			/* FPGA CLK */

    output logic [14:0] HPS_DDR3_ADDR,		/* HPS */
    output logic [2:0]  HPS_DDR3_BA,
    output logic        HPS_DDR3_CAS_N,
    output logic        HPS_DDR3_CKE,
    output logic        HPS_DDR3_CS_N,
    output logic [3:0]  HPS_DDR3_DM,
    output logic        HPS_DDR3_ODT,
    output logic        HPS_DDR3_RAS_N,
    output logic        HPS_DDR3_RESET_N,
    output logic        HPS_DDR3_WE_N,
    output logic        HPS_DDR3_CK_P,
    output logic        HPS_DDR3_CK_N,
    inout logic [31:0]  HPS_DDR3_DQ,
    inout logic [3:0]   HPS_DDR3_DQS_N,
    inout logic [3:0]   HPS_DDR3_DQS_P,
    input logic         HPS_DDR3_RZQ,

    output logic        HPS_ENET_GTX_CLK,
    output logic        HPS_ENET_MDC,
    output logic [3:0]  HPS_ENET_TX_DATA,
    output logic        HPS_ENET_TX_EN,
    inout logic         HPS_ENET_INT_N,
    inout logic         HPS_ENET_MDIO,
    input logic         HPS_ENET_RX_CLK,
    input logic [3:0]   HPS_ENET_RX_DATA,
    input logic         HPS_ENET_RX_DV,

    output logic        HPS_SD_CLK,
    inout logic         HPS_SD_CMD,
    inout logic [3:0]   HPS_SD_DATA,

    output logic        HPS_UART_TX,
    input logic         HPS_UART_RX,

    output logic        HPS_USB_STP,
    inout logic [7:0]   HPS_USB_DATA,
    input logic         HPS_USB_CLKOUT,
    input logic         HPS_USB_DIR,
    input logic         HPS_USB_NXT,
	 
	output logic 		ADC_CONVST,			/* ADC */
	output logic 		ADC_SCLK,
	output logic 		ADC_SDI,
	input logic  		ADC_SDO
);

/* Signal Tap */

(* noprune *) logic DEBUG_spi_sck;
(* noprune *) logic DEBUG_spi_mosi;
(* noprune *) logic DEBUG_spi_convst;
(* noprune *) logic DEBUG_spi_miso;

always_ff @(posedge CLOCK_50) begin
	DEBUG_spi_convst <= ADC_CONVST;
	DEBUG_spi_sck <= ADC_SCLK;
	DEBUG_spi_mosi <= ADC_SDI;
	DEBUG_spi_miso <= ADC_SDO;
end

/* Submodules placement */

de0_nano_soc u0 (
    .clk_clk(CLOCK_50),
    .reset_reset_n(1'b1),

    .hps_h2f_reset_reset_n(),

    .memory_mem_a(HPS_DDR3_ADDR),
    .memory_mem_ba(HPS_DDR3_BA),
    .memory_mem_ck(HPS_DDR3_CK_P),
    .memory_mem_ck_n(HPS_DDR3_CK_N),
    .memory_mem_cke(HPS_DDR3_CKE),
    .memory_mem_cs_n(HPS_DDR3_CS_N),
    .memory_mem_ras_n(HPS_DDR3_RAS_N),
    .memory_mem_cas_n(HPS_DDR3_CAS_N),
    .memory_mem_we_n(HPS_DDR3_WE_N),
    .memory_mem_reset_n(HPS_DDR3_RESET_N),
    .memory_mem_dq(HPS_DDR3_DQ),
    .memory_mem_dqs(HPS_DDR3_DQS_P),
    .memory_mem_dqs_n(HPS_DDR3_DQS_N),
    .memory_mem_odt(HPS_DDR3_ODT),
    .memory_mem_dm(HPS_DDR3_DM),
    .memory_oct_rzqin(HPS_DDR3_RZQ),

    .hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),
    .hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),
    .hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),
    .hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),
    .hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),
    .hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),
    .hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),
    .hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),
    .hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),
    .hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),
    .hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),
    .hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),
    .hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),
    .hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),

    .hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),
    .hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),
    .hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),
    .hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),
    .hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),
    .hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),

    .hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),
    .hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),

    .hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),
    .hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),
    .hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),
    .hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),
    .hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),
    .hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),
    .hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),
    .hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),
    .hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),
    .hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),
    .hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),
    .hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),
	 
	 .spi_adc_sclk(ADC_SCLK),
	 .spi_adc_sdi(ADC_SDI),
	 .spi_adc_convst(ADC_CONVST),
	 .spi_adc_sdo(ADC_SDO)
);

endmodule
