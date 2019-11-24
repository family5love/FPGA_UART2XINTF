library verilog;
use verilog.vl_types.all;
entity tb_uart_xintf is
    generic(
        U2X_FBYTE_NUM   : integer := 22;
        X2U_FBYTE_NUM   : integer := 6;
        BPS_460800_T    : integer := 2170
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of U2X_FBYTE_NUM : constant is 1;
    attribute mti_svvh_generic_type of X2U_FBYTE_NUM : constant is 1;
    attribute mti_svvh_generic_type of BPS_460800_T : constant is 1;
end tb_uart_xintf;
