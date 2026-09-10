module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire        tick,
    input  wire        RX,
    output reg  [7:0]  rx_data,
    output reg          rx_valid,
    output reg          rx_error
);

    // Stage 1: 2-flop synchronizer for the asynchronous RX input
    reg rx_sync1, rx_sync2;
    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= RX;
            rx_sync2 <= rx_sync1;
        end
    end

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            tick_cnt <= 4'd0;
            bit_cnt  <= 3'd0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    rx_valid <= 1'b0;
                    rx_error <= 1'b0;
                    if (rx_sync2 == 1'b0) begin
                        state    <= START;
                        tick_cnt <= 4'd0;
                    end
                end

                START: begin
                    if (tick) begin
                        if (tick_cnt == 4'd7) begin
                            if (rx_sync2 == 1'b1) begin
                                // glitch, not a real start bit - abort now
                                state <= IDLE;
                            end
                            // else: confirmed real start bit - fall through,
                            // keep counting to the end of this bit period below
                        end

                        if (tick_cnt == 4'd15) begin
                            // full 16-tick start-bit period has elapsed
                            tick_cnt <= 4'd0;
                            bit_cnt  <= 3'd0;
                            state    <= DATA;
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end

                DATA: begin
                    if (tick) begin
                        if (tick_cnt == 4'd7) begin
                            shift_reg[bit_cnt] <= rx_sync2;
                        end
                        if (tick_cnt == 4'd15) begin
                            tick_cnt <= 4'd0;
                            if (bit_cnt == 3'd7) begin
                                state <= STOP;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (tick) begin
                        if (tick_cnt == 4'd7) begin
                            if (rx_sync2 == 1'b1) begin
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                                rx_error <= 1'b0;
                            end else begin
                                rx_valid <= 1'b0;
                                rx_error <= 1'b1;
                            end
                        end
                        if (tick_cnt == 4'd15) begin
                            tick_cnt <= 4'd0;
                            state    <= IDLE;
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
