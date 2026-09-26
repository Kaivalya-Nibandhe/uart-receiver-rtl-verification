class uart_sequence_item extends uvm_sequence_item;

    // =========================================================
    // UART transaction data
    // =========================================================

    rand bit [7:0] data;


    // =========================================================
    // Type of UART stimulus
    // =========================================================

    typedef enum {
        UART_NORMAL,
        UART_INVALID_STOP,
        UART_FALSE_START
    } uart_frame_type_e;

    uart_frame_type_e frame_type;


    // =========================================================
    // DUT response information
    //
    // These fields are filled by the monitor.
    // =========================================================

    bit rx_valid;
    bit framing_error;


    // =========================================================
    // UVM factory registration
    // =========================================================

    `uvm_object_utils_begin(uart_sequence_item)

        `uvm_field_int(
            data,
            UVM_ALL_ON
        )

        `uvm_field_enum(
            uart_frame_type_e,
            frame_type,
            UVM_ALL_ON
        )

        `uvm_field_int(
            rx_valid,
            UVM_ALL_ON
        )

        `uvm_field_int(
            framing_error,
            UVM_ALL_ON
        )

    `uvm_object_utils_end


    // =========================================================
    // Constructor
    // =========================================================

    function new(
        string name = "uart_sequence_item"
    );

        super.new(name);

        data           = 8'h00;
        frame_type     = UART_NORMAL;
        rx_valid       = 1'b0;
        framing_error  = 1'b0;

    endfunction

endclass
