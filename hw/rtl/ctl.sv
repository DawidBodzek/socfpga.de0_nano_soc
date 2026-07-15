module ctl 
    import csr_pkg::*; 
(
    input logic         clk,
    input logic         rst_n,

    output logic [6:0]  t_ticks,
    output logic        t_load,
    output logic        spi_en,
    output logic        spi_convst,

    input  logic [11:0] spi_rx_data,
    input  logic        spi_done,
    input  logic        t_done,
    input  logic        en,

    output csr__in_t    adc_data
);

/* User defined types and constants */

typedef enum logic [1:0] {
    IDLE,
    TRIGGER,
    DELAY,
    SPI_ACTIVE
} state_t;

localparam T_CONV = 80;

/* Local variables and signals */

state_t   state, state_nxt;
csr__in_t adc_data_nxt;

logic [6:0] t_ticks_nxt;
logic       t_load_nxt, spi_en_nxt, spi_convst_nxt;

/* Module internal logic */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= state_nxt;
    end
end

always_comb begin
    state_nxt = state;

    case (state)
        IDLE: begin
            if (en) begin
                state_nxt = TRIGGER;
            end
        end

        TRIGGER: state_nxt = DELAY;

        DELAY: begin 
            if (t_done && !t_load) begin
                state_nxt = SPI_ACTIVE;
            end
        end

        SPI_ACTIVE: begin 
            if (spi_done) begin
                state_nxt = IDLE;
            end
        end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        t_load <= 1'b0;
        spi_en <= 1'b0;
        spi_convst <= 1'b0;
        t_ticks <= 7'b0;
        adc_data.data.result.next <= 12'b0;
    end else begin
        t_load <= t_load_nxt;
        spi_en <= spi_en_nxt;
        spi_convst <= spi_convst_nxt;
        t_ticks <= t_ticks_nxt;
        adc_data.data.result.next <= adc_data_nxt.data.result.next;
    end
end

always_comb begin
    spi_convst_nxt = 1'b0;
    t_load_nxt = 1'b0;
    t_ticks_nxt = 7'b0;
    spi_en_nxt = 1'b0;
    adc_data_nxt.data.result.next = adc_data.data.result.next;

    case (state)
        IDLE: begin
            if (en) begin
                spi_convst_nxt = 1'b1;
            end
        end

        TRIGGER: begin
            t_load_nxt = 1'b1;
            t_ticks_nxt = T_CONV - 4;
        end

        DELAY: begin
            if (t_done && !t_load) begin
                spi_en_nxt = 1'b1;
            end
        end

        SPI_ACTIVE: begin
            if (spi_done) begin
                adc_data_nxt.data.result.next = spi_rx_data;
            end
        end
    endcase
end

endmodule
