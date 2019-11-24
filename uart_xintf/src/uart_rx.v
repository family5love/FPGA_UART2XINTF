//`define SIM
`timescale 1ns / 1ps
module uart_rx(
	//system signal 
	input clk50M,
	input rst_n,
	//uart_interface
	input rs232_rx,
	//others
	output reg [ 7: 0]  rx_data,        //串口接收数据输出
	output reg          flag_end        //输出数据有效标志，高电平有效
);
//===============================================================parameter
`ifndef SIM
//localparam BAUD_END = 20833 - 1;		//clk200M bps 9600
//localparam BAUD_END = 5208 - 1;		//clk50M bps 9600
//localparam BAUD_END = 434 - 1;		//clk50M bps 115200
localparam BAUD_END = 108 - 1;			//clk50M bps 460800
`else
localparam BAUD_END = 56;
`endif
localparam BAUD_M   = BAUD_END/2 - 1;
localparam BIT_END  = 8;
reg         rx_r1;
reg         rx_r2;
reg         rx_r3;
reg         rx_flag;
reg [15:0]  baud_cnt;
reg         bit_flag;
reg [ 3:0]  bit_cnt;

wire        rx_neg;
//===============================================================rx_neg

assign rx_neg =(~rx_r2) & rx_r3;
always @(posedge clk50M) begin
    rx_r1 <= rs232_rx;
    rx_r2 <= rx_r1;
    rx_r3 <= rx_r2;
end
//===============================================================rx_flag
always @(posedge clk50M or negedge rst_n) begin
    if(~ rst_n)
        rx_flag <= 1'b0;
    else if(rx_neg)
        rx_flag <= 1'b1;
    else if(bit_cnt == 'd0 && baud_cnt == BAUD_END)
        rx_flag <= 1'b0;
    else
        rx_flag <= rx_flag;
end
//================================================================baud_cnt
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        baud_cnt <= 'd0;
    else if(baud_cnt == BAUD_END)
        baud_cnt <= 'd0;
    else if(rx_flag)
        baud_cnt <= baud_cnt + 'd1;
    else 
        baud_cnt <= 'd0;
end
//================================================================bit_flag
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        bit_flag <= 1'b0;
    else if(baud_cnt == BAUD_M)
        bit_flag <= 1'b1;
    else 
        bit_flag <= 1'b0;
end
//================================================================bit_cnt
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        bit_cnt <= 'd0;
    else if(bit_flag == 1 && bit_cnt == BIT_END)
        bit_cnt <= 'd0;
    else if(bit_flag == 1)
        bit_cnt <= bit_cnt + 'd1;
    else 
        bit_cnt <= bit_cnt;
end
//================================================================rx_data
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        rx_data <= 'd0;
    else if(bit_flag == 1'b1 && bit_cnt >= 1)
        rx_data <= {rx_r2, rx_data[7:1]};
    else
        rx_data <= rx_data;
end
//================================================================flag_end
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        flag_end <= 1'b0;
    else if(bit_cnt == BIT_END && bit_flag == 1'b1)
        flag_end <= 1'b1;
    else 
        flag_end <= 1'b0;
end
endmodule
