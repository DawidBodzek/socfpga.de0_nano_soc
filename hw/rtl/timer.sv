module timer (
    input  logic       clk,
    input  logic       rst_n,

    output logic       t_done,
    
    input  logic       t_load,
    input  logic [6:0] t_ticks
);

/* Local variables and signals */

logic [6:0] counter, counter_nxt;

/* Signals assignments */

assign t_done = ~(|counter);

/* Module internal logic */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 7'b0;
    end else begin
        counter <= counter_nxt;
    end
end

always_comb begin
    counter_nxt = (|counter) ? counter - 1 : 7'b0;
    
    if (t_load) begin
        counter_nxt = t_ticks;
    end
end

endmodule
