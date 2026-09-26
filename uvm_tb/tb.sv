`timescale 1ns/1ps

// UART interface must be declared outside the module
`include "uart_if.sv"


module tb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // Include project UVM classes
    `include "uart_sequence_item.sv"
    `include "uart_sequence.sv"
    `include "uart_sequencer.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
    `include "uart_scoreboard.sv"
    `include "uart_coverage.sv"
    `include "uart_env.sv"
    `include "uart_test.sv"


    // UART interface instance
    uart_if uart_vif();


    // DUT
    uart_rx #(
        .CLKS_PER_BIT(217)
    ) dut (

        .clk           (uart_vif.clk),
        .rst           (uart_vif.rst),
        .rx            (uart_vif.rx),

        .rx_data       (uart_vif.rx_data),
        .rx_valid      (uart_vif.rx_valid),
        .framing_error (uart_vif.framing_error)

    );


    // Clock generation
    initial begin

        uart_vif.clk = 1'b0;

        forever begin
            #20;
            uart_vif.clk = ~uart_vif.clk;
        end

    end


    // Reset generation
    initial begin

        uart_vif.rst = 1'b1;
        uart_vif.rx  = 1'b1;

        #200;

        uart_vif.rst = 1'b0;

    end


    // Pass virtual interface to UVM
    initial begin

        uvm_config_db#(virtual uart_if)::set(
            null,
            "*",
            "vif",
            uart_vif
        );

        run_test("uart_test");

    end

endmodule
