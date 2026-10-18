// IDLE -> RUN (on start) -> DONE (after the last out_valid) -> IDLE
module controller #(
    parameter TOTAL = 49
)(
    input  clk,
    input  rst,
    input  start,
    input  out_valid,
    output run,
    output done
);
    localparam IDLE = 2'd0, RUN = 2'd1, DONE = 2'd2;
    reg [1:0] state;
    reg [7:0] out_cnt;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; out_cnt <= 0;
        end else begin
            case (state)
                IDLE: if (start) begin state <= RUN; out_cnt <= 0; end
                RUN:  if (out_valid) begin
                          if (out_cnt == TOTAL-1) state <= DONE;
                          else out_cnt <= out_cnt + 1'b1;
                      end
                DONE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end

    assign run  = (state == RUN);
    assign done = (state == DONE);
endmodule