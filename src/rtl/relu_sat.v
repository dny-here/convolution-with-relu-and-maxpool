// ReLU + quantize to OUT_W bits. Input is signed. 1 cycle latency.
//   negative         -> 0
//   else din >> SHIFT (divide by 2^SHIFT), saturated to 2^OUT_W - 1
// SHIFT = 0 gives plain ReLU + saturation.
module relu_sat #(
    parameter IN_W  = 20,
    parameter OUT_W = 8,
    parameter SHIFT = 0
)(
    input                         clk,
    input  signed [IN_W-1:0]      din,
    output reg    [OUT_W-1:0]     dout
);
    localparam signed [IN_W-1:0] MAXV = (1 << OUT_W) - 1;

    wire signed [IN_W-1:0] scaled = din >>> SHIFT;   // arithmetic shift

    always @(posedge clk) begin
        if (din < 0)            dout <= {OUT_W{1'b0}};
        else if (scaled > MAXV) dout <= {OUT_W{1'b1}};
        else                    dout <= scaled[OUT_W-1:0];
    end
endmodule