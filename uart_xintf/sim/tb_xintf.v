`timescale 1ns / 1ps

module tb_xintf;
    reg rst_n;
    reg clk50M;
    //XINTF �ⲿ�ӿ��ź�
    reg xcs_n;                      //ʹ�ܣ��͵�ƽ��Ч
    reg xrd;                        //���ź�
    reg xwe;                        //д�ź�
    wire [15:0] xdata;              //XINTF ��������
    //XINTF �ڲ��ӿ��ź�
    reg  [15:0] xrd_data;           //��Ҫͨ����������XINTF��������xdata�����DSP������(xrd_data--->xdata)
    wire rd_end;                    //XINTF��������ɱ�־
    wire rd_fall;					//XINTF���ź�xrd�½��ر�־���������±��ζ�����xrd_data����
    wire [15:0] xwr_data;           //XINTFд������DSP-XINTF�ӿڻ�ȡ������
    wire wr_end;                    //XINTFд������ɱ�־ 


    //����ʹ�ñ���
    reg [15:0] xdata_w;             //���� д���� XINTF�������� ����
    reg flag_wr;                    //״̬��־��д����ʱ��1������״̬��0
    //ʵ������xintf
    xintf xintf_inst(
        .rst_n          (rst_n      ),
        .clk50M         (clk50M     ),
        //XINTF �ⲿ�ӿ��ź�
        .xcs_n          (xcs_n       ),
        .xrd            (xrd        ),
        .xwe            (xwe        ),
        .xdata          (xdata      ),
        //XINTF �ڲ��ӿ��ź�
        .xrd_data       (xrd_data   ),
        .rd_end         (rd_end     ),
        .rd_fall        (rd_fall    ),
        .xwr_data       (xwr_data   ),
        .wr_end         (wr_end     )
    );
    //ʱ��
    always #10 clk50M = ~clk50M;
    //��ʼ��
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

        //���濪ʼ��
        xcs_n = 0;//Ƭѡ
        xintf_write_byte(16'h5555);
        xintf_read_byte();
    end

    //XINTFд��ʱxdata = xdata_w
    //����״̬xdata = 16'hzzzz����xintf_instʵ������xdata��
    assign xdata = (flag_wr == 1) ? xdata_w : 16'hzzzz;

    //XINTFд��һ���ֽ����ݣ�XINTFģ����������
    task xintf_write_byte(
        input [15:0] data
    );
    begin
        flag_wr = 1;        //������״̬��־��1
        #80;
        xwe = 0;
        xdata_w = data;
        #200;
        xwe = 1;
        #80;
        xdata_w = 16'hzzzz;
        flag_wr = 0;        //������״̬��־��0
    end endtask

    //XINTF����һ���ֽ����ݣ�XINTFģ�����ڵ���
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

