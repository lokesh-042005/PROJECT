module clock_divider #(
    parameter COUNT_MAX = 26'd49_999_999   // default = real 1 second @ 50MHz
)(
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    reg [25:0] count;

    always @(posedge clk) begin
        if (reset) begin
            count <= 26'd0;
            tick  <= 1'b0;
        end
        else if (count == COUNT_MAX) begin
            count <= 26'd0;
            tick  <= 1'b1;
        end
        else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end

endmodule
