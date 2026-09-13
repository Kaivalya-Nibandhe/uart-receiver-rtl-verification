`timescale 1ns/10ps

//============================================================
// UART Receiver
//
// UART configuration:
//   - 8 data bits
//   - No parity
//   - 1 stop bit
//   - LSB-first data transmission
//
// The receiver uses an FSM and a clock-cycle counter to
// sample incoming UART data at the appropriate time.
//
// CLKS_PER_BIT defines the number of system-clock cycles
// corresponding to one UART bit period.
//
// framing_error is asserted for one clock cycle when the
// received stop bit is LOW instead of HIGH.
//============================================================

module uart_rx #(
    parameter CLKS_PER_BIT = 217
) (
    input clk,
    input rst,
    input rx,

    output rx_valid,
    output [7:0] rx_data,
    output framing_error
);

    //========================================================
    // FSM state encoding
    //========================================================

    parameter STATE_IDLE    = 3'b000;
    parameter STATE_START   = 3'b001;
    parameter STATE_DATA    = 3'b010;
    parameter STATE_STOP    = 3'b011;
    parameter STATE_CLEANUP = 3'b100;


    //========================================================
    // Internal registers
    //========================================================

    // Counts system-clock cycles within the current UART bit.
    reg [7:0] baud_cnt;

    // Tracks the number of received data bits.
    reg [2:0] bit_cnt;

    // Temporarily stores the received 8-bit data.
    reg [7:0] rx_shift_reg;

    // Internal registered version of rx_valid.
    reg rx_valid_reg;

    // Internal registered version of framing_error.
    reg framing_error_reg;

    // Current FSM state.
    reg [2:0] state;


    //========================================================
    // UART receiver state machine
    //========================================================

    always @(posedge clk) begin

        if (rst) begin

            // Reset all internal registers.
            baud_cnt        <= 8'd0;
            bit_cnt         <= 3'd0;
            rx_shift_reg    <= 8'd0;
            rx_valid_reg    <= 1'b0;
            framing_error_reg <= 1'b0;
            state           <= STATE_IDLE;

        end
        else begin

            case (state)

                //================================================
                // IDLE STATE
                //
                // The UART line remains HIGH when idle.
                // A LOW level indicates a possible start bit.
                //================================================

                STATE_IDLE: begin

                    // Output flags are inactive by default.
                    rx_valid_reg      <= 1'b0;
                    framing_error_reg <= 1'b0;

                    baud_cnt <= 8'd0;
                    bit_cnt  <= 3'd0;

                    if (rx == 1'b0) begin
                        state <= STATE_START;
                    end
                    else begin
                        state <= STATE_IDLE;
                    end

                end


                //================================================
                // START-BIT VALIDATION
                //
                // Wait for approximately half a bit period and
                // verify that RX is still LOW.
                //
                // This rejects short glitches or false starts.
                //================================================

                STATE_START: begin

                    if (baud_cnt == (CLKS_PER_BIT - 1) / 2) begin

                        if (rx == 1'b0) begin

                            // Valid start bit detected.
                            baud_cnt <= 8'd0;
                            state    <= STATE_DATA;

                        end
                        else begin

                            // False start detected.
                            state <= STATE_IDLE;

                        end

                    end
                    else begin

                        baud_cnt <= baud_cnt + 1'b1;
                        state    <= STATE_START;

                    end

                end


                //================================================
                // DATA RECEPTION
                //
                // Each data bit is sampled once every
                // CLKS_PER_BIT clock cycles.
                //
                // UART transmits the least-significant bit first.
                //================================================

                STATE_DATA: begin

                    if (baud_cnt < CLKS_PER_BIT - 1) begin

                        baud_cnt <= baud_cnt + 1'b1;
                        state    <= STATE_DATA;

                    end
                    else begin

                        // Sample the current data bit.
                        baud_cnt <= 8'd0;
                        rx_shift_reg[bit_cnt] <= rx;

                        if (bit_cnt < 3'd7) begin

                            // Move to the next data bit.
                            bit_cnt <= bit_cnt + 1'b1;
                            state   <= STATE_DATA;

                        end
                        else begin

                            // All eight data bits received.
                            bit_cnt <= 3'd0;
                            state   <= STATE_STOP;

                        end

                    end

                end


                //================================================
                // STOP-BIT VALIDATION
                //
                // The stop bit must be HIGH.
                //
                // If the stop bit is LOW, framing_error is
                // asserted for one clock cycle.
                //================================================

                STATE_STOP: begin

                    if (baud_cnt < CLKS_PER_BIT - 1) begin

                        baud_cnt <= baud_cnt + 1'b1;
                        state    <= STATE_STOP;

                    end
                    else begin

                        baud_cnt <= 8'd0;

                        if (rx == 1'b1) begin

                            // Valid stop bit.
                            rx_valid_reg      <= 1'b1;
                            framing_error_reg <= 1'b0;

                        end
                        else begin

                            // Invalid stop bit.
                            rx_valid_reg      <= 1'b0;
                            framing_error_reg <= 1'b1;

                        end

                        state <= STATE_CLEANUP;

                    end

                end


                //================================================
                // CLEANUP STATE
                //
                // Deassert rx_valid and framing_error, then
                // return to the idle state.
                //================================================

                STATE_CLEANUP: begin

                    rx_valid_reg      <= 1'b0;
                    framing_error_reg <= 1'b0;
                    state             <= STATE_IDLE;

                end


                //================================================
                // DEFAULT STATE
                //
                // Recover safely by returning to IDLE.
                //================================================

                default: begin

                    state             <= STATE_IDLE;
                    rx_valid_reg      <= 1'b0;
                    framing_error_reg <= 1'b0;
                    baud_cnt          <= 8'd0;
                    bit_cnt           <= 3'd0;

                end

            endcase

        end

    end


    //============================================================
    // Output assignments
    //============================================================

    assign rx_valid      = rx_valid_reg;
    assign rx_data       = rx_shift_reg;
    assign framing_error = framing_error_reg;

endmodule
