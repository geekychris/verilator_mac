// Combinational barrel shifter built from log2(WIDTH) mux stages.
// Stage i optionally shifts by 2^i if shift_amt[i] is set, so the whole
// shift completes in one cycle regardless of shift_amt.
//
//   right=0          : logical left  shift  (data_in << shift_amt)
//   right=1, arith=0 : logical right shift  (data_in >> shift_amt)
//   right=1, arith=1 : arithmetic right shift (sign-extends MSB)
module barrel_shifter #(
    parameter int WIDTH = 8
) (
    input  logic [WIDTH-1:0]              data_in,
    input  logic [$clog2(WIDTH)-1:0]      shift_amt,
    input  logic                          right,
    input  logic                          arith,
    output logic [WIDTH-1:0]              data_out
);
    localparam int STAGES = $clog2(WIDTH);

    logic [WIDTH-1:0] stage [STAGES:0];
    assign stage[0]  = data_in;
    assign data_out  = stage[STAGES];

    // Continuous assigns (rather than always_comb on an array) so Verilator's
    // per-element dependency analysis sees no false cycle through `stage`.
    for (genvar i = 0; i < STAGES; i++) begin : g_stage
        localparam int N = 1 << i;
        assign stage[i+1] = !shift_amt[i] ? stage[i]
                          : !right        ? {stage[i][WIDTH-1-N:0], {N{1'b0}}}
                          : arith         ? {{N{stage[i][WIDTH-1]}}, stage[i][WIDTH-1:N]}
                                          : {{N{1'b0}},             stage[i][WIDTH-1:N]};
    end
endmodule
