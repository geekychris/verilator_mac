// Tiny counter for smoke-testing Verilator.
// Runs for a fixed number of cycles, prints each value, then $finish.
module counter (
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] count
);
    always_ff @(posedge clk) begin
        if (!rst_n) count <= 8'd0;
        else        count <= count + 8'd1;
    end
endmodule

module top;
    logic       clk = 0;
    logic       rst_n = 0;
    logic [7:0] count;

    counter dut (.clk(clk), .rst_n(rst_n), .count(count));

    // 10 ns clock
    always #5 clk = ~clk;

    initial begin
        $display("verilator smoke-test: counter starting");
        #12 rst_n = 1;
        repeat (8) @(posedge clk) $display("  cycle: count=%0d", count);
        #1;  // let NBA settle for the 8th edge
        if (count !== 8'd8) begin
            $display("FAIL: expected count=8, got %0d", count);
            $fatal(1);
        end
        $display("PASS: counter reached %0d", count);
        $finish;
    end
endmodule
