`timescale 1ns / 1ps
//xintf_top����ģ��
//xintf_topģ�鼯��XINTF����ʱ��ģ�顢2��FIFO�洢ģ�飬ʵ�ֶ���ֽڵ�XINTF�շ�
//1.������FIFO�ӿ��ź�д��FIFO1����XINTF�ӿڶ�����
//2.������XINTF�ӿ�д��FIFO2����FIFO�ӿ��źŶ�����
//
//   FIFO�ӿ��ź�  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
//2019.10.26
module tb_xintf_top();
    reg clk50M;
    reg rst_n;
    //XINTF����ӿ��źţ�XINTF�ٷ�
    reg xcs_n;
    reg xrd;
    reg xwe;
    wire [15:0] xdata;
    //XINTF����ӿ��źţ��Զ���
    reg c_xcs_n;
    wire c_xrd_req;
    //FIFO�ӿ��ź�
    reg f1_wr_en;
    reg [7:0] f1_buf_in;
    wire f1_buf_empty;
    reg f2_rd_en;
    wire [7:0] f2_buf_out;
    wire f2_buf_full;

    //////////////////////////////////////////////////////
    //�����źţ��������ڲ�ʹ��
    reg flag_xwr;           //XINTFд�������־
    reg [15:0] xdata_r;     //xdataд��ʹ��

    //ʵ����xintf_top
    xintf_top xintf_top_inst(
        .clk50M                     (clk50M         ),
        .rst_n                      (rst_n          ),

        //XINTF����ӿ��źţ�XINTF�ٷ�
        .xcs_n                      (xcs_n          ),				//XINTFʹ�ܣ��͵�ƽ��Ч
        .xrd                        (xrd            ),				//���ź�
        .xwe                        (xwe            ),				//д�ź�
        .xdata                      (xdata          ),				//XINTF ��������
        //XINTF����ӿ��źţ��Զ���
        .c_xcs_n                    (c_xcs_n        ),              //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч
        .c_xrd_req                  (c_xrd_req      ),              //�������źţ�FIFO��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч

        //FIFO�ӿ��ź�
        .f1_wr_en                   (f1_wr_en       ),				//дʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO1
        .f1_buf_in                  (f1_buf_in      ),			    //д���ݣ������ڲ�FIFO1
        .f1_buf_empty               (f1_buf_empty   ),
        .f2_rd_en                   (f2_rd_en       ),				//��ʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO2
        .f2_buf_out                 (f2_buf_out     ),		        //�����ݣ������ڲ�FIFO2
        .f2_buf_full                (f2_buf_full    )
    );

    //ʱ��clk50M
    always #10 clk50M = ~clk50M;

    //��ʼ��
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

        //���ԣ�������FIFO�ӿ��ź�д��FIFO1����XINTF�ӿڶ���
        /*
        intf_write_to_fifo1(16, 8'ha0);

        c_xcs_n = 0;//DSPƬѡ XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 1;//DSPƬѡ�ر� XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 0;//DSPƬѡ XINTF
        xintf_rd_from_fifo1(1);
    
        c_xcs_n = 1;//DSPƬѡ�ر� XINTF
        xintf_rd_from_fifo1(1);

        c_xcs_n = 0;//DSPƬѡ XINTF
        xintf_rd_from_fifo1(14);

        xintf_rd_from_fifo1(5);

        intf_write_to_fifo1(16, 8'hb0);
        xintf_rd_from_fifo1(20);
        intf_write_to_fifo1(3, 8'hb0);
        xintf_rd_from_fifo1(5);
        */

        //���ԣ�������XINTF�ӿ�д��FIFO2����FIFO�ӿ��źŶ���
        c_xcs_n = 0;//DSPƬѡ XINTF
        xintf_wr_to_fifo2(8, 16'h00a0);
        c_xcs_n = 1;//DSPƬѡ XINTF
        xintf_wr_to_fifo2(8, 16'h00a8);
        c_xcs_n = 0;//DSPƬѡ XINTF
        xintf_wr_to_fifo2(8, 16'h00a8);

        #100;
        c_xcs_n = 0;//DSPƬѡ XINTF
        intf_read_from_fifo2(8);
        c_xcs_n = 1;//DSPƬѡ XINTF
        intf_read_from_fifo2(8);
    end

    //xdata: XINTFд����ʱxdata_r�����xdata������ʱ��xdata��Ϊ����
    assign xdata = flag_xwr ? xdata_r : 16'hzzzz;


    //FIFO�ӿ��ź� д�� FIFO1
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

    //FIFO�ӿ��ź� ���� FIFO2
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