/* verilator lint_off DECLFILENAME */
interface uart_rx_if;

    logic clk;
    logic rst;
    logic rx;

    logic rx_valid;
    logic [7:0] rx_data;

endinterface
/* verilator lint_on DECLFILENAME */
