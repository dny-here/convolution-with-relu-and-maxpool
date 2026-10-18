module conv_pool_relu_top #(
    parameter N     = 16,            // image size (kernel fixed 3x3, 3 channels)
    parameter SHIFT = 0              // output quantization: divide by 2^SHIFT, then saturate
)(
    input         clk,
    input         rst,
    input         k_valid,
    input  [7:0]  k_data,
    input         start,
    input         pix_valid,
    input  [7:0]  pix_data,
    output        out_valid,
    output [23:0] out_data,          // {ch2, ch1, ch0}
    output        done
);
    localparam CONV  = N - 2;
    localparam POOLN = CONV / 2;

    wire run;
    wire pix_en = pix_valid & run;

    // kernels
    wire [27*8-1:0] kernels;
    kernel_loader u_kl (.clk(clk), .rst(rst), .k_valid(k_valid),
                        .k_data(k_data), .kernels(kernels));

    // shared front end
    wire [9*8-1:0] window;
    wire           window_valid;
    window_frontend #(.N(N)) u_fe (.clk(clk), .en(pix_en), .din(pix_data), .window(window));
    conv_ctrl #(.N(N)) u_cc (.clk(clk), .rst(rst), .pix_en(pix_en), .window_valid(window_valid));

    // valid follows the 2-cycle MAC latency
    reg v1, v2;
    always @(posedge clk) begin
        if (rst) begin v1 <= 0; v2 <= 0; end
        else     begin v1 <= window_valid; v2 <= v1; end
    end
    wire conv_valid = v2;

    wire h_en, emit;
    pool_ctrl #(.CONV(CONV)) u_pc (.clk(clk), .rst(rst), .conv_valid(conv_valid),
                                   .h_en(h_en), .emit(emit));

    // 3 channels: MAC -> pool -> ReLU
    wire signed [19:0] conv_res [0:2];
    wire        [7:0]  ch_out   [0:2];
    genvar c;
    generate
        for (c = 0; c < 3; c = c + 1) begin : g_ch
            mac9 u_mac (.clk(clk), .pixels(window),
                        .kernels(kernels[c*72 +: 72]), .result(conv_res[c]));
            pool_relu_ch #(.POOL_W(POOLN), .SHIFT(SHIFT)) u_pr (
                .clk(clk), .conv_valid(conv_valid), .conv_in(conv_res[c]),
                .h_en(h_en), .dout(ch_out[c]));
        end
    endgenerate

    // emit -> pool_q (1) -> relu (2)
    reg e1, e2;
    always @(posedge clk) begin
        if (rst) begin e1 <= 0; e2 <= 0; end
        else     begin e1 <= emit; e2 <= e1; end
    end
    assign out_valid = e2;
    assign out_data  = {ch_out[2], ch_out[1], ch_out[0]};

    controller #(.TOTAL(POOLN*POOLN)) u_ctrl (
        .clk(clk), .rst(rst), .start(start), .out_valid(out_valid),
        .run(run), .done(done));
endmodule