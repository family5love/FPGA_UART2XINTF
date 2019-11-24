library verilog;
use verilog.vl_types.all;
entity fifo is
    port(
        clk50M          : in     vl_logic;
        rst_n           : in     vl_logic;
        wr_en           : in     vl_logic;
        buf_in          : in     vl_logic_vector(7 downto 0);
        rd_en           : in     vl_logic;
        buf_out         : out    vl_logic_vector(7 downto 0);
        buf_empty       : out    vl_logic;
        buf_full        : out    vl_logic;
        fifo_cnt        : out    vl_logic_vector(7 downto 0)
    );
end fifo;
