`timescale 1ns / 1ps
//��ģ�鼯��XINTF����ʱ��ģ�顢2��FIFO�洢ģ�飬ʵ�ֶ���ֽڵ�XINTF�շ�
//1.������FIFO�ӿ��ź�д��FIFO1����XINTF�ӿڶ�����
//2.������XINTF�ӿ�д��FIFO2����FIFO�ӿ��źŶ�����
//
//   FIFO�ӿ��ź�  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
//2019.10.26

module xintf_top(
    //ϵͳ�ź�
    input clk50M,
    input rst_n,

    //XINTF����ӿ��źţ�XINTF�ٷ�
	input xrd,						//���ź�
	input xwe,						//д�ź�
	inout [15:0] xdata,				//XINTF ��������
    //XINTF����ӿ��źţ��Զ���
    input c_xcs_n,                  //�Զ���XINTFʹ�ܣ��͵�ƽ��Ч���ٷ�CS0/CS6/CS7��ʹ��
    output c_xrd_req,               //�������źţ�FIFO1��֡���ݴ���ʱ����XINTF��ȡ���ߵ�ƽ��Ч

    //FIFO1�ӿ��ź�
	input f1_wr_en,				    //дʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO1
	input [7:0] f1_buf_in,			//д���ݣ������ڲ�FIFO1
	//FIFO2�ӿ��ź�
	input f2_rd_en,				    //��ʹ�ܣ��ߵ�ƽ��Ч�������ڲ�FIFO2
	output [7:0] f2_buf_out,		//�����ݣ������ڲ�FIFO2
	output [7:0] fifo2_cnt			//FIFO2��ʹ���ֽ���
);

//�ֲ�����
localparam U2X_FBYTE_NUM = 22;			//���� -> XINTF ֡�ֽڳ���(UART to XINTF Frame Byte Num)
//��������
wire [15:0] xrd_data;
wire [15:0] xwr_data;
wire [7:0] f1_buf_out;
wire [7:0] f2_buf_in;
wire [7:0] fifo1_cnt;

//ʵ������XINTF
//       
//   FIFO�ӿ��ź�  ->  FIFO1 -> XINTF
//                <-  FIFO2 <-
//
xintf xintf_inst(
    .rst_n                  (rst_n              ),
	.clk50M                 (clk50M             ),
	//XINTF �ⲿ�ӿ��ź�
	.xcs_n                  (c_xcs_n 		    ),				//ʹ�ܣ��͵�ƽ��Ч
	.xrd                    (xrd                ),				//���ź�
	.xwe                    (xwe                ),				//д�ź�
	.xdata                  (xdata              ),				//XINTF ��������
	//XINTF �ڲ��ӿ��ź�
	.xrd_data               (xrd_data			),				//λ��16bit
	.rd_fall                (rd_fall			),				//
	.rd_end                 (					),				// 
	.xwr_data               (xwr_data			),				//λ��16bit
	.wr_end                 (wr_end				)				//
);

assign xrd_data = {8'h00, f1_buf_out}; 							//��f1_buf_out ��8bitλ����չΪ16bitλ����8λ��0

//ʵ������FIFO1(FIFO�ӿ��ź� -> FIFO1 -> XINTF)��FIFO�ӿ��ź�д�룬XINTF����
fifo fifo1_inst(
	.clk50M					(clk50M				),
	.rst_n					(rst_n				),
	//FIFO�ź�
	.wr_en					(f1_wr_en			),				//����FIFO�ӿ��źţ�FIFO�ӿ��ź�д��
	.buf_in					(f1_buf_in			),				//����FIFO�ӿ��źţ�FIFO1��FIFO�ӿ��ź�д��
	.rd_en					(rd_fall			),				//����xintf_inst.rd_fall��XINTF����
	.buf_out				(f1_buf_out			),				//����xintf_inst.xrd_data������չλ��XINTF����
	//FIFO״̬���
	.buf_empty				(					),				//FIFO��
	.buf_full				(					),			    //FIFO��������XINTF��ʼ��ȡ����
	.fifo_cnt				(fifo1_cnt			)				//FIFO��ʹ���ֽ���
);

assign f2_buf_in = xwr_data[7:0];								//��f1_buf_out ��8bitλ����չΪ16bitλ����8λ��0

//ʵ������FIFO2(XINTF -> FIFO2 -> FIFO�ӿ��ź�)��XINTFд�룬FIFO�ӿ��źŶ���
fifo fifo2_inst(
	.clk50M					(clk50M				),
	.rst_n					(rst_n				),
	//FIFO�ź�
	.wr_en					(wr_end				),				//����xintf_inst.wr_end
	.buf_in					(f2_buf_in			),				//����xintf_inst.xwr_data��ȡ��8bit
	.rd_en					(f2_rd_en			),				//����FIFO�ӿ��źţ�FIFO1
	.buf_out				(f2_buf_out			),				//����FIFO�ӿ��źţ�FIFO1
	//FIFO״̬���
	.buf_empty				(					),				//FIFO��
	.buf_full				(					),				//FIFO��
	.fifo_cnt				(fifo2_cnt			)				//FIFO��ʹ���ֽ���
);

assign c_xrd_req = (fifo1_cnt >= U2X_FBYTE_NUM) ? 'b1 : 'b0;		//FIFO1�洢һ֡�ֽں�����XINTF��ȡ

endmodule