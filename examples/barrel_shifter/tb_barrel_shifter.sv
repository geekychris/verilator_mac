// Self-checking testbench for barrel_shifter.
// Drives a handful of directed cases plus a randomized sweep, comparing the
// DUT against SystemVerilog's native shift operators.
module top;
    localparam int WIDTH = 8;

    logic [WIDTH-1:0]              data_in;
    logic [$clog2(WIDTH)-1:0]      shift_amt;
    logic                          right;
    logic                          arith;
    logic [WIDTH-1:0]              data_out;

    barrel_shifter #(.WIDTH(WIDTH)) dut (.*);

    int errors = 0;

    function automatic logic [WIDTH-1:0] golden(
        input logic [WIDTH-1:0]         d,
        input logic [$clog2(WIDTH)-1:0] s,
        input logic                     r,
        input logic                     a
    );
        if (!r)     return d <<  s;
        else if (a) return $signed(d) >>> s;
        else        return d >>  s;
    endfunction

    task automatic check(string label);
        logic [WIDTH-1:0] expected;
        #1;  // let combinational logic settle
        expected = golden(data_in, shift_amt, right, arith);
        if (data_out !== expected) begin
            $display("FAIL [%s]: in=%08b shift=%0d right=%0b arith=%0b  got=%08b expected=%08b",
                     label, data_in, shift_amt, right, arith, data_out, expected);
            errors++;
        end else begin
            $display("ok   [%s]: in=%08b shift=%0d right=%0b arith=%0b  out=%08b",
                     label, data_in, shift_amt, right, arith, data_out);
        end
    endtask

    initial begin
        $display("barrel_shifter testbench (WIDTH=%0d)", WIDTH);

        // Directed cases
        data_in = 8'b0000_0001; shift_amt = 3; right = 0; arith = 0; check("LSL  1<<3");
        data_in = 8'b1000_0000; shift_amt = 7; right = 1; arith = 0; check("LSR  0x80>>7");
        data_in = 8'b1000_0000; shift_amt = 1; right = 1; arith = 1; check("ASR  0x80>>>1");
        data_in = 8'b1111_0000; shift_amt = 4; right = 1; arith = 1; check("ASR  0xF0>>>4");
        data_in = 8'b0101_1010; shift_amt = 0; right = 0; arith = 0; check("shift_amt=0");

        // Randomized sweep
        for (int i = 0; i < 200; i++) begin
            data_in   = WIDTH'($urandom_range(0, (1 << WIDTH) - 1));
            shift_amt = $clog2(WIDTH)'($urandom_range(0, WIDTH - 1));
            right     = 1'($urandom_range(0, 1));
            arith     = 1'($urandom_range(0, 1));
            check($sformatf("rand%0d", i));
        end

        if (errors == 0) $display("PASS: all cases matched golden model");
        else             $display("FAIL: %0d mismatches", errors);

        $finish;
    end
endmodule
