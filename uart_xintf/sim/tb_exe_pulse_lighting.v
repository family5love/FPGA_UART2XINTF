`timescale 1ns / 1ps

module tb_exe_pulse_lighting(); 
   //系统信号
    reg                     clk200M             ;           //200M时钟输入
    reg                     rst_n               ;           //复位，低电平有效
    //命令输入
    reg             [ 7:0]  mode                ;           //工作模式
    reg             [15:0]  distance            ;           //激光测距值(m)
    reg             [31:0]  phase_diff          ;           //相位偏差(5ns)
    reg             [31:0]  expose_time         ;           //探测器曝光时长
    reg             [15:0]  laser_width         ;           //激光脉宽
    reg                     flag_en             ;           //命令有效标志,高电平有效
    //控制信号输出
    wire                    laser_ttl           ;           //激光出射信号
    wire                    SWIR_ttl            ;           //SWIR曝光信号

    //实例化：exe_pusle_lighting
    exe_pusle_lighting exe_pusle_lighting_inst(
    //系统信号
        .clk200M             (clk200M       ),          //200M时钟输入
        .rst_n               (rst_n         ),          //复位，低电平有效
        //命令输入
        .mode                (mode          ),          //工作模式
        .distance            (distance      ),          //激光测距值(m)
        .phase_diff          (phase_diff    ),          //相位偏差(5ns)
        .expose_time         (expose_time   ),          //探测器曝光时长
        .laser_width         (laser_width   ),          //激光脉宽
        .flag_en             (flag_en       ),          //命令有效标志,高电平有效
        //控制信号输出
        .laser_ttl           (laser_ttl     ),          //激光出射信号
        .SWIR_ttl            (SWIR_ttl      )           //SWIR曝光信号
    );

    always #2.5 clk200M <= ~clk200M;                    //时钟周期5ns，200MHz

    initial begin
        clk200M = 0;
        rst_n = 0;
        mode = 8'h00;
        distance = 16'h0000;
        phase_diff = 32'h0000_0000;
        expose_time = 32'h0000_0000;
        laser_width = 16'h0000;
        flag_en = 'b0;

        #100;                           //复位延迟100ns
        rst_n = 1;

        
        cmd_debug_once_100us_10ms_20ms();   //调试用模式下（距离无效）：单次，激光脉宽100us，相位偏差10ms， 曝光时长20ms
        #12_000_000;                        //12ms，单次未结束
        cmd_debug_once_100us_10ms_20ms();   //调试用模式下（距离无效）：单次，激光脉宽100us，相位偏差10ms， 曝光时长20ms
        #19_000_000;        
        cmd_real_10Hz_10us_50us_100us();    //实际用模式下（距离/c加入相位差）：10Hz，激光脉宽10us，相位偏差50us， 曝光时长100us
        #201_000_000;
        cmd_cycle_stop();                   //stop
        cmd_debug_once_10us_10us_100us();   //调试用模式下（距离无效）：单次，激光脉宽10us，相位偏差10us， 曝光时长100us
    end

    //配置调试用模式下（距离无效）：单次，激光脉宽100us，相位偏差10ms， 曝光时长20ms
    task cmd_debug_once_100us_10ms_20ms(); 
    begin
        mode = 8'h18;                   //调试用,频率：单次
        distance = 16'd3000;            //距离：3000  无效
        laser_width = 16'd20_000;       //激光脉宽:100us
        phase_diff = 32'd2_000_000;     //相位偏差:10ms
        expose_time = 32'd4_000_000;    //曝光时长:20ms
        cmd_enable();                   //命令写入
    end endtask
    //配置调试用模式下（距离无效）：单次，激光脉宽10us，相位偏差10us， 曝光时长100us
    task cmd_debug_once_10us_10us_100us(); 
    begin
        mode = 8'h18;                   //调试用,频率：单次
        distance = 16'd3000;            //距离：3000  无效
        laser_width = 16'd2_000;        //激光脉宽:10us
        phase_diff = 32'd2_000;         //相位偏差:10us
        expose_time = 32'd20_000;       //曝光时长:100us
        cmd_enable();                   //命令写入
    end endtask
    //配置实际用模式下（距离/c加入相位差）：10Hz，激光脉宽10us，相位偏差50us， 曝光时长100us
    task cmd_real_10Hz_10us_50us_100us();
    begin
        mode = 8'h13;                   //实际用,频率：单次
        distance = 16'd3000;            //距离：3000
        laser_width = 16'd2000;         //2000 * 5ns = 10us
        phase_diff = 32'd6000;          //相位偏差: 6000 * 5ns = 30us， 真实相位差 = 30us + (distance*20/3)ns = 50us
        expose_time = 32'd20000;        //20000 * 5ns = 100us
        cmd_enable();                   //命令写入
    end endtask
    //周期模式停止
    task cmd_cycle_stop();
    begin
        mode = 8'h1f;
        cmd_enable();                   //命令写入
    end endtask
    //命令写入
    task cmd_enable();
    begin
        flag_en = 'b1;
        #20;                            //20ns高电平，flag_en由uart_rx_cmd模块提供，时钟clk50M
        flag_en = 'b0;
    end endtask





endmodule