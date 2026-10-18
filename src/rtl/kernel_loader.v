// Loads 27 bytes: kernel0 (9, row-major), kernel1, kernel2.
module kernel_loader (
    input              clk,
    input              rst,
    input              k_valid,
    input  [7:0]       k_data,
    output reg [27*8-1:0] kernels   // byte i = k_data of i-th write
);
    reg [4:0] kcnt;

    always @(posedge clk) begin
        if (rst) begin
            kcnt <= 0;
        end else if (k_valid) begin
            kernels[kcnt*8 +: 8] <= k_data;
            kcnt <= (kcnt == 26) ? 5'd0 : kcnt + 1'b1;
        end
    end
endmodule