interface uart_if;

    logic clk;
    logic rst;

    logic rx;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       framing_error;

endinterface
