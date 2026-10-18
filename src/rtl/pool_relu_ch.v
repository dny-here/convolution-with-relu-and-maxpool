// Per-channel 2x2/stride-2 maxpool (horizontal first, then vertical) + ReLU/sat.
// Latency from conv_in/emit: 2 clocks (pool_q register + relu_sat register).
module pool_relu_ch #(
    parameter IN_W   = 20,
    parameter OUT_W  = 8,
    parameter POOL_W = 7,           // pooled columns per row = (N-2)/2
    parameter SHIFT  = 0            // output quantization: divide by 2^SHIFT
)(
    input                       clk,
    input                       conv_valid,
    input  signed [IN_W-1:0]    conv_in,
    input                       h_en,
    output       [OUT_W-1:0]    dout
);
    wire signed [IN_W-1:0] prev, rowbuf_out;

    // previous conv sample (the even column of the pair)
    shift_reg #(.DEPTH(1), .WIDTH(IN_W)) u_prev (
        .clk(clk), .en(conv_valid), .din(conv_in), .dout(prev), .taps());

    wire signed [IN_W-1:0] hmax = (conv_in > prev) ? conv_in : prev;

    // one pooled row of horizontal maxes; shifts once per horizontal pair
    shift_reg #(.DEPTH(POOL_W), .WIDTH(IN_W)) u_rowbuf (
        .clk(clk), .en(h_en), .din(hmax), .dout(rowbuf_out), .taps());

    wire signed [IN_W-1:0] vmax = (hmax > rowbuf_out) ? hmax : rowbuf_out;

    reg signed [IN_W-1:0] pool_q;
    always @(posedge clk) pool_q <= vmax;

    relu_sat #(.IN_W(IN_W), .OUT_W(OUT_W), .SHIFT(SHIFT)) u_relu (
        .clk(clk), .din(pool_q), .dout(dout));
endmodule