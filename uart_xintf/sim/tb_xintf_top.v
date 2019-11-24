`timescale 1ns / 1ps
//xintf_top测试模块
//xintf_top模块集成XINTF基本时序模块、2个FIFO存储模块，实现多个字节的XINTF收发
//1.数据由FIFO接口信号写入FIFO1，由XINTF接口读出；
//2.数据由XINTF接口写入FIFO2，由FIFO接口信号读出。
//
//   FIFO接口信号  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
//2019.10.26
module tb_xintf_top();
    reg clk50M;
    reg rst_n;
    //XINTF对外接口信号，XINTF官方
    reg xcs_n;
    reg xrd;
    reg xwe;
    wire [15:0] xdata;
    //XINTF对外接口信号，自定义
    reg c_xcs_n;
    wire c_xrd_req;
    //FIFO接口信号
    reg f1_wr_en;
    reg [7:0] f1_buf_in;
    wire f1_buf_empty;
    reg f2_rd_en;
    wire [7:0] f2_buf_out;
    wire f2_buf_full;

    //////////////////////////////////////////////////////
    //其他信号：仅仿真内部使用
    reg flag_xwr;           //XINTF写入操作标志
    reg [15:0] xdata_r;     //xdata写入使用

    //实例化xintf_top
    xintf_top xintf_top_inst(
        .clk50M                     (clk50M         ),
        .rst_n                      (rst_n          ),

        //XINTF对外接口信号，XINTF官方
        .xcs_n                      (xcs_n          ),				//XINTF使能，低电平有效
        .xrd                        (xrd            ),				//读信号
        .xwe                        (xwe            ),				//写信号
        .xdata                      (xdata          ),				//XINTF 数据总线
        //XINTF对外接口信号，自定义
        .c_xcs_n                    (c_xcs_n        ),              //自定义XINTF使能，低电平有效
        .c_xrd_req                  (c_xrd_req      ),              //读请求信号：FIFO单帧数据存满时请求XINTF读取，高电平有效

        //FIFO接口信号
        .f1_wr_en                   (f1_wr_en       ),				//写使能，高电平有效，连接内部FIFO1
        .f1_buf_in                  (f1_buf_in      ),			    //写数据，连接内部FIFO1
        .f1_buf_empty               (f1_buf_empty   ),
        .f2_rd_en                   (f2_rd_en       ),				//读使能，高电平有效，连接内部FIFO2
        .f2_buf_out                 (f2_buf_out     ),		        //读数据，连接内部FIFO2
        .f2_buf_full                (f2_buf_full    )
    );

    //时钟clk50M
    always #10 clk50M = ~clk50M;

    //初始化
    initial begin
        clk50M = 0;
        rst_n = 0;

        xcs_n = 1;
        xrd = 1;
        xwe = 1;
        c_xcs_n = 1;
        
        f1_wr_en = 0;
        f1_buf_in = 8'h00;
        f2_rd_en = 0;

        #100;
        rst_n = 1;
        #10;

        //测试：数据由FIFO接口信号写入FIFO1，由XINTF接口读出
        /*
        intf_write_to_fifo1(16, 8'ha0);

        c_xcs_n = 0;//DSP片选 XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 1;//DSP片选关闭 XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 0;//DSP片选 XINTF
        xintf_rd_from_fifo1(1);
    
        c_xcs_n = 1;//DSP片选关闭 XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 0;//DSP片选 XINTF
        xintf_rd_from_fifo1(14);

        xintf_rd_from_fifo1(5);

        intf_write_to_fifo1(16, 8'hb0);
        xintf_rd_from_fifo1(20);
        intf_write_to_fifo1(3, 8'hb0);
        xintf_rd_from_fifo1(5);
        */

        //测试：数据由XINTF接口写入FIFO2，由FIFO接口信号读出
        c_xcs_n = 0;//DSP片选 XINTF
        xintf_wr_to_fifo2(8, 16'h00a0);
        c_xcs_n = 1;//DSP片选 XINTF
        xintf_wr_to_fifo2(8, 16'h00a8);
        c_xcs_n = 0;//DSP片选 XINTF
        xintf_wr_to_fifo2(8, 16'h00a8);

        #100;
        c_xcs_n = 0;//DSP片选 XINTF
        intf_read_from_fifo2(8);
        c_xcs_n = 1;//DSP片选 XINTF
        intf_read_from_fifo2(8);
    end

    //xdata: XINTF写操作时xdata_r输出至xdata，其他时候xdata置为高阻
    assign xdata = flag_xwr ? xdata_r : 16'hzzzz;


    //FIFO接口信号 写入 FIFO1
    task intf_write_to_fifo1(
        input [7:0] num, 
        input [7:0] data
    );
    integer i;
    begin
        f1_buf_in = data;
        for(i = 0; i < num ; i = i + 1) begin
            #20;
            f1_wr_en = 1;
            #20;
            f1_wr_en = 0;
            f1_buf_in = f1_buf_in + 1;
        end
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

    //FIFO接口信号 读出 FIFO2
    task intf_read_from_fifo2(
        input [7:0] num
    );
    integer i;
    begin
        for(i = 0; i < num; i = i + 1) begin
            f2_rd_en = 1;
            #20;
            f2_rd_en = 0;
            #20;
        end
    end endtask

endmodule 