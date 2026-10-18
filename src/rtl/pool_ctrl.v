// Counts conv outputs (row, col over CONV x CONV, CONV = N-2).
//   h_en : odd column  -> a horizontal pair is complete (write/shift row buffer)
//   emit : odd col AND odd row -> a 2x2 block is complete (stride 2 pooled output)
module pool_ctrl #(
    parameter CONV = 14
)(
    input  clk,
    input  rst,
    input  conv_valid,
    output h_en,
    output emit
);
    reg [7:0] col, row;

    always @(posedge clk) begin
        if (rst) begin
            col <= 0; row <= 0;
        end else if (conv_valid) begin
            if (col == CONV-1) begin
                col <= 0;
                row <= (row == CONV-1) ? 8'd0 : row + 1'b1;
            end else
                col <= col + 1'b1;
        end
    end

    assign h_en = conv_valid && col[0];
    assign emit = h_en && row[0];
endmodule