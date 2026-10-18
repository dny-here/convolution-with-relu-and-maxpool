// Counts incoming pixels (row, col). window_valid = a full 3x3 window exists
// with its bottom-right corner on the pixel currently on din.
module conv_ctrl #(
    parameter N = 16
)(
    input  clk,
    input  rst,
    input  pix_en,
    output window_valid
);
    reg [7:0] col, row;

    always @(posedge clk) begin
        if (rst) begin
            col <= 0; row <= 0;
        end else if (pix_en) begin
            if (col == N-1) begin
                col <= 0;
                row <= (row == N-1) ? 8'd0 : row + 1'b1;
            end else
                col <= col + 1'b1;
        end
    end

    assign window_valid = pix_en && (row >= 2) && (col >= 2);
endmodule