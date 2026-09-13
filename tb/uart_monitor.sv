`timescale 1ns/10ps

// verilator lint_off DECLFILENAME
// verilator lint_off UNUSED

class uart_monitor;

    // Stores the most recently received UART frame.
    bit [7:0] last_rx_data;

    // Stores the previously received UART frame.
    bit [7:0] previous_rx_data;

    // Counts the number of successfully monitored transactions.
    integer transaction_count;


    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------
    function new();

        last_rx_data      = 8'h00;
        previous_rx_data  = 8'h00;
        transaction_count = 0;

    endfunction


    // ------------------------------------------------------------
    // UART Monitor Task
    //
    // Waits for rx_valid to become HIGH, captures rx_data,
    // updates the transaction history, and increments the count.
    //
    // ref is used so that the monitor observes the live DUT signals.
    // ------------------------------------------------------------
    task automatic run_monitor(
        ref logic       rx_valid,
        ref logic [7:0] rx_data
    );

        forever begin

            // Wait for the DUT to indicate a valid received frame.
            @(posedge rx_valid);


            // Save the previously received frame before updating
            // last_rx_data with the newly received frame.
            previous_rx_data = last_rx_data;


            // Capture the newly received UART data.
            last_rx_data = rx_data;


            // Increment the number of received transactions.
            transaction_count = transaction_count + 1;


            // Display the received data.
            $display(
                "MONITOR: RX DATA = 0x%02h",
                last_rx_data
            );

        end

    endtask

endclass

// verilator lint_on UNUSED
// verilator lint_on DECLFILENAME
