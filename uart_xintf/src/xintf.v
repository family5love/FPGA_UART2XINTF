`timescale 1ns / 1ps

module xintf(
	//System signal
	input rst_n,
	input clk50M,
	//XINTF �ⲿ�ӿ��ź�
	input xcs_n,					//ʹ�ܣ��͵�ƽ��Ч
	input xrd,						//���ź�
	input xwe,						//д�ź�
	inout [15:0] xdata,				//XINTF ��������
	//XINTF �ڲ��ӿ��ź�
	input [15:0] xrd_data,			//��Ҫͨ����������XINTF��������xdata�����DSP������(xrd_data--->xdata)
	output reg rd_fall,				//XINTF���ź�xrd�½��ر�־����������FIFO����ı��ζ�����xrd_data����
	output rd_end,					//XINTF��������ɱ�־ 
	output reg [15:0] xwr_data,		//XINTFд������DSP-XINTF�ӿڻ�ȡ������
	output reg wr_end				//XINTFд������ɱ�־ 
);

	//��������
	localparam READ_CNT_END = 14-3; 	//������ʱ��: Active + Trail = 280ns�������ڲ�ʱ�ӽ����ӳ٣����ʵ�����
	localparam WRITE_CNT_END = 14-3; 	//д����ʱ��: Active + Trail = 280ns�������ڲ�ʱ�ӽ����ӳ٣����ʵ�����

	//��������
	//XINTF������
	reg rd_flag; 					//������flag��������־��xrd_data�����xdata��־
	reg [4:0] rd_cnt; 				//������������
	//XINTFд����
	reg wr_flag; 					//д����flag
	reg [4:0] wr_cnt; 				//д����������
	reg [15:0] xdata_t;				//xdata�����

	//===================================�����===================================
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

	//================================ XINTF ������ ================================
	//rd_fall
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			rd_fall <= 0;
		else if(p_xcs_n) 			//δƬѡ
			rd_fall <= 0;
		else if(~xrd_t & xrd_tt)	//rxd�½���
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
		else if(p_xcs_n)			//δƬѡ
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
		else if(p_xcs_n | (rd_flag == 'b0))		//δƬѡ �� rd_flag==0
			rd_cnt <= 'd0;
		else if(rd_flag == 'b1)
			rd_cnt <= rd_cnt + 'd1;
	end
	//xdata
	assign xdata = rd_flag ? xrd_data : 16'hzzzz; //rd_flag == 1: Read mode;

	//================================ XINTF д���� ================================
	//wr_flag
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_flag <= 'b0;
		else if(p_xcs_n) 			//δƬѡ
			wr_flag <= 'b0;
		else if(~xwe_t & xwe_tt)	//xwe�½���
			wr_flag <= 'b1;
		else if(wr_cnt == READ_CNT_END)
			wr_flag <= 'b0;
	end
	//[4:0] wr_cnt
	always @(posedge clk50M or negedge rst_n) begin
		if(~rst_n)
			wr_cnt <= 'd0;
		else if(p_xcs_n)			//δƬѡ
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
		else if(p_xcs_n)			//δƬѡ
			xwr_data <= 16'hzzzz;
		else if(xwe_t & ~xwe_tt)	//xwe������
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
