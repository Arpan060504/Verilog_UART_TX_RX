module uart_tx(clk , reset , tx_start , tx_data , tx , busy);

input   clk , reset , tx_start ;
input [7:0] tx_data;
output reg tx , busy;

reg [7:0]  shift_reg ;
reg [2:0] bit_count;
reg [1:0] baud_counter ;
reg [1:0] state , next_state;

parameter IDLE = 2'b00 , START = 2'b01 , SEND_BIT = 2'b10 , STOP = 2'b11 , BAUD_MAX = 2'b11;

always @(posedge clk ) // only for state change
begin
    if(reset)
        state <= IDLE;
    else
        state <= next_state;
end

always @(posedge clk) 
begin
    if(reset)
        begin
            busy <= 0 ;
            tx <= 1;
            bit_count <= 0;
            baud_counter <= 0;
            shift_reg <= 0;
        end
    else
    case(state)
        IDLE      :
            begin 
                tx <= 1;
                busy  <= 0;
                baud_counter <= 0;
            end
        START:
        begin
            bit_count <= 0;
            shift_reg <= tx_data;
            tx <= 0;
            busy <= 1;

            if(baud_counter == BAUD_MAX)
                baud_counter <= 0;
            else
                baud_counter <= baud_counter + 1;
        end
        SEND_BIT:
        begin
            busy <= 1;
            // Keep current data bit on TX
            tx <= shift_reg[0];
            if(baud_counter == BAUD_MAX)
            begin
                baud_counter <= 0;
                if(bit_count != 3'b111)
                begin
                    shift_reg <= shift_reg >> 1;
                    bit_count <= bit_count + 1;
                end
            end
            else
            begin
                baud_counter <= baud_counter + 1;
            end
        end
        STOP:
        begin 
            tx <= 1;
            busy <= 1;
            bit_count <= 0;
            shift_reg <= 0;
            if(baud_counter == BAUD_MAX)
                baud_counter <= 0;
            else
                baud_counter <= baud_counter + 1;
        end
        default :
            begin
                tx <= 1;
            end
    endcase    
end

always@(*)
begin
    next_state = state;
    case(state)
        IDLE      : 
            begin
                if(tx_start)
                    next_state = START;
            end
        START:
        begin
            if(baud_counter == BAUD_MAX)
                next_state = SEND_BIT;
        end
        SEND_BIT  : 
            begin
                if(bit_count == 3'b111 && baud_counter == BAUD_MAX ) // baud_counter == BAUD_MAX  confirms bit has been transmitted
                    next_state = STOP;
            end
        STOP:
        begin
            if(baud_counter == BAUD_MAX)
                next_state = IDLE;
        end
        default   :   next_state = IDLE;
        endcase
end

endmodule