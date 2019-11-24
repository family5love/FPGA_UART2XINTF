library verilog;
use verilog.vl_types.all;
entity xintf_top is
    port(
        clk50M          : in     vl_logic;
        rst_n           : in     vl_logic;
        xcs_n           : in     vl_logic;
        xrd             : in     vl_logic;
        xwe             : in     vl_logic;
        xdata           : inout  vl_logic_vector(15 downto 0);
        c_xcs_n         : in     vl_logic;
        c_xrd_req       : out    vl_logic;
        f1_wr_en        : in     vl_logic;
        f1_buf_in       : in     vl_logic_vector(7 downto 0);
        f2_rd_en        : in     vl_logic;
        f2_buf_out      : out    vl_logic_vector(7 downto 0);
        fifo2_cnt       : out    vl_logic_vector(7 downto 0)
    );
end xintf_top;
