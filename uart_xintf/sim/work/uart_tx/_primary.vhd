library verilog;
use verilog.vl_types.all;
entity uart_tx is
    port(
        clk50M          : in     vl_logic;
        rst_n           : in     vl_logic;
        rs232_tx        : out    vl_logic;
        tx_trig         : in     vl_logic;
        tx_data         : in     vl_logic_vector(7 downto 0);
        tx_idle         : out    vl_logic
    );
end uart_tx;
