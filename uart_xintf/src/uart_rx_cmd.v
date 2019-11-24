//===================================================================================
// uart_rx_cmd 
// ��ģ���uart_rxģ�鴮�ڽ��յ����ݽ����������������������
//
//                                                              ------2019.11.11
//===================================================================================

`timescale 1ns / 1ps

module uart_rx_cmd(
    //ϵͳ�ź�
    input                   clk50M              ,
    input                   rst_n               ,
    //��������
    input           [ 7:0]  rx_data             ,           //��������
    input                   flag_in             ,           //����������Ч��־���ߵ�ƽ��Ч
    //�������
    output  reg     [ 7:0]  mode                ,           //����ģʽ
    output  reg     [15:0]  distance            ,           //����ֵ(m)
    output  reg     [31:0]  phase_diff          ,           //��λƫ��(5ns)
    output  reg     [31:0]  expose_time         ,           //�ع�ʱ��
    output  reg     [15:0]  laser_width         ,           //��������
    output  reg             flag_out                        //���������Ч��־���ߵ�ƽ��Ч
);

//�ֲ�����
localparam  U2X_FBYTE_NUM   =   22;			      //���� -> XINTF ֡�ֽڳ���(UART to XINTF Frame Byte Num)
//״̬������
localparam  IDLE            =   0;                //����̬
localparam  HEAD            =   1;                //֡ͷ 8'haa
localparam  ID              =   2;                //ID  8'h02
localparam  MODE            =   3;                //����ģʽ
localparam  DIST            =   4;                //������ֵ
localparam  PHASE           =   5;                //��λƫ��
localparam  EXP             =   6;                //�ع�ʱ��
localparam  WIDTH           =   7;                //��������
localparam  FREE            =   8;                //�����ֽ�
localparam  CKECK           =   9;                //У���
//����ģʽ����
localparam  M_ACT           =   8'h10;            //����ʽ���弤������(active)
localparam  M_PAS           =   8'h20;            //����ʽ���弤������(passive)
localparam  M_CONT          =   8'h30;            //������������(continue)
localparam  M_SPOT_1        =   8'h40;            //��߸���ģʽ1(spot)
localparam  M_SPOT_2        =   8'h50;            //��߸���ģʽ2(spot)
localparam  M_SPOT_3        =   8'h60;            //��߸���ģʽ3(spot)
localparam  M_SCAN          =   8'h70;            //ɨ����ͬ��(scan)
localparam  M_STORE         =   8'h80;            //�����洢(store)
localparam  M_NONE          =   8'h00;            //����أ��޲���(none)
//��������
reg     [4:0]   rx_cnt;                 //�������ݼ�����
reg     [3:0]   state;                  //״ֵ̬
reg     [2:0]   s_cnt;                  //״̬�����ֽڼ�����
reg     [7:0]   checksum;               //У���,��2~21�ֽ���0xFF�������


//rx_cnt,�������ݼ�����
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        rx_cnt = 'd0;
    else if(flag_in)
        rx_cnt = rx_cnt + 'd1;
    else if(rx_cnt == U2X_FBYTE_NUM)
        rx_cnt = 'd0;
end
//checksum,��2~21�ֽ���0xFF�����
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        checksum = 8'hff;
    else if(flag_in && (rx_cnt > 1) && (rx_cnt < 22))
        checksum = checksum ^ rx_data;
    else if(rx_cnt == 0)
        checksum = 8'hff;
end
//״̬��:mode,distance,phase_diff,expose_time,laser_width,flag_out
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n) begin
        state               =   IDLE    ;           //����
        mode                =   M_NONE  ;           //����ģʽ,M_NONE,�����
        distance            =   16'd0   ;           //������ֵ(m)
        phase_diff          =   32'd0   ;           //��λƫ��(5ns)
        expose_time         =   32'd0   ;           //̽�����ع�ʱ��
        laser_width         =   16'd0   ;           //��������
        flag_out            =   'b0     ;           //���������Ч��־���ߵ�ƽ��Ч
        s_cnt               =   'd0     ;           //�ֽڼ�����
    end
    else begin
        case(state)
            IDLE: begin                             //����,flag_out
                flag_out <= 'b0;
                if(flag_in && rx_data == 8'haa)
                    state <= HEAD;
            end
            HEAD: begin                             //[1]֡ͷ
                if(flag_in && rx_data == 8'h02)
                    state <= ID;
                else if(flag_in && rx_data != 8'h02)  
                    state <= IDLE;
            end
            ID: begin                               //[2]ID
                if(rx_cnt == 'd7)
                    state <= MODE;
            end
            MODE: begin                             //[8]����ģʽ,mode
                if(flag_in) begin
                    mode = rx_data;
                    state <= DIST;
                end
            end
            DIST: begin                             //[9,10]������ֵ(m),distance
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
            PHASE: begin                            //[11:14]��λƫ��,phase_diff
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
            EXP: begin                              //[15:18]�ع�ʱ��,expose_time
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
            WIDTH: begin                            //[19:20]��������,laser_width
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
            FREE: begin                             //[21]�����ֽ�
                 if(flag_in) 
                    state <= CKECK;
            end
            CKECK: begin                            //[22]У��ͱȽ�,flag_out
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