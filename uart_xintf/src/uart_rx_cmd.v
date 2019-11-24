//===================================================================================
// uart_rx_cmd 
// ●模块对uart_rx模块串口接收的数据进行命令解析，输出解析结果
//
//                                                              ------2019.11.11
//===================================================================================

`timescale 1ns / 1ps

module uart_rx_cmd(
    //系统信号
    input                   clk50M              ,
    input                   rst_n               ,
    //数据输入
    input           [ 7:0]  rx_data             ,           //数据输入
    input                   flag_in             ,           //输入数据有效标志，高电平有效
    //命令输出
    output  reg     [ 7:0]  mode                ,           //工作模式
    output  reg     [15:0]  distance            ,           //距离值(m)
    output  reg     [31:0]  phase_diff          ,           //相位偏差(5ns)
    output  reg     [31:0]  expose_time         ,           //曝光时长
    output  reg     [15:0]  laser_width         ,           //激光脉宽
    output  reg             flag_out                        //输出命令有效标志，高电平有效
);

//局部参数
localparam  U2X_FBYTE_NUM   =   22;			      //串口 -> XINTF 帧字节长度(UART to XINTF Frame Byte Num)
//状态机参数
localparam  IDLE            =   0;                //空闲态
localparam  HEAD            =   1;                //帧头 8'haa
localparam  ID              =   2;                //ID  8'h02
localparam  MODE            =   3;                //工作模式
localparam  DIST            =   4;                //激光测距值
localparam  PHASE           =   5;                //相位偏差
localparam  EXP             =   6;                //曝光时长
localparam  WIDTH           =   7;                //激光脉宽
localparam  FREE            =   8;                //备用字节
localparam  CKECK           =   9;                //校验和
//工作模式参数
localparam  M_ACT           =   8'h10;            //主动式脉冲激光照明(active)
localparam  M_PAS           =   8'h20;            //被动式脉冲激光照明(passive)
localparam  M_CONT          =   8'h30;            //连续激光照明(continue)
localparam  M_SPOT_1        =   8'h40;            //光斑跟踪模式1(spot)
localparam  M_SPOT_2        =   8'h50;            //光斑跟踪模式2(spot)
localparam  M_SPOT_3        =   8'h60;            //光斑跟踪模式3(spot)
localparam  M_SCAN          =   8'h70;            //扫描外同步(scan)
localparam  M_STORE         =   8'h80;            //参数存储(store)
localparam  M_NONE          =   8'h00;            //不相关，无操作(none)
//公共变量
reg     [4:0]   rx_cnt;                 //接收数据计数器
reg     [3:0]   state;                  //状态值
reg     [2:0]   s_cnt;                  //状态机内字节计数器
reg     [7:0]   checksum;               //校验和,第2~21字节与0xFF的异或结果


//rx_cnt,接收数据计数器
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        rx_cnt = 'd0;
    else if(flag_in)
        rx_cnt = rx_cnt + 'd1;
    else if(rx_cnt == U2X_FBYTE_NUM)
        rx_cnt = 'd0;
end
//checksum,第2~21字节与0xFF的异或
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        checksum = 8'hff;
    else if(flag_in && (rx_cnt > 1) && (rx_cnt < 22))
        checksum = checksum ^ rx_data;
    else if(rx_cnt == 0)
        checksum = 8'hff;
end
//状态机:mode,distance,phase_diff,expose_time,laser_width,flag_out
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n) begin
        state               =   IDLE    ;           //空闲
        mode                =   M_NONE  ;           //工作模式,M_NONE,不相关
        distance            =   16'd0   ;           //激光测距值(m)
        phase_diff          =   32'd0   ;           //相位偏差(5ns)
        expose_time         =   32'd0   ;           //探测器曝光时长
        laser_width         =   16'd0   ;           //激光脉宽
        flag_out            =   'b0     ;           //输出命令有效标志，高电平有效
        s_cnt               =   'd0     ;           //字节计数器
    end
    else begin
        case(state)
            IDLE: begin                             //空闲,flag_out
                flag_out <= 'b0;
                if(flag_in && rx_data == 8'haa)
                    state <= HEAD;
            end
            HEAD: begin                             //[1]帧头
                if(flag_in && rx_data == 8'h02)
                    state <= ID;
                else if(flag_in && rx_data != 8'h02)  
                    state <= IDLE;
            end
            ID: begin                               //[2]ID
                if(rx_cnt == 'd7)
                    state <= MODE;
            end
            MODE: begin                             //[8]工作模式,mode
                if(flag_in) begin
                    mode = rx_data;
                    state <= DIST;
                end
            end
            DIST: begin                             //[9,10]激光测距值(m),distance
                if(flag_in)
                    s_cnt <= s_cnt + 'd1;
                if(flag_in && s_cnt == 'd0)
                    distance[ 7:0] <= rx_data;
                else if(flag_in && s_cnt == 'd1) begin
                    distance[15:8] <= rx_data;
                    s_cnt <= 'd0;
                    state <= PHASE;
                end
            end    
            PHASE: begin                            //[11:14]相位偏差,phase_diff
                if(flag_in) begin
                    s_cnt <= s_cnt + 'd1;
                    if(s_cnt == 'd0)
                        phase_diff[ 7:0] <= rx_data;
                    else if(s_cnt == 'd1)
                        phase_diff[15:8] <= rx_data;
                    else if(s_cnt == 'd2)
                        phase_diff[23:16] <= rx_data;
                    else if(s_cnt == 'd3) begin
                        phase_diff[31:24] <= rx_data;
                        s_cnt <= 'd0;
                        state <= EXP;
                    end
                end
            end
            EXP: begin                              //[15:18]曝光时长,expose_time
                if(flag_in) begin
                    s_cnt <= s_cnt + 'd1;
                    if(s_cnt == 'd0)
                        expose_time[ 7: 0] <= rx_data;
                    else if(s_cnt == 'd1)
                        expose_time[15: 8] <= rx_data;
                    else if(s_cnt == 'd2)
                        expose_time[23:16] <= rx_data;
                    else if(s_cnt == 'd3) begin
                        expose_time[31:24] <= rx_data;
                        s_cnt <= 'd0;
                        state <= WIDTH;
                    end
                end
            end
            WIDTH: begin                            //[19:20]激光脉宽,laser_width
                if(flag_in) begin
                    s_cnt <= s_cnt + 'd1;
                    if(s_cnt == 'd0)
                        laser_width[ 7: 0] <= rx_data;
                    else begin
                        laser_width[15: 8] <= rx_data;
                        s_cnt <= 'd0;
                        state <= FREE;
                    end
                end
            end
            FREE: begin                             //[21]备用字节
                 if(flag_in) 
                    state <= CKECK;
            end
            CKECK: begin                            //[22]校验和比较,flag_out
                if(flag_in) begin
                    state <= IDLE;
                    if(checksum == rx_data)
                        flag_out <= 'b1;
                end
            end
        endcase
    end
end

endmodule