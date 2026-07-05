module uart_rx(clk, reset, rx , rx_data ,  rx_done);

input clk, reset, rx ;
output reg [7:0] rx_data ;
output reg rx_done;

reg [7:0] shift_reg;
reg [2:0] bit_count;
reg [1:0] baud_counter;
reg [1:0] state, next_state;

parameter IDLE = 2'b00,  START= 2'b01,  RECEIVE = 2'b10,  STOP = 2'b11;

parameter BAUD_MAX  = 2'b11 , BAUD_MID = 2'b10;

always @(posedge clk ) 
begin
    if(reset)
        state <= IDLE;
    else
        state <= next_state;    
end

always @(*) 
begin
    next_state = state;
    case (state)
        IDLE:
            if(rx == 0)
                next_state = START;
        START: 
            if  (rx == 0 && baud_counter == BAUD_MID)
                next_state = RECEIVE;    
            else if (rx==1)    
                next_state = IDLE;
        RECEIVE: 
            if(bit_count == 3'b111 && baud_counter == BAUD_MAX)
              next_state = STOP;
        STOP:
        if(baud_counter == BAUD_MAX) 
            next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) 
begin
    if(reset)
    begin
        shift_reg    <= 8'b0;
        bit_count    <= 3'b0;
        baud_counter <= 2'b0;
        rx_data      <= 8'b0;
        rx_done      <= 1'b0;
    end
    else
    case(state)
        IDLE    : 
            begin
                rx_done      <= 0;
                shift_reg <= 0;
                bit_count <= 0;
                baud_counter <= 0;
            end
        START   : 
        begin 
            rx_done  <= 0;
            if(rx == 0 && baud_counter == BAUD_MID)
                    baud_counter <= 0;
            else if(rx == 0)
                 baud_counter <= baud_counter + 1;
            else 
                baud_counter <= 0;
        end
        RECEIVE :
            begin
                if(baud_counter == BAUD_MAX)
                    begin
                        shift_reg[bit_count] <= rx;
                        bit_count <= bit_count + 1;
                        baud_counter <= 0;
                    end
                else    baud_counter <= baud_counter + 1;    
            end
        STOP:
        begin
            if(baud_counter == BAUD_MAX)
                begin
                    baud_counter <= 0;
                    if(rx == 1)
                    begin
                        rx_data <= shift_reg;
                        rx_done <= 1;
                    end
                    else
                    begin
                        rx_done <= 0;
                    end
                end
            else
                begin
                    baud_counter <= baud_counter + 1;
                end
        end
    endcase    
end
endmodule