library verilog;
use verilog.vl_types.all;
entity xintf is
    port(
        rst_n           : in     vl_logic;
        clk50M          : in     vl_logic;
        xcs_n           : in     vl_logic;
        xrd             : in     vl_logic;
        xwe             : in     vl_logic;
        xdata           : inout  vl_logic_vector(15 downto 0);
        xrd_data        : in     vl_logic_vector(15 downto 0);
        rd_fall         : out    vl_logic;
        rd_end          : out    vl_logic;
        xwr_data        : out    vl_logic_vector(15 downto 0);
        wr_end          : out    vl_logic
    );
end xintf;
