class uart_sequence extends uvm_sequence #(uart_sequence_item);

    `uvm_object_utils(uart_sequence)

    // Number of transactions that should produce
    // a valid UART reception
    int valid_transaction_count;

    // Total number of transactions including
    // negative/error tests
    int total_transaction_count;


    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------

    function new(
        string name = "uart_sequence"
    );

        super.new(name);

        valid_transaction_count = 0;
        total_transaction_count = 0;

    endfunction


    // ------------------------------------------------------------
    // Sequence body
    // ------------------------------------------------------------

    virtual task body();

        uart_sequence_item req;


        // ========================================================
        // 1. Directed normal transactions
        // ========================================================

        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h00;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h55;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'hAA;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'hFF;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        // ========================================================
        // 2. Randomized normal transactions
        // ========================================================

        repeat (10) begin

            req = uart_sequence_item::type_id::create("req");

            start_item(req);

            req.frame_type = uart_sequence_item::UART_NORMAL;

            if (!req.randomize()) begin

                `uvm_error(
                    "UART_SEQ",
                    "Failed to randomize UART data"
                )

            end

            finish_item(req);

            valid_transaction_count++;
            total_transaction_count++;

        end


        // ========================================================
        // 3. Invalid stop-bit test
        // ========================================================
        //
        // Expected DUT behavior:
        //     framing_error = 1
        //     rx_valid      = 0
        //
        // This is a negative test, so it is NOT included in
        // valid_transaction_count.
        //
        // It IS included in total_transaction_count.
        // ========================================================

        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'hA5;
        req.frame_type = uart_sequence_item::UART_INVALID_STOP;

        finish_item(req);

        total_transaction_count++;


        // ========================================================
        // 4. False-start test
        // ========================================================
        //
        // Expected DUT behavior:
        //     No rx_valid
        //     No framing_error
        //
        // This is also a negative test.
        // ========================================================

        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h00;
        req.frame_type = uart_sequence_item::UART_FALSE_START;

        finish_item(req);

        total_transaction_count++;


        // ========================================================
        // 5. Back-to-back normal transactions
        // ========================================================

        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h3C;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'hC3;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h96;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        req = uart_sequence_item::type_id::create("req");

        start_item(req);

        req.data = 8'h69;
        req.frame_type = uart_sequence_item::UART_NORMAL;

        finish_item(req);

        valid_transaction_count++;
        total_transaction_count++;


        // ========================================================
        // Sequence summary
        // ========================================================

        `uvm_info(
            "UART_SEQ",
            $sformatf(
                "Completed UART sequence. Valid transactions = %0d, Total transactions = %0d",
                valid_transaction_count,
                total_transaction_count
            ),
            UVM_LOW
        )

    endtask

endclass
