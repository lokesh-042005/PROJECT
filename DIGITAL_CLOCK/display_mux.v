module display_mux #(
    parameter REFRESH_MAX = 16'd49_999
)(
    input  wire clk,
    input  wire reset,
    input  wire [5:0] minutes,
    input  wire [5:0] seconds,
    output reg  [3:0] digit_out,
    output reg  [3:0] anode
);

    reg [15:0] refresh_count;
    reg [1:0]  state;
    reg        refresh_tick;

    localparam DIG0 = 2'd0,
               DIG1 = 2'd1,
               DIG2 = 2'd2,
               DIG3 = 2'd3;

    always @(posedge clk) begin
        if (reset) begin
            refresh_count <= 16'd0;
            refresh_tick  <= 1'b0;
        end
        else if (refresh_count == REFRESH_MAX) begin
            refresh_count <= 16'd0;
            refresh_tick  <= 1'b1;
        end
        else begin
            refresh_count <= refresh_count + 1'b1;
            refresh_tick  <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (reset)
            state <= DIG0;
        else if (refresh_tick) begin
            case (state)
                DIG0: state <= DIG1;
                DIG1: state <= DIG2;
                DIG2: state <= DIG3;
                DIG3: state <= DIG0;
                default: state <= DIG0;
            endcase
        end
    end

    always @(*) begin
        case (state)
            DIG0: begin
                digit_out = minutes / 10;
                anode     = 4'b1110;
            end
            DIG1: begin
                digit_out = minutes % 10;
                anode     = 4'b1101;
            end
            DIG2: begin
                digit_out = seconds / 10;
                anode     = 4'b1011;
            end
            DIG3: begin
                digit_out = seconds % 10;
                anode     = 4'b0111;
            end
            default: begin
                digit_out = 4'd0;
                anode     = 4'b1111;
            end
        endcase
    end

endmodule
