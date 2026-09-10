module baud_gen (
    input  wire clk,
    input  wire rst,
    output reg  tick
);

    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE  = 115200;
    localparam DIVISOR  = CLK_FREQ / (BAUD_RATE * 16);

    reg [15:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end else if (counter == DIVISOR - 1) begin
            counter <= 16'd0;
            tick    <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            tick    <= 1'b0;
        end
    end

endmodule
