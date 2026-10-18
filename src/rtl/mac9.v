// 3x3 MAC. Flat buses, element index = row*3 + col. Latency: 2 clocks.
module mac9 #(
    parameter PIX_W = 8,
    parameter KER_W = 8,
    parameter OUT_W = 20
)(
    input                          clk,
    input  [9*PIX_W-1:0]           pixels,
    input  [9*KER_W-1:0]           kernels,
    output reg signed [OUT_W-1:0]  result
);
    wire signed [OUT_W-1:0] prod [0:8];

    genvar g;
    generate
        for (g = 0; g < 9; g = g + 1) begin : g_mul
            signed_mult #(.PIX_W(PIX_W), .KER_W(KER_W), .OUT_W(OUT_W)) u_mul (
                .clk    (clk),
                .pixel  (pixels [g*PIX_W +: PIX_W]),
                .kernel (kernels[g*KER_W +: KER_W]),
                .product(prod[g])
            );
        end
    endgenerate

    always @(posedge clk)
        result <= prod[0] + prod[1] + prod[2] + prod[3] + prod[4]
                + prod[5] + prod[6] + prod[7] + prod[8];
endmodule