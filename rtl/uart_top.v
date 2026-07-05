module uart_top(
    clk,
    reset,
    tx_start,
    tx_data,
    rx_data,
    rx_done,
    busy
);

input clk, reset, tx_start;
input [7:0] tx_data;

output [7:0] rx_data;
output rx_done, busy;

wire serial_line;

uart_tx uart_tx_inst (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(serial_line),
    .busy(busy)
);

uart_rx uart_rx_inst (
    .clk(clk),
    .reset(reset),
    .rx(serial_line),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

endmodule