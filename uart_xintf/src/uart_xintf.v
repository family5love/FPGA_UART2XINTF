//===================================================================================
// uart_xintf 
// ●模块实现uart和XINTF接口之间的数据传递，基本功能描述如下：
//  1. uart_rx输入，XINTF输出：
//      1）uart_rx接收串口信号，并写入FIFO1；
//      2）FIFO1存储的数据量达到1帧时，c_xrd_req置1，请求DSP通过XINTF接口读取数据；
//  2. XINTF输入，uart_tx输出：
//      DSP通过XINTF写入数据至FIFO2，当写入数据量达到1帧时，触发uart_tx进行串口发送。
// ● 功能描述示意图：
//                     xintf_top
//                ____________________
//   uart_rx  ->  | FIFO1 -> | XINTF |  
//   uart_tx  <-  | FIFO2 <- |       |      
//                ————————————————————
//
//                                                              ------2019.10.29
//===================================================================================

`timescale 1ns / 1ps

module uart_xintf(
    //系统信号
    input               clk50M              ,
    input               rst_n               ,
    //UART接口
    input               uart_rxd            ,           //串口接收端
    output              uart_txd            ,           //串口发送端
    //XINTF对外接口信号，XINTF官方
	input               xrd                 ,			//读信号
	input               xwe                 ,			//写信号
	inout       [15:0]  xdata               ,			//XINTF 数据总线
    //XINTF对外接口信号，自定义
    input               c_xcs_n             ,           //自定义XINTF使能，低电平有效
    output              c_xrd_req           ,           //读请求信号：FIFO1单帧数据存满时请求XINTF读取，高电平有效
    //串口接收命令输出
    output      [ 7:0]  cmd_mode            ,           //工作模式
    output      [15:0]  cmd_laser_dist      ,           //激光测距值(m)
    output      [31:0]  cmd_phase_diff      ,           //相位偏差(5ns)
    output      [31:0]  cmd_exp_time        ,           //探测器曝光时长
    output      [15:0]  cmd_laser_width     ,           //激光脉宽
    output              cmd_flag_out                    //输出命令有效标志，高电平有效      

);

//局部参数
localparam X2U_FBYTE_NUM = 6;       //帧字节长度(XINTF to UART Frame Byte Num)
localparam RD_EN_DELAY = 4;         //f2_rd_en两次读取间隔延迟(仿真图像观察获得，尽量不要修改)

//公共变量
reg f2_rd_en;                       //读使能，高电平有效，连接内部FIFO2
wire [7:0] f2_buf_out;              //读数据，连接内部FIFO2
reg tx_trig;                        //串口发送触发信号
wire tx_idle;                       //串口发送接口空闲状态标志
wire [7:0] f1_buf_in;               //写数据，连接内部FIFO1
wire [7:0] fifo2_cnt;               //FIFO2已使用字节数，达到一帧数据启动读数据


//FIFO2与uart_tx连接的中间变量
reg flag_f2_rd;                     //FIFO2帧数据读取标识
reg [5:0] f2_rd_cnt;                //FIFO2帧数据读取计数器
reg [2:0] f2_rd_en_delay;           //读使能延时计数器（保证f2_rd_en一次仅读取一个字节数据）
reg flag_f2_rd_en;                  //f2_rd_en信号间隔标志


//===================================================================================
//实例化 xintf_top
//===================================================================================
xintf_top xintf_top_inst(
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //XINTF对外接口信号，XINTF官方
	.xrd                    (xrd            ),					//读信号
	.xwe                    (xwe            ),				    //写信号
	.xdata                  (xdata          ),				    //XINTF 数据总线
    //XINTF对外接口信号，自定义
    .c_xcs_n                (c_xcs_n        ),                  //自定义XINTF使能，低电平有效
    .c_xrd_req              (c_xrd_req      ),                  //读请求信号：FIFO单帧数据存满时请求XINTF读取，高电平有效
    //FIFO1接口信号
	.f1_wr_en               (f1_wr_en       ),				    //写使能，高电平有效，连接内部FIFO1
	.f1_buf_in              (f1_buf_in      ),			        //[7:0]写数据，连接内部FIFO1
    //FIFO2接口信号
	.f2_rd_en               (f2_rd_en       ),				    //[7:0]读使能，高电平有效，连接内部FIFO2
	.f2_buf_out             (f2_buf_out     ),		            //读数据，连接内部FIFO2   
    .fifo2_cnt              (fifo2_cnt      )                   //FIFO2状态，FIFO2已使用字节数，达到一帧数据启动读数据
);


//===================================================================================
//uart_tx 与 xintf_top 连接
//===================================================================================
//实例化：uart_tx
uart_tx uart_tx_inst(
    	//系统信号
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
	//串口发送接口
	.rs232_tx               (uart_txd       ),
	//串口发送触发信号
    .tx_trig                (tx_trig        ),
	.tx_data                (f2_buf_out     ),
	//串口发送接口空闲状态标志
	.tx_idle                (tx_idle        )
);

//flag_f2_rd
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        flag_f2_rd <= 'b0;
    else if(fifo2_cnt == X2U_FBYTE_NUM)
        flag_f2_rd <= 'b1;
    else if(f2_rd_cnt == X2U_FBYTE_NUM)
        flag_f2_rd <= 'b0;
end

//f2_rd_cnt
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        f2_rd_cnt <= 'd0;
    else if(tx_trig == 'b1)
        f2_rd_cnt <= f2_rd_cnt + 'd1;
    else if(f2_rd_cnt == X2U_FBYTE_NUM)
        f2_rd_cnt <= 'd0;
end

//f2_rd_en,将FIFO2数据读出
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        f2_rd_en <= 'b0;
    else if(flag_f2_rd && tx_idle && ~flag_f2_rd_en && ~f2_rd_en)
        f2_rd_en <= 'b1;
    else
        f2_rd_en <= 'b0;
end

//f2_rd_en_delay, f2_rd_en信号两次间隔时间计数器
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        f2_rd_en_delay <= 'd0;
    else if(flag_f2_rd_en)
        f2_rd_en_delay <= f2_rd_en_delay + 'd1;
    else
        f2_rd_en_delay <= 'd0;
end

//flag_f2_rd_en
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        flag_f2_rd_en <= 'b0;
    else if(f2_rd_en == 'b1)
        flag_f2_rd_en <= 'b1;
    else if(f2_rd_en_delay == RD_EN_DELAY)
        flag_f2_rd_en <= 'b0;
end

//tx_trig,将读出的FIFO2数据写入uart_tx_inst
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        tx_trig <= 'b0;
    else
        tx_trig <= f2_rd_en;
end

//===================================================================================
//uart_rx 与 xintf_top 连接
//===================================================================================
//实例化：uart_rx
uart_rx uart_rx_inst(
    //系统信号
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //串口接收管脚
    .rs232_rx               (uart_rxd       ),
    //数据输出
    .rx_data                (f1_buf_in      ),      //串口接收数据[7:0]
    .flag_end               (f1_wr_en       )       //单字节接收完成标志
);


//===================================================================================
//uart_rx_cmd:串口命令解析，uart_rx数据输入，输出的解析结果直接送至uart_xintf输出接口
//===================================================================================
//实例化:uart_rx_cmd,串口命令解析
uart_rx_cmd  uart_rx_cmd_inst(
    //系统信号
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //数据输入  
    .rx_data                (f1_buf_in      ),           //数据输入
    .flag_in                (f1_wr_en       ),           //输入数据有效标志，高电平有效
    //命令输出  
    .mode                   (cmd_mode       ),           //工作模式
    .laser_dist             (cmd_laser_dist ),           //激光测距值(m)
    .phase_diff             (cmd_phase_diff ),           //相位偏差(5ns)
    .exp_time               (cmd_exp_time   ),           //探测器曝光时长
    .laser_width            (cmd_laser_width),           //激光脉宽
    .flag_out               (cmd_flag_out   )            //输出命令有效标志，高电平有效
);

endmodule 
