module tb_timer();

/* Local variables and signals */

logic clk, rst_n;
int ok;

logic t_done, t_load;
logic [6:0] t_ticks;

/* Submodules placement */

timer dut (
    .clk,
    .rst_n,

    .t_done,
    .t_load,
    .t_ticks
);

/* Tasks and functions definitions */

task reset();
    for (int i = 0; i < 2; i++) begin
        @(negedge clk);
        rst_n = i[0];
    end
endtask

task test_timer();
    ok = randomize(t_ticks);

    reset();

    fork
        begin
            t_load = 1'b1;

            @(negedge clk);
            t_load = 1'b0;
        end

        begin 
            for (int i = 0; i < t_ticks; i++) begin
                @(negedge clk);
                assert (dut.counter == t_ticks - i) else
                    $error("timer counter: exp: %0d, rcv: %0d", t_ticks - i, dut.counter);
            end
        end
    join

    @(negedge clk);
        assert (t_done && dut.counter == 7'b0) else
            $error("t_done: exp: %b, rcv: %b", 1'b1, t_done);

    repeat(10)
        @(negedge clk);

    t_load = 7'b0;

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
    t_load = 1'b0;
    t_ticks = 7'b0;
    
    test_timer();
    
    $finish();
end

endmodule
