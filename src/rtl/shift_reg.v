// Shift register with enable. dout is DEPTH enabled-samples behind din.
// taps[i*WIDTH +: WIDTH] = stage i (stage 0 = newest = din delayed by 1).
module shift_reg #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input                       clk,
    input                       en,
    input  [WIDTH-1:0]          din,
    output [WIDTH-1:0]          dout,
    output [DEPTH*WIDTH-1:0]    taps
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        if (en) begin
            buffer[0] <= din;
            for (i = 1; i < DEPTH; i = i + 1)
                buffer[i] <= buffer[i-1];
        end
    end

    assign dout = buffer[DEPTH-1];

    genvar g;
    generate
        for (g = 0; g < DEPTH; g = g + 1) begin : g_taps
            assign taps[g*WIDTH +: WIDTH] = buffer[g];
        end
    endgenerate
endmodule