`timescale 1ns/1ps

module tb_uart_tx();
    reg clk50M;
    reg rst_n;

    wire rs232_tx;

    reg tx_trig;
    reg [7:0] tx_data;

    wire tx_idle;

    uart_tx uart_tx_inst(
        .clk50M         (clk50M),
        .rst_n          (rst_n),

        .rs232_tx       (rs232_tx),

        .tx_trig        (tx_trig),
        .tx_data        (tx_data),

        .tx_idle        (tx_idle)
    );

    always #10 clk50M = ~clk50M;

    initial begin
        rst_n = 0;
        clk50M = 0;
        tx_trig = 0;
        tx_data = 8'hzz;
        
        //
        #100;
        rst_n = 1;
        
        tx_data = 8'h55;
        tx_trig = 0;
        #20;

        tx_trig = 1;
        #20;
        tx_trig = 0;
        #20;

        #40000;
        tx_trig = 1;
        #20;
        tx_trig = 0;
        #20; 

        #80000;
        tx_trig = 1;
        #20;
        tx_trig = 0;
        #20;

    end





endmodule

