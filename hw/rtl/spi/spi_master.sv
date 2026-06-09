module spi_master (
	input logic 		clk,
	input logic 		rst_n,
	
	output logic [11:0] spi_rx_data,
	output logic 		spi_done,
	output logic 		spi_sck_en,
	output logic 		spi_mosi,
	
	input  logic [5:0]  spi_tx_data,
	input  logic 		spi_en,
	input  logic 		spi_miso,
	
	input  logic 		rising_edge,	/* spi_sck clock */
	input  logic 		falling_edge
);

/* User defined types and constants */

typedef enum logic {
	IDLE,
	ACTIVE
} state_t;

/* Local variables and signals */

state_t state, state_nxt;

logic spi_sck_en_nxt;
logic [12:0] shift_reg, shift_reg_nxt;
logic [3:0] counter, counter_nxt;

logic spi_done_nxt;
logic [11:0] spi_rx_data_nxt;

/* Signals assignments */

assign spi_mosi = shift_reg[12];

/* Module internal logic */

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		counter <= 4'h0;
	end else begin
		state <= state_nxt;
		counter <= counter_nxt;
	end
end

always_comb begin
	state_nxt = state;
	counter_nxt = counter;
	
	case (state)
		IDLE: begin
			if (spi_en) begin
				state_nxt = ACTIVE;
			end
		end
		
		ACTIVE: begin
			if (falling_edge) begin
				
				if (counter == 4'hB) begin
					counter_nxt = 4'h0;
					state_nxt = IDLE;
				end else begin
					counter_nxt = counter + 1;
				end
			end
		end
	endcase
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		spi_sck_en <= 1'b0;
		shift_reg <= 13'b0;
		spi_done <= 1'b0;
		spi_rx_data <= 12'b0;
	end else begin
		spi_sck_en <= spi_sck_en_nxt;
		shift_reg <= shift_reg_nxt;
		spi_done <= spi_done_nxt;
		spi_rx_data <= spi_rx_data_nxt;
	end
end

always_comb begin
	spi_sck_en_nxt = spi_sck_en;
	shift_reg_nxt = shift_reg;
	spi_done_nxt = 1'b0;
	spi_rx_data_nxt = 12'b0;
	
	case (state)
		IDLE: begin
			if (spi_en) begin
				spi_sck_en_nxt = 1'b1;
				shift_reg_nxt[12:7] = spi_tx_data;
			end
		end
		
		ACTIVE: begin
			if (rising_edge) begin
				shift_reg_nxt[0] = spi_miso;
		
				if (counter == 4'hB) begin
					spi_sck_en_nxt = 1'b0;
				end
			end else if (falling_edge) begin
			
				if (counter == 4'hB) begin
					shift_reg_nxt = 13'b0;
					spi_done_nxt = 1'b1;
					spi_rx_data_nxt = shift_reg[11:0];
				end else begin
					shift_reg_nxt = shift_reg << 1;
				end
			end
		end
	endcase
end

endmodule
