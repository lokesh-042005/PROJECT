`timescale 1ns/1ps

module tb_uart_top;

    reg  clk;
    reg  rst;
    wire TX;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_error;

    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE  = 115200;
    localparam DIVISOR   = CLK_FREQ / (BAUD_RATE * 16);
    localparam CLK_PERIOD_NS = 20;
    localparam MSG_LEN   = 18;

    localparam CLKS_PER_FRAME = 10 * 16 * DIVISOR;
    localparam NS_PER_FRAME   = CLKS_PER_FRAME * CLK_PERIOD_NS;
    localparam SIM_TIMEOUT_NS = (MSG_LEN * NS_PER_FRAME) + 5000;

    reg [7:0] expected [0:MSG_LEN-1];
    integer   rx_index;
    integer   pass_count = 0;
    integer   fail_count = 0;

    uart_top dut (
        .clk      (clk),
        .rst      (rst),
        .TX       (TX),
        .RX       (TX),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_error (rx_error)
    );

    always #(CLK_PERIOD_NS/2) clk = ~clk;

    // ---- Waveform dump setup ----
    initial begin
        $dumpfile("tb_uart_top.vcd");
        $dumpvars(0, tb_uart_top);   // dump all signals in this module and below (DUT included)
    end

    initial begin
        expected[0]  = "S"; expected[1]  = "I"; expected[2]  = "L";
        expected[3]  = "I"; expected[4]  = "C"; expected[5]  = "O";
        expected[6]  = "N"; expected[7]  = " "; expected[8]  = "C";
        expected[9]  = "R"; expected[10] = "A"; expected[11] = "F";
        expected[12] = "T"; expected[13] = " "; expected[14] = "V";
        expected[15] = "L"; expected[16] = "S"; expected[17] = "I";
    end

    initial begin
        clk      = 0;
        rst      = 1;
        rx_index = 0;
        #50 rst = 0;
        $display("Computed SIM_TIMEOUT_NS = %0d ns (DIVISOR=%0d, %0d clocks/frame)",
                   SIM_TIMEOUT_NS, DIVISOR, CLKS_PER_FRAME);
    end

    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_index < MSG_LEN) begin
                if (rx_data !== expected[rx_index]) begin
                    $display("FAIL: char %0d expected '%c' (0x%0h), got '%c' (0x%0h)",
                              rx_index, expected[rx_index], expected[rx_index],
                              rx_data, rx_data);
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: char %0d = '%c' received correctly", rx_index, rx_data);
                    pass_count = pass_count + 1;
                end
                rx_index = rx_index + 1;
            end else begin
                $display("FAIL: received more characters than expected (index %0d)", rx_index);
                fail_count = fail_count + 1;
                rx_index = rx_index + 1;
            end
        end

        if (rx_error) begin
            $display("FAIL: rx_error asserted unexpectedly at char %0d", rx_index);
            fail_count = fail_count + 1;
        end
    end

    initial begin
        #(50 + SIM_TIMEOUT_NS);
        if (rx_index !== MSG_LEN) begin
            $display("FAIL: only received %0d of %0d expected characters", rx_index, MSG_LEN);
            fail_count = fail_count + 1;
        end
        $display("---------------------------------------------");
        $display("TESTS PASSED: %0d   TESTS FAILED: %0d", pass_count, fail_count);
        $display("---------------------------------------------");
        $finish;
    end

endmodule
