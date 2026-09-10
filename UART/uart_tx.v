module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire        tick,
    input  wire        tx_start,
    input  wire [7:0]  tx_data,
    output reg         tx_busy,
    output reg         TX
);

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
            TX       <= 1'b1;
            tx_busy  <= 1'b0;
            tick_cnt <= 4'd0;
            bit_cnt  <= 3'd0;
        end else begin
            case (state)

                IDLE: begin
                    TX <= 1'b1;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        tick_cnt  <= 4'd0;
                        state     <= START;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                START: begin
                    TX <= 1'b0;
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt <= 4'd0;
                            bit_cnt  <= 3'd0;
                            state    <= DATA;
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end

                DATA: begin
                    TX <= shift_reg[0];
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt  <= 4'd0;
                            shift_reg <= shift_reg >> 1;
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
                    TX <= 1'b1;
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt <= 4'd0;
                            tx_busy  <= 1'b0;
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
