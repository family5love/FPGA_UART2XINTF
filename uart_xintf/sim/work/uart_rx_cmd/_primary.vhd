library verilog;
use verilog.vl_types.all;
entity uart_rx_cmd is
    port(
        clk50M          : in     vl_logic;
        rst_n           : in     vl_logic;
        rx_data         : in     vl_logic_vector(7 downto 0);
        flag_in         : in     vl_logic;
        mode            : out    vl_logic_vector(7 downto 0);
        laser_dist      : out    vl_logic_vector(15 downto 0);
        phase_diff      : out    vl_logic_vector(31 downto 0);
        exp_time        : out    vl_logic_vector(31 downto 0);
        laser_width     : out    vl_logic_vector(15 downto 0);
        flag_out        : out    vl_logic
    );
end uart_rx_cmd;
