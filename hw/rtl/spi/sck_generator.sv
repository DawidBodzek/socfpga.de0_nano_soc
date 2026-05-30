module sck_generator (
	input logic 	   clk,
	input logic 	   rst_n,
	
	output logic 	   spi_sck,
	output logic 	   rising_edge,
	output logic 	   falling_edge,
	input  logic [3:0] divider,
	input  logic 	   spi_sck_en
);

/* User defined types and constants */

typedef enum logic {
	IDLE,
	ACTIVE
} state_t;

/* Local variables and signals */

state_t state, state_nxt;

logic sck_nxt, sck_buf;
logic [3:0] counter, counter_nxt;
logic [3:0] half_divider;

/* Signals assignments */

assign rising_edge = (spi_sck & ~sck_buf);
assign falling_edge = (~spi_sck & sck_buf);

/* Module internal logic */

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		counter <= 4'h0;
		half_divider <= 4'h0;
	end else begin
		state <= state_nxt;
		counter <= counter_nxt;
		half_divider <= (divider >> 1) - 1;
	end
end

always_comb begin
	state_nxt = state;
	counter_nxt = counter;
	
	case (state)
		IDLE: begin
			if (spi_sck_en) begin
				state_nxt = ACTIVE;
			end
		end
		
		ACTIVE: begin
			if (counter == half_divider) begin
				counter_nxt = 4'h0;
				
				if (!spi_sck_en) begin
					state_nxt = IDLE;
				end
			end else begin
				counter_nxt = counter + 1;
			end
		end
	endcase
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		spi_sck <= 1'b0;
		sck_buf <= 1'b0;
	end else begin
		spi_sck <= sck_nxt;
		sck_buf <= spi_sck;
	end
end

always_comb begin
	sck_nxt = spi_sck;
	
	case (state)
		IDLE: begin
			if (spi_sck_en) begin
				sck_nxt = ~spi_sck;
			end
		end
			
		ACTIVE: begin
			if (counter == half_divider) begin
				sck_nxt = (divider == 4'h2 && !spi_sck_en) ? spi_sck : ~spi_sck;
			end
		end
	endcase
end

endmodule
