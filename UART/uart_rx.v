module receiver #(parameter integer clock = 50000000, baudrate = 115200) // Synced default clock with transmitter
(
    input clk,
    input rst,
    input rx,
    input parity_en,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);

localparam integer t_bit = clock/baudrate;
localparam integer half_bit = t_bit/2;

reg [2:0] state, next;
reg [15:0] baudcount; // Increased to 16 bits
reg [2:0] bitcount;
reg [7:0] shift_reg;
reg parity;
reg parity_err_flag; // New register to securely latch parity error

parameter rx_idle = 3'd0, rx_start_check = 3'd5, rx__data = 3'd2, rx_parity = 3'd3, rx_stop = 3'd4;

always@(posedge clk or posedge rst) begin
    if(rst)
        state <= rx_idle;
    else 
        state <= next;
end

always@(posedge clk or posedge rst) begin
    if(rst) begin
        baudcount <= 0;
        bitcount <= 0;
    end
    else if(state == rx_idle) begin
        baudcount <= 0;
        bitcount <= 0;
    end
    else if(state == rx_start_check) begin
        if(baudcount == half_bit-1) begin
            baudcount <= 0;
        end
        else
            baudcount <= baudcount + 1;
    end
    else begin
        if(baudcount == t_bit-1) begin
            baudcount <= 0;
            if(state == rx__data) begin
                if(bitcount < 3'd7)
                    bitcount <= bitcount + 1;
            end
        end
        else begin
            baudcount <= baudcount + 1;
        end
    end
end

always@(posedge clk or posedge rst) begin
    if(rst)
        parity <= 0;
    else if(state == rx__data && baudcount == t_bit-1 && bitcount == 3'd7) begin
        if(parity_en) begin
            // Hardcoded to EVEN parity, and correctly excluding the garbage bit
            parity <= ^{rx, shift_reg[7:1]};
        end
        else
            parity <= 0;
    end
end

always@(posedge clk or posedge rst) begin
    if(rst) begin
        shift_reg <= 0;
    end
    else if(state == rx__data && baudcount == t_bit-1) begin
        shift_reg <= {rx, shift_reg[7:1]};
    end
end

// Latch to capture the parity error safely
always@(posedge clk or posedge rst) begin
    if (rst)
        parity_err_flag <= 1'b0;
    else if (state == rx_parity && baudcount == t_bit-1)
        parity_err_flag <= (rx != parity);
end

always@(*) begin
    next = state;
    case(state)
        rx_idle : begin
            if(rx == 0)
                next = rx_start_check;
            else	
                next = rx_idle;
        end
        
        rx_start_check : begin
            if(baudcount == half_bit-1) begin
                if(rx == 0)
                    next = rx__data;
                else 
                    next = rx_idle;
            end
            else
                next = rx_start_check;
        end
        
        rx__data : begin
            if(baudcount == t_bit-1) begin
                if (bitcount == 3'd7) begin
                    if(parity_en)
                        next = rx_parity;
                    else
                        next = rx_stop;
                end
                else begin
                    next = rx__data;
                end
            end
            else begin
                next = rx__data;
            end
        end

        rx_parity : begin
            if(baudcount == t_bit-1) begin
                next = rx_stop;
            end
            else
                next = rx_parity;
        end
        
        rx_stop: begin
            if (baudcount == t_bit-1) begin
                if (rx == 1'b1) 
                    next = rx_idle;
                else 
                    next = rx_stop;
            end
            else
                next = rx_stop;
        end
        
        default : begin 
            next = rx_idle;
        end
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_data  <= 8'd0;
        rx_valid <= 1'b0;
        rx_error <= 1'b0;
    end
    else begin
        if (state == rx_stop && baudcount == t_bit-1) begin
            if (rx == 1'b1) begin
                rx_data  <= shift_reg;
                rx_valid <= 1'b1;
                // Safely assign the latched flag if parity is enabled
                rx_error <= parity_en ? parity_err_flag : 1'b0; 
            end
            else begin
                rx_error <= 1'b1; // Framing error
                rx_valid <= 1'b0;
            end
        end
        else begin
            rx_valid <= 1'b0; // This guarantees valid only pulses for a single clock cycle!
        end
    end
end
endmodule 
