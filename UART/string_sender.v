module string_sender (
    input  wire        clk,
    input  wire        rst,
    input  wire         tx_busy,
    output reg          tx_start,
    output reg  [7:0]   tx_data
);

    localparam MSG_LEN = 18;

    reg [7:0] message [0:MSG_LEN-1];
    reg [4:0] index;

    initial begin
        message[0]  = "S";
        message[1]  = "I";
        message[2]  = "L";
        message[3]  = "I";
        message[4]  = "C";
        message[5]  = "O";
        message[6]  = "N";
        message[7]  = " ";
        message[8]  = "C";
        message[9]  = "R";
        message[10] = "A";
        message[11] = "F";
        message[12] = "T";
        message[13] = " ";
        message[14] = "V";
        message[15] = "L";
        message[16] = "S";
        message[17] = "I";
    end

    localparam S_IDLE      = 3'd0;
    localparam S_ASSERT    = 3'd1;
    localparam S_WAIT_BUSY = 3'd2;
    localparam S_WAIT_DONE = 3'd3;
    localparam S_NEXT      = 3'd4;
    localparam S_DONE      = 3'd5;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            index    <= 5'd0;
            tx_start <= 1'b0;
            tx_data  <= 8'd0;
        end else begin
            case (state)

                S_IDLE: begin
                    index    <= 5'd0;
                    tx_start <= 1'b0;
                    state    <= S_ASSERT;
                end

                S_ASSERT: begin
                    tx_data  <= message[index];
                    tx_start <= 1'b1;
                    state    <= S_WAIT_BUSY;
                end

                S_WAIT_BUSY: begin
                    tx_start <= 1'b0;
                    if (tx_busy)
                        state <= S_WAIT_DONE;
                end

                S_WAIT_DONE: begin
                    if (!tx_busy)
                        state <= S_NEXT;
                end

                S_NEXT: begin
                    if (index == MSG_LEN - 1)
                        state <= S_DONE;
                    else begin
                        index <= index + 1'b1;
                        state <= S_ASSERT;
                    end
                end

                S_DONE: begin
                    tx_start <= 1'b0;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
