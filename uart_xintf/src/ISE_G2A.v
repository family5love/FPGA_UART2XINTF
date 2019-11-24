`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:48:01 05/17/2019 
// Design Name: 
// Module Name:    ISE_G2A 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ISE_G2A(
	//System signal
	input clk,//ʱ�ӣ�T8
	input rst_n,//��λ��A9

	//1_��߸�����ST(spot tracker)��ָ������,T15
	input in_spot_tracker,
	//2_��߸�����ST(spot tracker)��ָ�����,T14
	output reg out_spot_tracker,
	
	//3_5308������laser_5308��1570������䣨������������ָ�����,T5
	output reg out_laser_5308,
	//4_5308������laser_5308��1570����ز��źţ�����������/1064������䷴���źţ���߸��٣�������,T4
	input in_laser_5308,
	
	//5_���⼤����laser_xg��810������䣨������������ָ�����,T6
	output reg out_laser_xg,
	
	//6_�����ɫ�����佹����CTV�����������ع⣬ָ�����,T7
	output reg out_CTV_xg,
	
	//7_����·С�ӳ�����COP_TV�����������ع�/ɨ����ͬ����ָ�����,R9
	output reg out_COP_TV,

	//8_����·ǰ�Ӻ���COP_FLIR��ɨ����ͬ����ָ�����,T9
	output reg out_COP_FLIR,
	
	//9_����·�̲�����COP_SWIR�����������ع�/ɨ����ͬ��/��߸�����ͬ����ָ�����,R7
	output reg out_COP_SWIR,
	
	//10_����·���ٷ��侵FSM(fast steering mirror)������ָ���źţ�ɨ����ͬ������ɨ��������ָ�����,R5
	output reg out_COP_FSM,
	
	//ɨ����ͬ������I/O����4��
	input in_scan_COP_TV,//ɨ����ͬ������I/O��С�ӳ�����COP_TV			R2
	input in_scan_COP_FLIR,//ɨ����ͬ������I/O��ǰ�Ӻ���FLIR			R1	
	input in_scan_COP_SWIR,//ɨ����ͬ������I/O���̲�����SWIR			P2
	input in_scan_COP_FSM,//ɨ����ͬ������I/O�����ٷ��侵FSM			P1
	
	//���ڣ���������ͨ��
	input rxd,//���գ�T13			
	output reg txd,//���ͣ�T12
	
	//DSP��������XINTF
	input cs_n,//ƬѡCZCS0				M1
	input re_n,//��ʹ��XRD				K2
	input we_n,//дʹ��XWE0				L1
	inout [15:0] xdata,//��������0-15:	K1 J3 J1 H2 H1 G3 G1 F2 F1 K3 E2 E1 C3 C2 D1 C1	
	//����XINTF�Զ����ź�
	output reg c_xrd_req,//�������źţ�FIFO��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч					N3
	input c_xcs_n,//�Զ���XINTFʹ�ܣ��͵�ƽFPGA��XINTF�ӿ��������߱�ѡ��						N1
	
	//LED
	output reg led1,				//A13
	output reg led2,				//A14

	//��DSP��������IO��4��:				M2 A2 B2 A3
	input nc1,			// M2
	input nc2,			// A2
	output nc3,			// B2
	output nc4,			// A3
	
	//FPGA״̬���Թܽ�(������)
	output nop1,		//A4
	output nop2,		//A5
	output nop3,		//A6
	output nop4			//A7
);


//ʵ���������໷IP
wire clk50M;
wire clk200M;
clk_pll clk_pll_inst(
	// Clock in ports
	.CLK_IN1(clk),      		// IN  50M
	// Clock out ports
	.CLK_OUT1(clk50M),     	// OUT 50M
	.CLK_OUT2(clk200M),     	// OUT 200M
	// Status and control signals
	.RESET(~rst_n),				// IN
	.LOCKED(LOCKED)
);

//���δ����������IO�ڵ������Ƿ���ȷ
//out_spot_tracker
//out_laser_5308
//out_laser_xg
//out_CTV_xg
//out_COP_TV
//out_COP_FLIR
//out_COP_SWIR
//out_COP_FSM
//in_spot_tracker
//in_laser_5308
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n) begin
		out_spot_tracker <= 1'b0;
		out_laser_5308 <= 1'b0;
		out_laser_xg <= 1'b0;
		out_CTV_xg <= 1'b0;
		out_COP_TV <= 1'b0;
		out_COP_FLIR <= 1'b0;
		out_COP_SWIR <= 1'b0;
		out_COP_FSM <= 1'b0;
	end
	else if(in_spot_tracker) begin
		out_spot_tracker <= 1'b0;
		out_laser_5308 <= 1'b0;
		out_laser_xg <= 1'b0;
		out_CTV_xg <= 1'b0;
	end
	else if(in_laser_5308) begin
		out_COP_TV <= 1'b0;
		out_COP_FLIR <= 1'b0;
		out_COP_SWIR <= 1'b0;
		out_COP_FSM <= 1'b0;
	end

end

//in_scan_COP_TV
//in_scan_COP_FLIR
//in_scan_COP_SWIR
//in_scan_COP_FSM
//rxd
wire [4:0] a;
assign a = {in_scan_COP_TV, in_scan_COP_FLIR, in_scan_COP_SWIR, in_scan_COP_FSM, rxd};
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n)
		txd <= 0;
	else 
		case(a)
			5'b00000: txd <= 1;
			5'b00011: txd <= 0;
			5'b10100: txd <= 0;
			5'b01001: txd <= 0;
			5'b10000: txd <= 1;
		endcase
end

//cs_n
//re_n
//we_n
//cs_fpga_n
//xdata
//fifo_state
reg [15:0] d_xdata;
always @(posedge clk50M or negedge rst_n) begin
	if(~rst_n) begin
		d_xdata <= 16'hzzzz;
		fifo_state <= 1'b0;
	end
	else if(~cs_n & ~cs_fpga_n & re_n)
		fifo_state <= 1'b1;
	else if(~cs_n & ~cs_fpga_n & we_n) begin
		fifo_state <= 1'b0;
		d_xdata <= 16'h5f5f;
	end
	else begin
		fifo_state <= 1'b0;
		d_xdata <= 16'hzzzz;
	end
end
assign xdata = d_xdata;


//led1
//led2
always @(posedge clk200M or negedge rst_n) begin
	if(~rst_n) begin
        led1 <= 0;
		led2 <= 0;
	end
	else begin
		led1 <= ~led1;
		led2 <= ~led2;
	end
end

//nc1		
//nc2		
//nc3		
//nc4
assign nc3 = nc1;
assign nc4 = nc2;

//nop1
//nop2
//nop3
//nop4
assign nop1 = nc1? 1:0;
assign nop2 = nc1? 1:0;
assign nop3 = nc1? 1:0;
assign nop4 = nc1? 1:0;

endmodule
