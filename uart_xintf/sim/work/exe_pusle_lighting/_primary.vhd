library verilog;
use verilog.vl_types.all;
entity exe_pusle_lighting is
    port(
        clk200M         : in     vl_logic;
        rst_n           : in     vl_logic;
        mode            : in     vl_logic_vector(7 downto 0);
        distance        : in     vl_logic_vector(15 downto 0);
        phase_diff      : in     vl_logic_vector(31 downto 0);
        expose_time     : in     vl_logic_vector(31 downto 0);
        laser_width     : in     vl_logic_vector(15 downto 0);
        flag_en         : in     vl_logic;
        laser_ttl       : out    vl_logic;
        SWIR_ttl        : out    vl_logic
    );
end exe_pusle_lighting;
