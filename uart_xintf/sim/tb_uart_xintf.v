`timescale 1ns/1ps
module tb_uart_xintf();
    reg clk50M;
    reg rst_n;
    //UART接口
    reg uart_rxd;                   //串口接收端
    wire uart_txd;                  //串口发送端
    //XINTF对外接口信号，XINTF官方
    reg xcs_n;					    //XINTF使能，低电平有效
	reg xrd;						//读信号
	reg xwe;						//写信号
	wire [15:0] xdata;				//XINTF 数据总线
    //XINTF对外接口信号，自定义
    reg c_xcs_n;                    //自定义XINTF使能，低电平有效
    wire c_xrd_req;                 //读请求信号：FIFO单帧数据存满时请求XINTF读取，高电平有效

    //其他公共变量
    parameter U2X_FBYTE_NUM = 22;           //UART  ->  XINTF   帧字节数
    parameter X2U_FBYTE_NUM = 6;            //XINTF ->  UART    帧字节数
    parameter BPS_460800_T = 2170;          //bps 460800 对应延时周期
    reg flag_xwr;
    reg [15:0] xdata_r;
    //实例化
    uart_xintf uart_xintf_inst(
        //系统信号
        .clk50M                 (clk50M         ),
        .rst_n                  (rst_n          ),
        //UART接口
        .uart_rxd               (uart_rxd       ),                      //串口接收端
        .uart_txd               (uart_txd       ),                      //串口发送端
        //XINTF对外接口信号，XINTF官方
        .xcs_n                  (xcs_n          ),					    //XINTF使能，低电平有效
        .xrd                    (xrd            ),						//读信号
        .xwe                    (xwe            ),						//写信号
        .xdata                  (xdata          ),				        //XINTF 数据总线
        //XINTF对外接口信号，自定义
        .c_xcs_n                (c_xcs_n        ),                      //自定义XINTF使能，低电平有效
        .c_xrd_req              (c_xrd_req      )                       //读请求信号：FIFO单帧数据存满时请求XINTF读取，高电平有效
    );
    //时钟
    always #10 clk50M = ~clk50M;
    //初始化
    initial begin
        clk50M = 0;
        rst_n = 0;
        uart_rxd = 1;
        xcs_n = 1;
        xrd = 1;
        xwe = 1;
        c_xcs_n = 1;
        #100;
        rst_n = 1;

        c_xcs_n = 0;
        xcs_n = 0;

        c_xcs_n = 1;
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h50);       //XINTF写满一帧，触发串口发送----c_xcs_n = 1不起作用
        rxd_one_frame(8'h10, 16'hffff, 32'h1112_1314, 32'h1516_1718, 16'h1920);//rxd接收一帧通信协议定义数据UART  -> XINTF
        c_xcs_n = 0;
        #(U2X_FBYTE_NUM * 400);                         //等待FIFO1数据从XINTF接口读出(防止XINTF数据总线读写冲突)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h50);       //XINTF写满一帧，触发串口发送                       XINTF -> UART
        
        //重复
        rxd_one_frame(8'h20, 16'he0e0, 32'he4e3_e2e1, 32'he8e7_e6e5, 16'hf0e9);//rxd接收一帧通信协议定义数据UART  -> XINTF
        #(U2X_FBYTE_NUM * 400);                         //等待FIFO1数据从XINTF接口读出(防止XINTF数据总线读写冲突)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h58);       //XINTF写满一帧，触发串口发送                       XINTF -> UART

        //重复
        rxd_one_frame(8'h30, 16'hdd00, 32'ha1a2_a3a4, 32'ha5a6_a7a8, 16'ha9a0);//rxd接收一帧通信协议定义数据UART  -> XINTF
        #(U2X_FBYTE_NUM * 400);                         //等待FIFO1数据从XINTF接口读出(防止XINTF数据总线读写冲突)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h60);       //XINTF写满一帧，触发串口发送                       XINTF -> UART

        //重复
        #(BPS_460800_T * 10 *6);                        //串口发送延时
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h68);       //XINTF写满一帧，触发串口发送                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //串口发送延时
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h70);       //XINTF写满一帧，触发串口发送                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //串口发送延时
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h78);       //XINTF写满一帧，触发串口发送                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //串口发送延时
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h80);       //XINTF写满一帧，触发串口发送                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //串口发送延时
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h88);       //XINTF写满一帧，触发串口发送                       XINTF -> UART   

    end

    assign xdata = flag_xwr ? xdata_r : 16'hzzzz;

    //c_xrd_req == 1 时，启动XINTF读取一帧数据
    always @(posedge clk50M) begin
        if(c_xrd_req & ~c_xcs_n)
            xintf_rd_from_fifo1(U2X_FBYTE_NUM);
    end

    //===========================================================================
    //XINTF对外接口信号 写入 FIFO2
    task xintf_wr_to_fifo2(
        input [7:0] num,
        input [15:0] data
    );
    integer i;
    begin
        flag_xwr = 'b1;
        xdata_r = data;
        for(i = 0; i < num; i = i + 1) begin
            xcs_n = 0;//片选 XINTF总线片选
            #80;
            xwe = 0;
            #200;
            xwe = 1;
            #80;
            xdata_r = xdata_r + 'd1;
        end
        flag_xwr = 'b0;
    end endtask

    //rxd接收1Byte数据
    task rxd_1_Byte(
        input [7:0] data
    );
    integer i;
    begin
        uart_rxd = 0;
        #BPS_460800_T;
        for(i = 0; i < 8; i = i + 1) begin
            uart_rxd = data[i];
            #BPS_460800_T;
        end
        uart_rxd = 1;
        #BPS_460800_T;
    end endtask

    //rxd接收多Byte数据
    task rxd_n_Byte(
        input [7:0] num,
        input [7:0] data
    );
    integer n;
    begin
        for(n = 0; n < num; n = n + 1) begin
             rxd_1_Byte(data + n);
        end
    end endtask

    //rxd接收2字节数据，16bit输入
    task rxd_2_Byte(
        input [15:0] bi_data
    );
    reg [7:0] data;
    begin
        data = bi_data[ 7: 0];
        rxd_1_Byte(data);
        data = bi_data[15: 8];
        rxd_1_Byte(data);
    end endtask

    //rxd接收4字节数据，32bit输入
    task rxd_4_Byte(
        input [31:0] quat_data
    );
    reg [7:0] data;
    begin
        data = quat_data[ 7: 0];
        rxd_1_Byte(data);
        data = quat_data[15: 8];
        rxd_1_Byte(data);
        data = quat_data[23:16];
        rxd_1_Byte(data);
        data = quat_data[31:24];
        rxd_1_Byte(data);
    end endtask

    //rxd接收一帧通信协议定义数据
    //3~7字节依次为: 8'h33, 8'h44, 8'h55, 8'h66, 8'h77
    //21字节为: 8'h21
    task rxd_one_frame(
        input [ 7: 0]   tb_mode,        // 8'h10
        input [15: 0]   tb_dist,        //16'hffff
        input [31: 0]   tb_phase,       //32'h1112_1314
        input [31: 0]   tb_exp,         //32'h1516_1718
        input [15: 0]   tb_width        //16'h1920
    );
    reg [7:0] tb_checksum;
    reg [7:0] data;
    integer n;
    begin
        rxd_1_Byte(8'haa);                          //1，帧头
        rxd_1_Byte(8'h02);                          //2，ID
        rxd_1_Byte(8'h33);                          //3
        rxd_1_Byte(8'h44);                          //4
        rxd_1_Byte(8'h55);                          //5
        rxd_1_Byte(8'h66);                          //6
        rxd_1_Byte(8'h77);                          //7
        rxd_1_Byte(tb_mode);                        //8
        rxd_2_Byte(tb_dist);                        //9-10
        rxd_4_Byte(tb_phase);                       //11-14
        rxd_4_Byte(tb_exp);                         //15-18
        rxd_2_Byte(tb_width);                       //19-20
        rxd_1_Byte(8'h21);                          //21

        tb_checksum = 8'hff ^ 8'h02 ^ 8'h33 ^ 8'h44 ^ 8'h55 ^ 8'h66 ^ 8'h77 ^ tb_mode ^ tb_dist[7:0] ^ tb_dist[15:8];               
        tb_checksum = tb_checksum ^ tb_phase[7:0] ^ tb_phase[15:8] ^ tb_phase[23:16] ^ tb_phase[31:24];
        tb_checksum = tb_checksum ^ tb_exp[7:0] ^ tb_exp[15:8] ^ tb_exp[23:16] ^ tb_exp[31:24];
        tb_checksum = tb_checksum ^ tb_width[7:0] ^ tb_width[15:8] ^ 8'h21;
        
        rxd_1_Byte(tb_checksum);                    //22,校验和
    end endtask
    //XINTF对外接口信号 读出，实际从FIFO1读出
    task xintf_rd_from_fifo1(
        input [7:0] num
    ); 
    integer i;
    begin
        for(i = 0; i < num; i = i + 1) begin
            xcs_n = 0;//片选 XINTF总线片选
            #80;
            xrd = 0;
            #200;
            xrd = 1;
        end
    end endtask

endmodule

