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
	input clk,//时钟，T8
	input rst_n,//复位，A9

	//1_光斑跟踪器ST(spot tracker)，指令输入,T15
	input in_spot_tracker,
	//2_光斑跟踪器ST(spot tracker)，指令输出,T14
	output reg out_spot_tracker,
	
	//3_5308激光器laser_5308，1570激光出射（激光照明），指令输出,T5
	output reg out_laser_5308,
	//4_5308激光器laser_5308，1570激光回波信号（激光照明）/1064激光出射反馈信号（光斑跟踪），输入,T4
	input in_laser_5308,
	
	//5_西光激光器laser_xg，810激光出射（激光照明），指令输出,T6
	output reg out_laser_xg,
	
	//6_西光彩色连续变焦电视CTV，激光照明曝光，指令输出,T7
	output reg out_CTV_xg,
	
	//7_共光路小视场电视COP_TV，激光照明曝光/扫描外同步，指令输出,R9
	output reg out_COP_TV,

	//8_共光路前视红外COP_FLIR，扫描外同步，指令输出,T9
	output reg out_COP_FLIR,
	
	//9_共光路短波红外COP_SWIR，激光照明曝光/扫描外同步/光斑跟踪外同步，指令输出,R7
	output reg out_COP_SWIR,
	
	//10_共光路快速反射镜FSM(fast steering mirror)，动作指令信号（扫描外同步），扫描启动，指令输出,R5
	output reg out_COP_FSM,
	
	//扫描外同步输入I/O，共4个
	input in_scan_COP_TV,//扫描外同步输入I/O，小视场电视COP_TV			R2
	input in_scan_COP_FLIR,//扫描外同步输入I/O，前视红外FLIR			R1	
	input in_scan_COP_SWIR,//扫描外同步输入I/O，短波红外SWIR			P2
	input in_scan_COP_FSM,//扫描外同步输入I/O，快速反射镜FSM			P1
	
	//串口，与计算机板通信
	input rxd,//接收，T13			
	output reg txd,//发送，T12
	
	//DSP并行总线XINTF
	input cs_n,//片选CZCS0				M1
	input re_n,//读使能XRD				K2
	input we_n,//写使能XWE0				L1
	inout [15:0] xdata,//数据总线0-15:	K1 J3 J1 H2 H1 G3 G1 F2 F1 K3 E2 E1 C3 C2 D1 C1	
	//其他XINTF自定义信号
	output reg c_xrd_req,//读请求信号：FIFO单帧数据存满时请求XINTF读取，高电平有效					N3
	input c_xcs_n,//自定义XINTF使能，低电平FPGA的XINTF接口数据总线被选中						N1
	
	//LED
	output reg led1,				//A13
	output reg led2,				//A14

	//与DSP相连备份IO共4个:				M2 A2 B2 A3
	input nc1,			// M2
	input nc2,			// A2
	output nc3,			// B2
	output nc4,			// A3
	
	//FPGA状态测试管脚(调试用)
	output nop1,		//A4
	output nop2,		//A5
	output nop3,		//A6
	output nop4			//A7
);


//实例化：锁相环IP
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

//本段代码仅仅测试IO口的配置是否正确
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
