//`define SIM
`timescale 1ns / 1ps

module uart_tx(
	//系统信号
	input 				clk50M,
	input 				rst_n,
	//串口发送接口
	output reg 			rs232_tx,
	//串口发送触发信号
	input 				tx_trig,
	input 		[7:0] 	tx_data,
	//串口发送接口空闲状态标志
	output    			tx_idle
);

`ifndef SIM
//localparam BAUD_END = 20833 - 1;		//clk200M bps 9600
//localparam BAUD_END = 5208 - 1;		//clk50M bps 9600
//localparam BAUD_END = 434 - 1;		//clk50M bps 115200
localparam BAUD_END = 108 - 1;			//clk50M bps 460800
`else
localparam BAUD_END = 56;
`endif
localparam BAUD_M = BAUD_END/2 - 1;
localparam BIT_END = 9;

reg [ 7:0] 	tx_data_r;
reg 		tx_flag;
reg [15:0]	baud_cnt;
reg 		bit_flag;
reg [ 3:0]	bit_cnt;

//tx_idle
assign tx_idle = ~tx_flag;

//tx_data_r
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		tx_data_r <= 'd0;
	else if(tx_trig & (~tx_flag))
		tx_data_r <= tx_data;
end
//tx_flag
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		tx_flag <= 'b0;
	else if(tx_trig & (~tx_flag))
		tx_flag <= 'b1;
	else if(bit_cnt == BIT_END && bit_flag == 'b1)
		tx_flag <= 'b0;
end
//baud_cnt
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		baud_cnt <= 'd0;
	else if(baud_cnt == BAUD_END)
		baud_cnt <= 'd0;
	else if(tx_flag)
		baud_cnt <= baud_cnt + 'd1;
	else
		baud_cnt <= 'd0;
end
//bit_flag
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		bit_flag <= 'b0;
	else if(baud_cnt == BAUD_END)
		bit_flag <= 'b1;
	else
		bit_flag <= 'b0;
end
//bit_cnt
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		bit_cnt <= 'd0;
	else if(bit_flag & (bit_cnt == BIT_END))
		bit_cnt <= 'd0;
	else if(bit_flag)
		bit_cnt <= bit_cnt + 'd1;
end
//rs232_tx
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		rs232_tx <= 1'b1;
	else if(tx_flag)
		case(bit_cnt)
			'd0: 		rs232_tx <= 1'b0;
			'd1: 		rs232_tx <= tx_data_r[0];
			'd2: 		rs232_tx <= tx_data_r[1];
			'd3: 		rs232_tx <= tx_data_r[2];
			'd4: 		rs232_tx <= tx_data_r[3];
			'd5: 		rs232_tx <= tx_data_r[4];
			'd6: 		rs232_tx <= tx_data_r[5];
			'd7: 		rs232_tx <= tx_data_r[6];
			'd8: 		rs232_tx <= tx_data_r[7];
			'd9:		rs232_tx <= 1'b1;
			default:	rs232_tx <= 1'b1;
		endcase
	else
		rs232_tx <= 1'b1;
end

endmodule
