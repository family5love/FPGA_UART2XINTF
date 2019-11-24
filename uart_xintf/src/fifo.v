`timescale 1ns / 1ps

module fifo(
	//ϵͳ�ź�
	input clk50M,
	input rst_n,
	//FIFO�ź�
	input wr_en,				//дʹ�ܣ��ߵ�ƽ��Ч
	input [7:0] buf_in,			//д����
	input rd_en,				//��ʹ�ܣ��ߵ�ƽ��Ч
	output reg [7:0] buf_out,	//������
	//FIFO״̬���
	output buf_empty,			//FIFO��
	output buf_full,			//FIFO��
	output reg [7:0] fifo_cnt	//FIFO��ʹ���ֽ���
);
	//�������ã��޸�FIFO����ʱ����������������ͬʱ�޸ģ�
	localparam BUF_NUM = 32;	//�趨FIFO������BUF_NUM, Ĭ��16 Bytes
	localparam P_BIT_N = 5;		//��дָ��λ��������BUF_NUM��ȫƥ�䣬2^P_BIT_N == BUF_NUM

	//��������
	reg [P_BIT_N - 1 : 0] rd_prt; 			//��ָ�룬λ�������BUF_NUM��ȫƥ��
	reg [P_BIT_N - 1 : 0] wr_prt; 			//дָ�룬λ�������BUF_NUM��ȫƥ��
	reg [7:0] buf_mem [0 : BUF_NUM - 1]; 	//8λ��BUF_NUM���� 
	
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
