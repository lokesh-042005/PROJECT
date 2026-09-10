module uart_top (
    input  wire        clk,
    input  wire        rst,
    output wire         TX,
    input  wire         RX,
    output wire [7:0]  rx_data,
    output wire         rx_valid,
    output wire         rx_error
);

    wire       tick;
    wire       tx_busy;
    wire       tx_start;
    wire [7:0] tx_data;

    baud_gen #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (115200)
    ) baud_gen_inst (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );

    string_sender string_sender_inst (
        .clk      (clk),
        .rst      (rst),
        .tx_busy  (tx_busy),
        .tx_start (tx_start),
        .tx_data  (tx_data)
    );

    uart_tx uart_tx_inst (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx_busy  (tx_busy),
        .TX       (TX)
    );

    uart_rx uart_rx_inst (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick),
        .RX       (RX),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_error (rx_error)
    );

endmodule
