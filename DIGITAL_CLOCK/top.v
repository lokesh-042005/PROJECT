module digital_timer_top #(
    parameter COUNT_MAX   = 26'd49_999_999,
    parameter REFRESH_MAX = 16'd49_999
)(
    input  wire clk,
    input  wire reset,
    output wire [6:0] seg,
    output wire [3:0] anode
);

    wire tick;
    wire [5:0] minutes, seconds;
    wire [3:0] current_digit;

    clock_divider #(.COUNT_MAX(COUNT_MAX)) u_clkdiv (
        .clk   (clk),
        .reset (reset),
        .tick  (tick)
    );

    mmss_counter u_counter (
        .clk     (clk),
        .reset   (reset),
        .tick    (tick),
        .seconds (seconds),
        .minutes (minutes)
    );

    display_mux #(.REFRESH_MAX(REFRESH_MAX)) u_mux (
        .clk        (clk),
        .reset      (reset),
        .minutes    (minutes),
        .seconds    (seconds),
        .digit_out  (current_digit),
        .anode      (anode)
    );

    seven_seg_decoder u_decoder (
        .digit (current_digit),
        .seg   (seg)
    );

endmodule
