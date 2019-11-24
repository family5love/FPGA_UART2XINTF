`timescale 1ns / 1ps

module xintf(
	//System signal
	input rst_n,
	input clk50M,
	//XINTF 外部接口信号
	input xcs_n,					//使能，低电平有效
	input xrd,						//读信号
	input xwe,						//写信号
	inout [15:0] xdata,				//XINTF 数据总线
	//XINTF 内部接口信号
	input [15:0] xrd_data,			//将要通过读操作从XINTF数据总线xdata输出给DSP的数据(xrd_data--->xdata)
	output reg rd_fall,				//XINTF读信号xrd下降沿标志，用来更新FIFO输入的本次读操作xrd_data数据
	output rd_end,					//XINTF读操作完成标志 
	output reg [15:0] xwr_data,		//XINTF写操作从DSP-XINTF接口获取的数据
	output reg wr_end				//XINTF写操作完成标志 
);

	//参数设置
	localparam READ_CNT_END = 14-3; 	//读操作时间: Active + Trail = 280ns，由于内部时钟节拍延迟，做适当减少
	localparam WRITE_CNT_END = 14-3; 	//写操作时间: Active + Trail = 280ns，由于内部时钟节拍延迟，做适当减少

	//公共变量
	//XINTF读操作
	reg rd_flag; 					//读操作flag，计数标志，xrd_data输出至xdata标志
	reg [4:0] rd_cnt; 				//读操作计数器
	//XINTF写操作
	reg wr_flag; 					//写操作flag
	reg [4:0] wr_cnt; 				//写操作计数器
	reg [15:0] xdata_t;				//xdata打节拍

	//===================================打节拍===================================
	//p_xcs_n
	reg p_xcs_n;
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			p_xcs_n <= 'b1;
		else 
			p_xcs_n <= xcs_n;
	end
	//xrd_t, xrd_tt
	reg xrd_t; //1 beat for 'xrd'
	reg xrd_tt; //2 beat for 'xrd'
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n) begin
			xrd_t <= 'b0;
			xrd_tt <= 'b0;
		end
		else begin
			xrd_t <= xrd;
			xrd_tt <= xrd_t;
		end
	end
	//xwe_t, xwe_tt
	reg xwe_t; //1 beat for 'xwe'
	reg xwe_tt; //2 beat for 'xwe'
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n) begin
			xwe_t <= 'b0;
			xwe_tt <= 'b0;
		end
		else begin
			xwe_t <= xwe;
			xwe_tt <= xwe_t;
		end
	end

	//================================ XINTF 读操作 ================================
	//rd_fall
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			rd_fall <= 0;
		else if(p_xcs_n) 			//未片选
			rd_fall <= 0;
		else if(~xrd_t & xrd_tt)	//rxd下降沿
			rd_fall <= 1;
		else 
			rd_fall <= 0;
	end
	//rd_end
	assign rd_end = (rd_cnt == READ_CNT_END) ? 1'b1 : 1'b0;
	//rd_flag
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			rd_flag <= 'b0;
		else if(p_xcs_n)			//未片选
			rd_flag <= 'b0;
		else if((~p_xcs_n) & rd_fall)
			rd_flag <= 'b1;
		else if(rd_cnt == READ_CNT_END)
			rd_flag <= 'b0;
	end
	//[4:0] rd_cnt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n) 
			rd_cnt <= 'd0;
		else if(p_xcs_n | (rd_flag == 'b0))		//未片选 或 rd_flag==0
			rd_cnt <= 'd0;
		else if(rd_flag == 'b1)
			rd_cnt <= rd_cnt + 'd1;
	end
	//xdata
	assign xdata = rd_flag ? xrd_data : 16'hzzzz; //rd_flag == 1: Read mode;

	//================================ XINTF 写操作 ================================
	//wr_flag
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_flag <= 'b0;
		else if(p_xcs_n) 			//未片选
			wr_flag <= 'b0;
		else if(~xwe_t & xwe_tt)	//xwe下降沿
			wr_flag <= 'b1;
		else if(wr_cnt == READ_CNT_END)
			wr_flag <= 'b0;
	end
	//[4:0] wr_cnt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_cnt <= 'd0;
		else if(p_xcs_n)			//未片选
			wr_cnt <= 'd0;
		else if(wr_flag == 'b0)
			wr_cnt <= 'd0;
		else if(wr_flag == 'b1)
			wr_cnt <= wr_cnt + 'd1;
	end
	//xdata_t 
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			xdata_t <= 16'hzzzz;
		else if(~p_xcs_n & wr_flag)
			xdata_t <= xdata;
	end
	//xwr_data
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			xwr_data <= 16'hzzzz;
		else if(p_xcs_n)			//未片选
			xwr_data <= 16'hzzzz;
		else if(xwe_t & ~xwe_tt)	//xwe上升沿
			xwr_data <= xdata_t;
	end
	//wr_end
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_end <= 0;
		else if(wr_cnt == READ_CNT_END) 
			wr_end <= 1;
		else
			wr_end <= 0;
	end

endmodule
