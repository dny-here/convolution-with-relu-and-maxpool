`timescale 1ns/1ps
module tb_top;
    parameter N     = 16;
    parameter SHIFT = 0;       // iverilog -P tb_top.SHIFT=8 ...
    localparam OUT = 7;

    reg         clk = 0, rst = 1, start = 0;
    reg         k_valid = 0, pix_valid = 0;
    reg  [7:0]  k_data = 0, pix_data = 0;
    wire        out_valid, done;
    wire [23:0] out_data;

    conv_pool_relu_top #(.N(N), .SHIFT(SHIFT)) dut (
        .clk(clk), .rst(rst), .start(start),
        .k_valid(k_valid), .k_data(k_data),
        .pix_valid(pix_valid), .pix_data(pix_data),
        .out_valid(out_valid), .out_data(out_data), .done(done)
    );

    always #5 clk = ~clk;

    reg [7:0]  img  [0:N*N-1];
    reg [7:0]  kern [0:26];
    reg [23:0] exp_mem [0:OUT*OUT-1];
    integer i, idx = 0, errors = 0;

    always @(posedge clk) begin
        if (out_valid) begin
            if (idx >= OUT*OUT) begin
                $display("ERROR: extra output %0d", idx);
                errors = errors + 1;
            end else if (out_data !== exp_mem[idx]) begin
                $display("MISMATCH #%0d (r=%0d,c=%0d): got %06h exp %06h",
                         idx, idx/OUT, idx%OUT, out_data, exp_mem[idx]);
                errors = errors + 1;
            end
            idx = idx + 1;
        end
    end

    initial begin
        #1_000_000;
        $display("TIMEOUT: done never asserted");
        $finish;
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        $readmemh("image.hex",    img);
        $readmemh("kernel.hex",   kern);
        $readmemh("expected.hex", exp_mem);

        repeat (4) @(posedge clk);
        rst <= 0;

        for (i = 0; i < 27; i = i + 1) begin
            @(posedge clk);
            k_valid <= 1; k_data <= kern[i];
        end
        @(posedge clk); k_valid <= 0;

        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;

        for (i = 0; i < N*N; i = i + 1) begin
            @(posedge clk);
            pix_valid <= 1; pix_data <= img[i];
        end
        @(posedge clk); pix_valid <= 0;

        wait (done);
        repeat (3) @(posedge clk);

        if (idx != OUT*OUT) begin
            $display("ERROR: got %0d outputs, expected %0d", idx, OUT*OUT);
            errors = errors + 1;
        end
        if (errors == 0) $display("PASS: all %0d outputs match", OUT*OUT);
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule