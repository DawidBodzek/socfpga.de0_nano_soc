module csr_wrapper 
    import csr_pkg::*;
(
    input logic         clk,
    input logic         rst_n,

    output logic [31:0] avalon_readdata,
    output logic [1:0]  avalon_response,
    output logic        avalon_readdatavalid,
    output logic        avalon_writeresponsevalid,
    output logic        avalon_waitrequest,

    input  logic [31:0] avalon_writedata,
    input  logic [3:0]  avalon_byteenable,
    input  logic [1:0]  avalon_address,
    input  logic        avalon_read,
    input  logic        avalon_write,
        
    output csr__out_t   csr_out,
    input  csr__in_t    csr_in
);

/* Local variables and signals */

logic [31:0] avalon_readdata_nxt;
logic avalon_writeresponsevalid_nxt;
logic avalon_readdatavalid_nxt;

/* Submodules placement */

csr u_csr (
	.clk,
	.arst_n(rst_n),

	.avalon_read,
	.avalon_write,
	.avalon_waitrequest,
	.avalon_address,
	.avalon_writedata,
	.avalon_byteenable,
	.avalon_readdatavalid(avalon_readdatavalid_nxt),
	.avalon_writeresponsevalid(avalon_writeresponsevalid_nxt),
	.avalon_readdata(avalon_readdata_nxt),
	.avalon_response,

	.hwif_in(csr_in),
	.hwif_out(csr_out)
);

/* Module internal logic */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        avalon_readdata <= 32'b0;
        avalon_readdatavalid <= 1'b0;
        avalon_writeresponsevalid <= 1'b0;
    end else begin
        avalon_readdata <= avalon_readdata_nxt;
        avalon_readdatavalid <= avalon_readdatavalid_nxt;
        avalon_writeresponsevalid <= avalon_writeresponsevalid_nxt;
    end
end

endmodule
