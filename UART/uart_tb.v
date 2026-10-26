`timescale 1ns/1ps

module uart_tb;

    // Simulation parameters
    parameter integer CLOCK = 1000000;
    parameter integer BAUDRATE = 10000;

    // Clock and reset
    reg clk;
    reg rst;

    // UART transmitter inputs
    reg [7:0] tx_data;
    reg tx_start;
    reg parity_en;

    // UART receiver input
    wire uart_rx;

    // UART outputs
    wire uart_tx;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_error;

    integer test_count;
    integer error_count;
    integer timeout;

    // Loopback connection:
    // Transmitter output is connected to receiver input.
    assign uart_rx = uart_tx;

    // DUT: UART transmitter + receiver
    uart #(
        .clock(CLOCK),
        .baudrate(BAUDRATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .parity_en(parity_en),
        .tx_busy(tx_busy),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // Clock generation: 1 MHz = 1 us period
    initial begin
        clk = 1'b0;
        forever #500 clk = ~clk;
    end

    // Test task: transmit a byte and verify reception
    task send_byte;
        input [7:0] data;
        input parity_mode;

        begin
            // Wait until transmitter becomes idle
            wait (tx_busy == 1'b0);

            @(negedge clk);
            tx_data = data;
            parity_en = parity_mode;
            tx_start = 1'b1;

            // Start pulse for one clock cycle
            @(negedge clk);
            tx_start = 1'b0;

            // Wait for receiver to capture the complete frame
            timeout = 0;

            while ((rx_valid !== 1'b1) && (timeout < 2000)) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            #1;

            test_count = test_count + 1;

            if (timeout >= 2000) begin
                $display(
                    "FAIL: Timeout for TX data = 0x%02h",
                    data
                );
                error_count = error_count + 1;
            end
            else if (rx_data !== data) begin
                $display(
                    "FAIL: TX = 0x%02h, RX = 0x%02h",
                    data, rx_data
                );
                error_count = error_count + 1;
            end
            else if (rx_error !== 1'b0) begin
                $display(
                    "FAIL: Unexpected RX error for data = 0x%02h",
                    data
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "PASS: TX = 0x%02h, RX = 0x%02h, Parity = %0b",
                    data, rx_data, parity_mode
                );
            end

            // Allow the receiver and transmitter to return to idle
            @(negedge clk);
        end
    endtask

    // Main test sequence
    initial begin

        // Initialize signals
        rst = 1'b1;
        tx_data = 8'h00;
        tx_start = 1'b0;
        parity_en = 1'b0;

        test_count = 0;
        error_count = 0;
        timeout = 0;

        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);

        $display("------------------------------------------");
        $display("       UART LOOPBACK TESTBENCH");
        $display("------------------------------------------");

        // Apply reset
        repeat (5) @(negedge clk);
        rst = 1'b0;

        repeat (5) @(negedge clk);

        // Test 1: Parity disabled
        $display("\n--- PARITY DISABLED ---");

        send_byte(8'hA5, 1'b0);
        send_byte(8'h3C, 1'b0);
        send_byte(8'h00, 1'b0);
        send_byte(8'hFF, 1'b0);
        send_byte(8'h55, 1'b0);

        // Test 2: Even parity enabled
        $display("\n--- EVEN PARITY ENABLED ---");

        send_byte(8'hA5, 1'b1);
        send_byte(8'h3C, 1'b1);
        send_byte(8'h00, 1'b1);
        send_byte(8'hFF, 1'b1);
        send_byte(8'h55, 1'b1);

        // Final summary
        $display("\n------------------------------------------");
        $display("             TEST SUMMARY");
        $display("------------------------------------------");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", test_count - error_count);
        $display("Failed      : %0d", error_count);

        if (error_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");

        $display("------------------------------------------");

        #1000;
        $finish;
    end

endmodule
