// Shared front end. Pixel stream in, 3x3 window out (combinational from din).
// window element g = row*3 + col ; row 0 = oldest (top), col 0 = oldest (left)
// so it lines up with the kernel index row*3+col (plain correlation, no flip).
module window_frontend #(
    parameter N     = 16,
    parameter PIX_W = 8
)(
    input                    clk,
    input                    en,        // shift enable (= pixel valid)
    input  [PIX_W-1:0]       din,
    output [9*PIX_W-1:0]     window
);
    wire [PIX_W-1:0] row1_in = din;     // newest row   (p[i])
    wire [PIX_W-1:0] row0_in;           // 1 row older  (p[i-N])
    wire [PIX_W-1:0] row_2_in;          // 2 rows older (p[i-2N])

    shift_reg #(.DEPTH(N), .WIDTH(PIX_W)) u_lb1 (
        .clk(clk), .en(en), .din(din),     .dout(row0_in),  .taps());
    shift_reg #(.DEPTH(N), .WIDTH(PIX_W)) u_lb2 (
        .clk(clk), .en(en), .din(row0_in), .dout(row_2_in), .taps());

    wire [2*PIX_W-1:0] tap_top, tap_mid, tap_bot;
    shift_reg #(.DEPTH(2), .WIDTH(PIX_W)) u_wt (
        .clk(clk), .en(en), .din(row_2_in), .dout(), .taps(tap_top));
    shift_reg #(.DEPTH(2), .WIDTH(PIX_W)) u_wm (
        .clk(clk), .en(en), .din(row0_in),  .dout(), .taps(tap_mid));
    shift_reg #(.DEPTH(2), .WIDTH(PIX_W)) u_wb (
        .clk(clk), .en(en), .din(row1_in),  .dout(), .taps(tap_bot));

    // taps[1] = delayed 2 (left), taps[0] = delayed 1 (middle), live = right
    assign window = {
        row1_in, tap_bot[0*PIX_W +: PIX_W], tap_bot[1*PIX_W +: PIX_W],   // g=8,7,6
        row0_in, tap_mid[0*PIX_W +: PIX_W], tap_mid[1*PIX_W +: PIX_W],   // g=5,4,3
        row_2_in, tap_top[0*PIX_W +: PIX_W], tap_top[1*PIX_W +: PIX_W]   // g=2,1,0
    };
endmodule