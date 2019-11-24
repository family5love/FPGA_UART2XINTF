`timescale 1ns / 1ps

module tb_xintf;
    reg rst_n;
    reg clk50M;
    //XINTF 外部接口信号
    reg xcs_n;                      //使能，低电平有效
    reg xrd;                        //读信号
    reg xwe;                        //写信号
    wire [15:0] xdata;              //XINTF 数据总线
    //XINTF 内部接口信号
    reg  [15:0] xrd_data;           //将要通过读操作从XINTF数据总线xdata输出给DSP的数据(xrd_data--->xdata)
    wire rd_end;                    //XINTF读操作完成标志
    wire rd_fall;					//XINTF读信号xrd下降沿标志，用来更新本次读操作xrd_data数据
    wire [15:0] xwr_data;           //XINTF写操作从DSP-XINTF接口获取的数据
    wire wr_end;                    //XINTF写操作完成标志 


    //仿真使用变量
    reg [15:0] xdata_w;             //仿真 写输入 XINTF数据总线 数据
    reg flag_wr;                    //状态标志，写数据时置1，其他状态置0
    //实例化：xintf
    xintf xintf_inst(
        .rst_n          (rst_n      ),
        .clk50M         (clk50M     ),
        //XINTF 外部接口信号
        .xcs_n          (xcs_n       ),
        .xrd            (xrd        ),
        .xwe            (xwe        ),
        .xdata          (xdata      ),
        //XINTF 内部接口信号
        .xrd_data       (xrd_data   ),
        .rd_end         (rd_end     ),
        .rd_fall        (rd_fall    ),
        .xwr_data       (xwr_data   ),
        .wr_end         (wr_end     )
    );
    //时钟
    always #10 clk50M = ~clk50M;
    //初始化
    initial begin
        rst_n = 0;
        clk50M = 0;
        xcs_n = 1;
        xrd = 1;
        xwe = 1;
        xrd_data = 16'haaa0;
        xdata_w = 16'hzzzz;
        flag_wr = 0;
        #100;
        rst_n = 1;

        //仿真开始：
        xcs_n = 0;//片选
        xintf_write_byte(16'h5555);
        xintf_read_byte();
    end

    //XINTF写出时xdata = xdata_w
    //其他状态xdata = 16'hzzzz（由xintf_inst实例控制xdata）
    assign xdata = (flag_wr == 1) ? xdata_w : 16'hzzzz;

    //XINTF写入一个字节数据，XINTF模块由外入内
    task xintf_write_byte(
        input [15:0] data
    );
    begin
        flag_wr = 1;        //读数据状态标志置1
        #80;
        xwe = 0;
        xdata_w = data;
        #200;
        xwe = 1;
        #80;
        xdata_w = 16'hzzzz;
        flag_wr = 0;        //读数据状态标志置0
    end endtask

    //XINTF读出一个字节数据，XINTF模块由内到外
    task xintf_read_byte();
    begin
        #80;
        xrd = 0;
        xrd_data = xrd_data + 1;
        #200;
        xrd = 1;
        #80;
    end endtask


endmodule

