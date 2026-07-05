module uart_top_tb;

reg clk;
reg reset;
reg tx_start;
reg [7:0] tx_data;

wire [7:0] rx_data;
wire rx_done;
wire busy;


// DUT instantiation
uart_top uart_test (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .busy(busy)
);


// Clock generation
initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end


// Test stimulus + self checking
initial
begin
    // Initial values
    reset    = 1;
    tx_start = 0;
    tx_data  = 8'h00;

    // Reset
    #12;
    reset = 0;

    // ==================================
    // TEST 1: Send A5
    // ==================================
    #10;
    tx_data  = 8'hA5;
    tx_start = 1;

    #10;
    tx_start = 0;

    // Wait until receiver completes byte
    wait(rx_done == 1);

    // Automatic comparison
    if(rx_data == 8'hA5)
        $display(
            "PASS: Expected A5, Received %h",
            rx_data
        );
    else
        $display(
            "FAIL: Expected A5, Received %h",
            rx_data
        );

    // Wait for rx_done pulse to return low
    wait(rx_done == 0);

    #20;


    // ==================================
    // TEST 2: Send 00
    // ==================================
    tx_data  = 8'h00;
    tx_start = 1;

    #10;
    tx_start = 0;

    wait(rx_done == 1);

    if(rx_data == 8'h00)
        $display(
            "PASS: Expected 00, Received %h",
            rx_data
        );
    else
        $display(
            "FAIL: Expected 00, Received %h",
            rx_data
        );

    wait(rx_done == 0);

    #20;


    // ==================================
    // TEST 3: Send FF
    // ==================================
    tx_data  = 8'hFF;
    tx_start = 1;

    #10;
    tx_start = 0;

    wait(rx_done == 1);

    if(rx_data == 8'hFF)
        $display(
            "PASS: Expected FF, Received %h",
            rx_data
        );
    else
        $display(
            "FAIL: Expected FF, Received %h",
            rx_data
        );

    wait(rx_done == 0);

    #20;


    // ==================================
    // TEST 4: Send AB
    // ==================================
    tx_data  = 8'hAB;
    tx_start = 1;

    #10;
    tx_start = 0;

    wait(rx_done == 1);

    if(rx_data == 8'hAB)
        $display(
            "PASS: Expected AB, Received %h",
            rx_data
        );
    else
        $display(
            "FAIL: Expected AB, Received %h",
            rx_data
        );

    wait(rx_done == 0);

    #20;


    // ==================================
    // TEST 5: Send 3C
    // ==================================
    tx_data  = 8'h3C;
    tx_start = 1;

    #10;
    tx_start = 0;

    wait(rx_done == 1);

    if(rx_data == 8'h3C)
        $display(
            "PASS: Expected 3C, Received %h",
            rx_data
        );
    else
        $display(
            "FAIL: Expected 3C, Received %h",
            rx_data
        );

    wait(rx_done == 0);

    #20;

    $display("--------------------------------");
    $display("SELF-CHECKING TESTBENCH FINISHED");
    $display("--------------------------------");

    $finish;
end


// Waveform generation
initial
begin
    $dumpfile("uart_top_test.vcd");
    $dumpvars(0, uart_top_tb);
end


// Debug monitor
initial
begin
    $monitor(
        "T=%0t | tx_start=%b tx_data=%h busy=%b | serial=%b | rx_data=%h rx_done=%b | TX_state=%0d RX_state=%0d",
        $time,
        tx_start,
        tx_data,
        busy,
        uart_test.serial_line,
        rx_data,
        rx_done,
        uart_test.uart_tx_inst.state,
        uart_test.uart_rx_inst.state
    );
end

endmodule