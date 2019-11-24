`timescale 1ns/1ps
module tb_uart_xintf();
    reg clk50M;
    reg rst_n;
    //UART�ӿ�
    reg uart_rxd;                   //���ڽ��ն�
    wire uart_txd;                  //���ڷ��Ͷ�
    //XINTF����ӿ��źţ�XINTF�ٷ�
    reg xcs_n;					    //XINTFʹ�ܣ��͵�ƽ��Ч
	reg xrd;						//���ź�
	reg xwe;						//д�ź�
	wire [15:0] xdata;				//XINTF ��������
    //XINTF����ӿ��źţ��Զ���
    reg c_xcs_n;                    //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч
    wire c_xrd_req;                 //�������źţ�FIFO��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч

    //������������
    parameter U2X_FBYTE_NUM = 22;           //UART  ->  XINTF   ֡�ֽ���
    parameter X2U_FBYTE_NUM = 6;            //XINTF ->  UART    ֡�ֽ���
    parameter BPS_460800_T = 2170;          //bps 460800 ��Ӧ��ʱ����
    reg flag_xwr;
    reg [15:0] xdata_r;
    //ʵ����
    uart_xintf uart_xintf_inst(
        //ϵͳ�ź�
        .clk50M                 (clk50M         ),
        .rst_n                  (rst_n          ),
        //UART�ӿ�
        .uart_rxd               (uart_rxd       ),                      //���ڽ��ն�
        .uart_txd               (uart_txd       ),                      //���ڷ��Ͷ�
        //XINTF����ӿ��źţ�XINTF�ٷ�
        .xcs_n                  (xcs_n          ),					    //XINTFʹ�ܣ��͵�ƽ��Ч
        .xrd                    (xrd            ),						//���ź�
        .xwe                    (xwe            ),						//д�ź�
        .xdata                  (xdata          ),				        //XINTF ��������
        //XINTF����ӿ��źţ��Զ���
        .c_xcs_n                (c_xcs_n        ),                      //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч
        .c_xrd_req              (c_xrd_req      )                       //�������źţ�FIFO��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч
    );
    //ʱ��
    always #10 clk50M = ~clk50M;
    //��ʼ��
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
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h50);       //XINTFд��һ֡���������ڷ���----c_xcs_n = 1��������
        rxd_one_frame(8'h10, 16'hffff, 32'h1112_1314, 32'h1516_1718, 16'h1920);//rxd����һ֡ͨ��Э�鶨������UART  -> XINTF
        c_xcs_n = 0;
        #(U2X_FBYTE_NUM * 400);                         //�ȴ�FIFO1���ݴ�XINTF�ӿڶ���(��ֹXINTF�������߶�д��ͻ)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h50);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART
        
        //�ظ�
        rxd_one_frame(8'h20, 16'he0e0, 32'he4e3_e2e1, 32'he8e7_e6e5, 16'hf0e9);//rxd����һ֡ͨ��Э�鶨������UART  -> XINTF
        #(U2X_FBYTE_NUM * 400);                         //�ȴ�FIFO1���ݴ�XINTF�ӿڶ���(��ֹXINTF�������߶�д��ͻ)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h58);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART

        //�ظ�
        rxd_one_frame(8'h30, 16'hdd00, 32'ha1a2_a3a4, 32'ha5a6_a7a8, 16'ha9a0);//rxd����һ֡ͨ��Э�鶨������UART  -> XINTF
        #(U2X_FBYTE_NUM * 400);                         //�ȴ�FIFO1���ݴ�XINTF�ӿڶ���(��ֹXINTF�������߶�д��ͻ)
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h60);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART

        //�ظ�
        #(BPS_460800_T * 10 *6);                        //���ڷ�����ʱ
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h68);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //���ڷ�����ʱ
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h70);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //���ڷ�����ʱ
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h78);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //���ڷ�����ʱ
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h80);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART
        #(BPS_460800_T * 10 *6);                        //���ڷ�����ʱ
        xintf_wr_to_fifo2(X2U_FBYTE_NUM, 16'h88);       //XINTFд��һ֡���������ڷ���                       XINTF -> UART   

    end

    assign xdata = flag_xwr ? xdata_r : 16'hzzzz;

    //c_xrd_req == 1 ʱ������XINTF��ȡһ֡����
    always @(posedge clk50M) begin
        if(c_xrd_req & ~c_xcs_n)
            xintf_rd_from_fifo1(U2X_FBYTE_NUM);
    end

    //===========================================================================
    //XINTF����ӿ��ź� д�� FIFO2
    task xintf_wr_to_fifo2(
        input [7:0] num,
        input [15:0] data
    );
    integer i;
    begin
        flag_xwr = 'b1;
        xdata_r = data;
        for(i = 0; i < num; i = i + 1) begin
            xcs_n = 0;//Ƭѡ XINTF����Ƭѡ
            #80;
            xwe = 0;
            #200;
            xwe = 1;
            #80;
            xdata_r = xdata_r + 'd1;
        end
        flag_xwr = 'b0;
    end endtask

    //rxd����1Byte����
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

    //rxd���ն�Byte����
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

    //rxd����2�ֽ����ݣ�16bit����
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

    //rxd����4�ֽ����ݣ�32bit����
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

    //rxd����һ֡ͨ��Э�鶨������
    //3~7�ֽ�����Ϊ: 8'h33, 8'h44, 8'h55, 8'h66, 8'h77
    //21�ֽ�Ϊ: 8'h21
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
        rxd_1_Byte(8'haa);                          //1��֡ͷ
        rxd_1_Byte(8'h02);                          //2��ID
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
        
        rxd_1_Byte(tb_checksum);                    //22,У���
    end endtask
    //XINTF����ӿ��ź� ������ʵ�ʴ�FIFO1����
    task xintf_rd_from_fifo1(
        input [7:0] num
    ); 
    integer i;
    begin
        for(i = 0; i < num; i = i + 1) begin
            xcs_n = 0;//Ƭѡ XINTF����Ƭѡ
            #80;
            xrd = 0;
            #200;
            xrd = 1;
        end
    end endtask

endmodule

