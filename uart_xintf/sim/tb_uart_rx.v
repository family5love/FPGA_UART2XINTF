`timescale 1ns / 1ps

module tb_uart_rx();
    reg clk50M;
    reg rst_n;

    reg rs232_rx;

    wire [7:0] rx_data;
    wire end_flag;

    uart_rx uart_rx_inst(
        .clk50M                 (clk50M         ),
        .rst_n                  (rst_n          ),

        .rs232_rx               (rs232_rx       ),

        .rx_data                (rx_data        ),
        .end_flag               (end_flag       )

    );

    always #10 clk50M = ~clk50M;

    initial begin
        clk50M = 0;
        rst_n = 0;
        #100;
        rst_n = 1;

        rxd_1_Byte(8'h55);
    end

    task rxd_1_Byte(
        input [7:0] data
    );
    integer i;
    begin
        rs232_rx = 0;
        #8680;
        for(i = 0; i < 8; i = i + 1) begin
            rs232_rx = data[i];
            #8680;
        end
        rs232_rx = 1;
        #8680;
    end endtask
endmodule
