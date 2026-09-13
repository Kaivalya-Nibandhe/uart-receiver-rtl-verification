`timescale 1ns/10ps

module uart_assertions (
    input logic       clk,
    input logic       rst,
    input logic       rx_valid,
    input logic [7:0] rx_data
);

    // ============================================================
    // ASSERTION 1
    //
    // rx_valid must not remain HIGH for two consecutive clock
    // cycles. If rx_valid is HIGH in the current cycle, it must
    // be LOW in the next cycle.
    // ============================================================

    property rx_valid_one_cycle;

        @(posedge clk)
        rx_valid |=> !rx_valid;

    endproperty


    assert property (rx_valid_one_cycle)
    else
        $error(
            "ASSERTION FAILED: rx_valid remained HIGH for multiple cycles"
        );


    // ============================================================
    // ASSERTION 2
    //
    // While reset is asserted, rx_valid must remain LOW.
    // ============================================================

    property rx_valid_low_during_reset;

        @(posedge clk)
        rst |-> !rx_valid;

    endproperty


    assert property (rx_valid_low_during_reset)
    else
        $error(
            "ASSERTION FAILED: rx_valid is HIGH during reset"
        );


    // ============================================================
    // ASSERTION 3
    //
    // rx_data should remain stable during a valid receive cycle.
    //
    // NOTE:
    // This assertion may be timing-sensitive because rx_data and
    // rx_valid can be updated together by nonblocking assignments
    // inside the DUT. In that situation, $stable(rx_data) may fail
    // on the same clock edge that rx_valid becomes HIGH, even when
    // the DUT behavior is correct.
    // ============================================================

    property rx_data_stable_when_valid;

        @(posedge clk)
        rx_valid |-> $stable(rx_data);

    endproperty


    assert property (rx_data_stable_when_valid)
    else
        $error(
            "ASSERTION FAILED: rx_data changed while rx_valid was HIGH"
        );

endmodule
