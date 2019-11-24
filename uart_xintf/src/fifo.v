`timescale 1ns / 1ps

module fifo(
	//系统信号
	input clk50M,
	input rst_n,
	//FIFO信号
	input wr_en,				//写使能，高电平有效
	input [7:0] buf_in,			//写数据
	input rd_en,				//读使能，高电平有效
	output reg [7:0] buf_out,	//读数据
	//FIFO状态输出
	output buf_empty,			//FIFO空
	output buf_full,			//FIFO满
	output reg [7:0] fifo_cnt	//FIFO已使用字节数
);
	//参数设置（修改FIFO容量时以下两个参数必须同时修改）
	localparam BUF_NUM = 32;	//设定FIFO容量：BUF_NUM, 默认16 Bytes
	localparam P_BIT_N = 5;		//读写指针位宽：必须与BUF_NUM完全匹配，2^P_BIT_N == BUF_NUM

	//公共变量
	reg [P_BIT_N - 1 : 0] rd_prt; 			//读指针，位宽必须与BUF_NUM完全匹配
	reg [P_BIT_N - 1 : 0] wr_prt; 			//写指针，位宽必须与BUF_NUM完全匹配
	reg [7:0] buf_mem [0 : BUF_NUM - 1]; 	//8位宽，BUF_NUM容量 
	
	//buf_empty
	assign buf_empty = (fifo_cnt == 'd0) ? 'b1 : 'b0;	
	//buf_full
	assign buf_full = (fifo_cnt == BUF_NUM) ? 'b1 : 'b0;
	
	//fifo_cnt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			fifo_cnt <= 'd0;
		else if(wr_en & rd_en) //Simultaneously read and write
			fifo_cnt <= fifo_cnt;
		else if(wr_en & ~buf_full) // Write
			fifo_cnt <= fifo_cnt + 'd1;
		else if(rd_en & ~buf_empty)	// Read
			fifo_cnt <= fifo_cnt - 'd1;
		else
			fifo_cnt <= fifo_cnt;
	end	
	
	//buf_out, Read data operation
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			buf_out <= 'h00;
		else if(rd_en & ~buf_empty)
			buf_out <= buf_mem[rd_prt];
	end
	
	//buf_mem, Write data operation
	always @(posedge clk50M) begin
		if(wr_en & ~buf_full)
			buf_mem[wr_prt] <= buf_in;
	end
	
	//rd_prt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			rd_prt <= 0;
		else if(rd_en & ~buf_empty)
			rd_prt <= rd_prt + 1;
	end
	
	//wr_prt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_prt <= 0;
		else if(wr_en & ~buf_full)
			wr_prt <= wr_prt + 1;
	end
endmodule
