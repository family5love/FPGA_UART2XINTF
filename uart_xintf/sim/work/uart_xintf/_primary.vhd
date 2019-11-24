library verilog;
use verilog.vl_types.all;
entity uart_xintf is
    port(
        clk50M          : in     vl_logic;
        rst_n           : in     vl_logic;
        uart_rxd        : in     vl_logic;
        uart_txd        : out    vl_logic;
        xcs_n           : in     vl_logic;
        xrd             : in     vl_logic;
        xwe             : in     vl_logic;
        xdata           : inout  vl_logic_vector(15 downto 0);
        c_xcs_n         : in     vl_logic;
        c_xrd_req       : out    vl_logic;
        cmd_mode        : out    vl_logic_vector(7 downto 0);
        cmd_laser_dist  : out    vl_logic_vector(15 downto 0);
        cmd_phase_diff  : out    vl_logic_vector(31 downto 0);
        cmd_exp_time    : out    vl_logic_vector(31 downto 0);
        cmd_laser_width : out    vl_logic_vector(15 downto 0);
        cmd_flag_out    : out    vl_logic
    );
end uart_xintf;
