`timescale 1ns/1ps

module digital_timer_tb;

    reg clk = 0;
    reg reset;
    wire [6:0] seg;
    wire [3:0] anode;

    digital_timer_top #(
        .COUNT_MAX   (26'd9),
        .REFRESH_MAX (16'd4)
    ) uut (
        .clk   (clk),
        .reset (reset),
        .seg   (seg),
        .anode (anode)
    );

    always #10 clk = ~clk;

    initial begin
        reset = 1;
        #100;
        reset = 0;

        #30000;

        $display("Final state: minutes=%0d seconds=%0d", uut.minutes, uut.seconds);
        $finish;
    end

    always @(uut.tick) begin
        if (uut.tick)
            $display("time=%0t reset=%b tick=%b min=%0d sec=%0d seg=%b anode=%b",
                      $time, reset, uut.tick, uut.minutes, uut.seconds,
                      seg, anode);
    end

endmodule
