`timescale 1ns / 1ps

module tb_exe_pulse_lighting(); 
   //ϵͳ�ź�
    reg                     clk200M             ;           //200Mʱ������
    reg                     rst_n               ;           //��λ���͵�ƽ��Ч
    //��������
    reg             [ 7:0]  mode                ;           //����ģʽ
    reg             [15:0]  distance            ;           //������ֵ(m)
    reg             [31:0]  phase_diff          ;           //��λƫ��(5ns)
    reg             [31:0]  expose_time         ;           //̽�����ع�ʱ��
    reg             [15:0]  laser_width         ;           //��������
    reg                     flag_en             ;           //������Ч��־,�ߵ�ƽ��Ч
    //�����ź����
    wire                    laser_ttl           ;           //��������ź�
    wire                    SWIR_ttl            ;           //SWIR�ع��ź�

    //ʵ������exe_pusle_lighting
    exe_pusle_lighting exe_pusle_lighting_inst(
    //ϵͳ�ź�
        .clk200M             (clk200M       ),          //200Mʱ������
        .rst_n               (rst_n         ),          //��λ���͵�ƽ��Ч
        //��������
        .mode                (mode          ),          //����ģʽ
        .distance            (distance      ),          //������ֵ(m)
        .phase_diff          (phase_diff    ),          //��λƫ��(5ns)
        .expose_time         (expose_time   ),          //̽�����ع�ʱ��
        .laser_width         (laser_width   ),          //��������
        .flag_en             (flag_en       ),          //������Ч��־,�ߵ�ƽ��Ч
        //�����ź����
        .laser_ttl           (laser_ttl     ),          //��������ź�
        .SWIR_ttl            (SWIR_ttl      )           //SWIR�ع��ź�
    );

    always #2.5 clk200M <= ~clk200M;                    //ʱ������5ns��200MHz

    initial begin
        clk200M = 0;
        rst_n = 0;
        mode = 8'h00;
        distance = 16'h0000;
        phase_diff = 32'h0000_0000;
        expose_time = 32'h0000_0000;
        laser_width = 16'h0000;
        flag_en = 'b0;

        #100;                           //��λ�ӳ�100ns
        rst_n = 1;

        
        cmd_debug_once_100us_10ms_20ms();   //������ģʽ�£�������Ч�������Σ���������100us����λƫ��10ms�� �ع�ʱ��20ms
        #12_000_000;                        //12ms������δ����
        cmd_debug_once_100us_10ms_20ms();   //������ģʽ�£�������Ч�������Σ���������100us����λƫ��10ms�� �ع�ʱ��20ms
        #19_000_000;        
        cmd_real_10Hz_10us_50us_100us();    //ʵ����ģʽ�£�����/c������λ���10Hz����������10us����λƫ��50us�� �ع�ʱ��100us
        #201_000_000;
        cmd_cycle_stop();                   //stop
        cmd_debug_once_10us_10us_100us();   //������ģʽ�£�������Ч�������Σ���������10us����λƫ��10us�� �ع�ʱ��100us
    end

    //���õ�����ģʽ�£�������Ч�������Σ���������100us����λƫ��10ms�� �ع�ʱ��20ms
    task cmd_debug_once_100us_10ms_20ms(); 
    begin
        mode = 8'h18;                   //������,Ƶ�ʣ�����
        distance = 16'd3000;            //���룺3000  ��Ч
        laser_width = 16'd20_000;       //��������:100us
        phase_diff = 32'd2_000_000;     //��λƫ��:10ms
        expose_time = 32'd4_000_000;    //�ع�ʱ��:20ms
        cmd_enable();                   //����д��
    end endtask
    //���õ�����ģʽ�£�������Ч�������Σ���������10us����λƫ��10us�� �ع�ʱ��100us
    task cmd_debug_once_10us_10us_100us(); 
    begin
        mode = 8'h18;                   //������,Ƶ�ʣ�����
        distance = 16'd3000;            //���룺3000  ��Ч
        laser_width = 16'd2_000;        //��������:10us
        phase_diff = 32'd2_000;         //��λƫ��:10us
        expose_time = 32'd20_000;       //�ع�ʱ��:100us
        cmd_enable();                   //����д��
    end endtask
    //����ʵ����ģʽ�£�����/c������λ���10Hz����������10us����λƫ��50us�� �ع�ʱ��100us
    task cmd_real_10Hz_10us_50us_100us();
    begin
        mode = 8'h13;                   //ʵ����,Ƶ�ʣ�����
        distance = 16'd3000;            //���룺3000
        laser_width = 16'd2000;         //2000 * 5ns = 10us
        phase_diff = 32'd6000;          //��λƫ��: 6000 * 5ns = 30us�� ��ʵ��λ�� = 30us + (distance*20/3)ns = 50us
        expose_time = 32'd20000;        //20000 * 5ns = 100us
        cmd_enable();                   //����д��
    end endtask
    //����ģʽֹͣ
    task cmd_cycle_stop();
    begin
        mode = 8'h1f;
        cmd_enable();                   //����д��
    end endtask
    //����д��
    task cmd_enable();
    begin
        flag_en = 'b1;
        #20;                            //20ns�ߵ�ƽ��flag_en��uart_rx_cmdģ���ṩ��ʱ��clk50M
        flag_en = 'b0;
    end endtask





endmodule