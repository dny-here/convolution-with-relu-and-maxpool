// unsigned pixel * signed kernel. Pixel is zero-extended by 1 bit, then signed.
module signed_mult #(
    parameter PIX_W = 8,
    parameter KER_W = 8,
    parameter OUT_W = 20
)(
    input                         clk,
    input      [PIX_W-1:0]        pixel,
    input signed [KER_W-1:0]      kernel,
    output reg signed [OUT_W-1:0] product
);
    wire signed [PIX_W:0] pix_s = {1'b0, pixel};
    always @(posedge clk)
        product <= pix_s * kernel;
endmodule