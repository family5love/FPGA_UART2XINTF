//===================================================================================
// uart_xintf 
// ��ģ��ʵ��uart��XINTF�ӿ�֮������ݴ��ݣ����������������£�
//  1. uart_rx���룬XINTF�����
//      1��uart_rx���մ����źţ���д��FIFO1��
//      2��FIFO1�洢���������ﵽ1֡ʱ��c_xrd_req��1������DSPͨ��XINTF�ӿڶ�ȡ���ݣ�
//  2. XINTF���룬uart_tx�����
//      DSPͨ��XINTFд��������FIFO2����д���������ﵽ1֡ʱ������uart_tx���д��ڷ��͡�
// �� ��������ʾ��ͼ��
//                     xintf_top
//                ____________________
//   uart_rx  ->  | FIFO1 -> | XINTF |  
//   uart_tx  <-  | FIFO2 <- |       |      
//                ����������������������������������������
//
//                                                              ------2019.10.29
//===================================================================================

`timescale 1ns / 1ps

module uart_xintf(
    //ϵͳ�ź�
    input               clk50M              ,
    input               rst_n               ,
    //UART�ӿ�
    input               uart_rxd            ,           //���ڽ��ն�
    output              uart_txd            ,           //���ڷ��Ͷ�
    //XINTF����ӿ��źţ�XINTF�ٷ�
	input               xrd                 ,			//���ź�
	input               xwe                 ,			//д�ź�
	inout       [15:0]  xdata               ,			//XINTF ��������
    //XINTF����ӿ��źţ��Զ���
    input               c_xcs_n             ,           //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч
    output              c_xrd_req           ,           //�������źţ�FIFO1��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч
    //���ڽ����������
    output      [ 7:0]  cmd_mode            ,           //����ģʽ
    output      [15:0]  cmd_laser_dist      ,           //������ֵ(m)
    output      [31:0]  cmd_phase_diff      ,           //��λƫ��(5ns)
    output      [31:0]  cmd_exp_time        ,           //̽�����ع�ʱ��
    output      [15:0]  cmd_laser_width     ,           //��������
    output              cmd_flag_out                    //���������Ч��־���ߵ�ƽ��Ч      

);

//�ֲ�����
localparam X2U_FBYTE_NUM = 6;       //֡�ֽڳ���(XINTF to UART Frame Byte Num)
localparam RD_EN_DELAY = 4;         //f2_rd_en���ζ�ȡ����ӳ�(����ͼ��۲��ã�������Ҫ�޸�)

//��������
reg f2_rd_en;                       //��ʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO2
wire [7:0] f2_buf_out;              //�����ݣ������ڲ�FIFO2
reg tx_trig;                        //���ڷ��ʹ����ź�
wire tx_idle;                       //���ڷ��ͽӿڿ���״̬��־
wire [7:0] f1_buf_in;               //д���ݣ������ڲ�FIFO1
wire [7:0] fifo2_cnt;               //FIFO2��ʹ���ֽ������ﵽһ֡��������������


//FIFO2��uart_tx���ӵ��м����
reg flag_f2_rd;                     //FIFO2֡���ݶ�ȡ��ʶ
reg [5:0] f2_rd_cnt;                //FIFO2֡���ݶ�ȡ������
reg [2:0] f2_rd_en_delay;           //��ʹ����ʱ����������֤f2_rd_enһ�ν���ȡһ���ֽ����ݣ�
reg flag_f2_rd_en;                  //f2_rd_en�źż����־


//===================================================================================
//ʵ���� xintf_top
//===================================================================================
xintf_top xintf_top_inst(
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //XINTF����ӿ��źţ�XINTF�ٷ�
	.xrd                    (xrd            ),					//���ź�
	.xwe                    (xwe            ),				    //д�ź�
	.xdata                  (xdata          ),				    //XINTF ��������
    //XINTF����ӿ��źţ��Զ���
    .c_xcs_n                (c_xcs_n        ),                  //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч
    .c_xrd_req              (c_xrd_req      ),                  //�������źţ�FIFO��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч
    //FIFO1�ӿ��ź�
	.f1_wr_en               (f1_wr_en       ),				    //дʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO1
	.f1_buf_in              (f1_buf_in      ),			        //[7:0]д���ݣ������ڲ�FIFO1
    //FIFO2�ӿ��ź�
	.f2_rd_en               (f2_rd_en       ),				    //[7:0]��ʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO2
	.f2_buf_out             (f2_buf_out     ),		            //�����ݣ������ڲ�FIFO2   
    .fifo2_cnt              (fifo2_cnt      )                   //FIFO2״̬��FIFO2��ʹ���ֽ������ﵽһ֡��������������
);


//===================================================================================
//uart_tx �� xintf_top ����
//===================================================================================
//ʵ������uart_tx
uart_tx uart_tx_inst(
    	//ϵͳ�ź�
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
	//���ڷ��ͽӿ�
	.rs232_tx               (uart_txd       ),
	//���ڷ��ʹ����ź�
    .tx_trig                (tx_trig        ),
	.tx_data                (f2_buf_out     ),
	//���ڷ��ͽӿڿ���״̬��־
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

//f2_rd_en,��FIFO2���ݶ���
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        f2_rd_en <= 'b0;
    else if(flag_f2_rd && tx_idle && ~flag_f2_rd_en && ~f2_rd_en)
        f2_rd_en <= 'b1;
    else
        f2_rd_en <= 'b0;
end

//f2_rd_en_delay, f2_rd_en�ź����μ��ʱ�������
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

//tx_trig,��������FIFO2����д��uart_tx_inst
always @(posedge clk50M or negedge rst_n) begin
    if(~rst_n)
        tx_trig <= 'b0;
    else
        tx_trig <= f2_rd_en;
end

//===================================================================================
//uart_rx �� xintf_top ����
//===================================================================================
//ʵ������uart_rx
uart_rx uart_rx_inst(
    //ϵͳ�ź�
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //���ڽ��չܽ�
    .rs232_rx               (uart_rxd       ),
    //�������
    .rx_data                (f1_buf_in      ),      //���ڽ�������[7:0]
    .flag_end               (f1_wr_en       )       //���ֽڽ�����ɱ�־
);


//===================================================================================
//uart_rx_cmd:�������������uart_rx�������룬����Ľ������ֱ������uart_xintf����ӿ�
//===================================================================================
//ʵ����:uart_rx_cmd,�����������
uart_rx_cmd  uart_rx_cmd_inst(
    //ϵͳ�ź�
    .clk50M                 (clk50M         ),
    .rst_n                  (rst_n          ),
    //��������  
    .rx_data                (f1_buf_in      ),           //��������
    .flag_in                (f1_wr_en       ),           //����������Ч��־���ߵ�ƽ��Ч
    //�������  
    .mode                   (cmd_mode       ),           //����ģʽ
    .laser_dist             (cmd_laser_dist ),           //������ֵ(m)
    .phase_diff             (cmd_phase_diff ),           //��λƫ��(5ns)
    .exp_time               (cmd_exp_time   ),           //̽�����ع�ʱ��
    .laser_width            (cmd_laser_width),           //��������
    .flag_out               (cmd_flag_out   )            //���������Ч��־���ߵ�ƽ��Ч
);

endmodule 
