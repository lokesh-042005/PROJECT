module mmss_counter (
    input  wire clk,
    input  wire reset,
    input  wire tick,           // 1-sec pulse from clock_divider
    output reg [5:0] seconds,   // 0-59
    output reg [5:0] minutes    // 0-59
);

    always @(posedge clk) begin
        if (reset) begin
            seconds <= 6'd0;
            minutes <= 6'd0;
        end
        else if (tick) begin
            if (seconds == 6'd59) begin
                seconds <= 6'd0;
                if (minutes == 6'd59)
                    minutes <= 6'd0;
                else
                    minutes <= minutes + 1'b1;
            end
            else begin
                seconds <= seconds + 1'b1;
            end
        end
    end

endmodule
