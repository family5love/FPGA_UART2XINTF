`timescale 1ns / 1ps
//本模块集成XINTF基本时序模块、2个FIFO存储模块，实现多个字节的XINTF收发
//1.数据由FIFO接口信号写入FIFO1，由XINTF接口读出；
//2.数据由XINTF接口写入FIFO2，由FIFO接口信号读出。
//
//   FIFO接口信号  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
//2019.10.26

module xintf_top(
    //系统信号
    input clk50M,
    input rst_n,

    //XINTF对外接口信号，XINTF官方
	input xrd,						//读信号
	input xwe,						//写信号
	inout [15:0] xdata,				//XINTF 数据总线
    //XINTF对外接口信号，自定义
    input c_xcs_n,                  //自定义XINTF使能，低电平有效，官方CS0/CS6/CS7不使用
    output c_xrd_req,               //读请求信号：FIFO1单帧数据存满时请求XINTF读取，高电平有效

    //FIFO1接口信号
	input f1_wr_en,				    //写使能，高电平有效，连接内部FIFO1
	input [7:0] f1_buf_in,			//写数据，连接内部FIFO1
	//FIFO2接口信号
	input f2_rd_en,				    //读使能，高电平有效，连接内部FIFO2
	output [7:0] f2_buf_out,		//读数据，连接内部FIFO2
	output [7:0] fifo2_cnt			//FIFO2已使用字节数
);

//局部参数
localparam U2X_FBYTE_NUM = 22;			//串口 -> XINTF 帧字节长度(UART to XINTF Frame Byte Num)
//公共变量
wire [15:0] xrd_data;
wire [15:0] xwr_data;
wire [7:0] f1_buf_out;
wire [7:0] f2_buf_in;
wire [7:0] fifo1_cnt;

//实例化：XINTF
//       
//   FIFO接口信号  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
xintf xintf_inst(
    .rst_n                  (rst_n              ),
	.clk50M                 (clk50M             ),
	//XINTF 外部接口信号
	.xcs_n                  (c_xcs_n 		    ),				//使能，低电平有效
	.xrd                    (xrd                ),				//读信号
	.xwe                    (xwe                ),				//写信号
	.xdata                  (xdata              ),				//XINTF 数据总线
	//XINTF 内部接口信号
	.xrd_data               (xrd_data			),				//位宽16bit
	.rd_fall                (rd_fall			),				//
	.rd_end                 (					),				// 
	.xwr_data               (xwr_data			),				//位宽16bit
	.wr_end                 (wr_end				)				//
);

assign xrd_data = {8'h00, f1_buf_out}; 							//将f1_buf_out 由8bit位宽扩展为16bit位宽，高8位置0

//实例化：FIFO1(FIFO接口信号 -> FIFO1 -> XINTF)，FIFO接口信号写入，XINTF读出
fifo fifo1_inst(
	.clk50M					(clk50M				),
	.rst_n					(rst_n				),
	//FIFO信号
	.wr_en					(f1_wr_en			),				//连接FIFO接口信号，FIFO接口信号写入
	.buf_in					(f1_buf_in			),				//连接FIFO接口信号，FIFO1，FIFO接口信号写入
	.rd_en					(rd_fall			),				//连接xintf_inst.rd_fall，XINTF读出
	.buf_out				(f1_buf_out			),				//连接xintf_inst.xrd_data，需扩展位宽，XINTF读出
	//FIFO状态输出
	.buf_empty				(					),				//FIFO空
	.buf_full				(					),			    //FIFO满，请求XINTF开始读取数据
	.fifo_cnt				(fifo1_cnt			)				//FIFO已使用字节数
);

assign f2_buf_in = xwr_data[7:0];								//将f1_buf_out 由8bit位宽扩展为16bit位宽，高8位置0

//实例化：FIFO2(XINTF -> FIFO2 -> FIFO接口信号)，XINTF写入，FIFO接口信号读出
fifo fifo2_inst(
	.clk50M					(clk50M				),
	.rst_n					(rst_n				),
	//FIFO信号
	.wr_en					(wr_end				),				//连接xintf_inst.wr_end
	.buf_in					(f2_buf_in			),				//连接xintf_inst.xwr_data，取低8bit
	.rd_en					(f2_rd_en			),				//连接FIFO接口信号，FIFO1
	.buf_out				(f2_buf_out			),				//连接FIFO接口信号，FIFO1
	//FIFO状态输出
	.buf_empty				(					),				//FIFO空
	.buf_full				(					),				//FIFO满
	.fifo_cnt				(fifo2_cnt			)				//FIFO已使用字节数
);

assign c_xrd_req = (fifo1_cnt >= U2X_FBYTE_NUM) ? 'b1 : 'b0;		//FIFO1存储一帧字节后请求XINTF读取

endmodule