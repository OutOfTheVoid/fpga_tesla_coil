module UartTx #(
	parameter CLOCK_RATE = 27000000,
	parameter BAUD_RATE = 9600
) (
	input       reset,
	input       clock,
	output      ready,
	input [7:0] data,
	input       send,
	output      tx
);
	
	`define STATE_READY 2'd0
	`define STATE_START 2'd1
	`define STATE_TRANSMIT 2'd2
	`define STATE_STOP 2'd3
	
	logic [1:0] state;
	logic [1:0] state_next;
	
	logic [7:0] tx_data;
	logic [7:0] tx_data_next;
	logic [2:0] tx_bit;
	logic [2:0] tx_bit_next;
	
	logic tx_clock_reset;
	logic tx_clock_en;
	
	logic tx_ready;
	logic tx_begin;
	logic tx_out;
	
	assign ready = tx_ready;
	assign tx = tx_out;
	
	ClockDiv #(
		.DIVIDE_BY(CLOCK_RATE / BAUD_RATE)
	) tx_clock (
		.reset(reset | tx_clock_reset),
		.clock_in(clock),
		.clock_en(tx_clock_en)
	);
	
	always_comb begin
		tx_ready = (state == `STATE_READY) & ~reset;
		tx_begin = tx_ready & send;
		tx_clock_reset = tx_begin;
		
		if (reset) begin
			state_next = `STATE_READY;
			tx_bit_next = '0;
			tx_data_next = '0;
		end else begin
			if (tx_begin) begin
				state_next = `STATE_START;
				tx_bit_next = '0;
				tx_data_next = data;
			end else begin
				tx_data_next = tx_data;
				if (tx_clock_en) begin
					case (state)
						`STATE_START: begin
							state_next = `STATE_TRANSMIT;
							tx_bit_next = '0;
						end
						`STATE_TRANSMIT: begin
							state_next = (tx_bit == 3'd7) ? `STATE_STOP : `STATE_TRANSMIT;
							tx_bit_next = tx_bit + 1;
						end
						default: begin
							state_next = `STATE_READY;
							tx_bit_next = '0;
						end
					endcase
				end else begin
					state_next = state;
					tx_bit_next = tx_bit;
				end
			end
		end
		
		case (state)
			`STATE_START: tx_out = '1;
			`STATE_TRANSMIT: tx_out = ~tx_data_next[tx_bit];
			default: tx_out = '0;
		endcase
	end
	
	always_ff @(posedge clock) begin
		state <= state_next;
		tx_data <= tx_data_next;
		tx_bit <= tx_bit_next;
	end
	
endmodule

module UartRx #(
	parameter CLOCK_RATE = 27000000,
	parameter BAUD_RATE = 9600,
	parameter PERCENT_PHASE_DELAY = 50
) (
	input reset,
	input clock,
	output receive,
	output [7:0] data,
	input rx
);
	
	`define STATE_WAIT 2'd0
	`define STATE_START 2'd1
	`define STATE_RECEIVE 2'd2
	`define STATE_STOP 2'd3
	
	logic rx_stable;
	
	logic [1:0] state;
	logic [1:0] state_next;
	
	logic [7:0] rx_data;
	logic [7:0] rx_data_next;
	logic [2:0] rx_bit;
	logic [2:0] rx_bit_next;
	
	logic rx_clock_reset;
	logic rx_clock_reset_next;
	logic rx_clock_en;
	
	logic delay_timer_start;
	logic delay_timer_alarm;
	logic delay_timer_reset;
	
	logic rx_finish;
	
	ClockDiv #(
		.DIVIDE_BY(CLOCK_RATE / BAUD_RATE)
	) tx_clock (
		.reset(rx_clock_reset | reset),
		.clock_in(clock),
		.clock_en(rx_clock_en)
	);
	
	Timer phase_delay_timer (
		.reset(reset | delay_timer_reset),
		.clock(clock),
		.count_en('1),
		.period_in(((CLOCK_RATE / BAUD_RATE) * PERCENT_PHASE_DELAY) / 100),
		.period_set('1),
		.start(delay_timer_start),
		.alarm(delay_timer_alarm),
		.acknowledge('0)
	);
	
	assign data = rx_data;
	assign receive = rx_finish;
	
	always_comb begin
		if (reset) begin
			state_next = `STATE_WAIT;
			rx_data_next = 8'd0;
			rx_clock_reset_next = '1;
			delay_timer_reset = '1;
			delay_timer_start = '0;
			rx_bit_next = 0;
		end else begin
			case (state)
				`STATE_WAIT: begin
					rx_clock_reset_next = '1;
					delay_timer_reset = '1;
					delay_timer_start = '0;
					rx_data_next = 8'd0;
					rx_bit_next = 0;
					state_next = rx_stable ? `STATE_START : `STATE_WAIT;
				end
				`STATE_START: begin
					rx_clock_reset_next = ~delay_timer_alarm;
					delay_timer_reset = '0;
					delay_timer_start = '1;
					rx_data_next = 8'd0;
					rx_bit_next = 0;
					state_next = delay_timer_alarm ? `STATE_RECEIVE : `STATE_START;
				end
				`STATE_RECEIVE: begin
					delay_timer_reset = '1;
					delay_timer_start = '0;
					rx_clock_reset_next = '0;
					rx_data_next = rx_data | ({7'd0, (~rx_stable & rx_clock_en)} << rx_bit);
					rx_bit_next = rx_clock_en ? (rx_bit + 1) : rx_bit;
					state_next = (rx_clock_en & (rx_bit == 7)) ? `STATE_STOP : `STATE_RECEIVE;
				end
				`STATE_STOP: begin
					delay_timer_reset = '1;
					delay_timer_start = '0;
					rx_clock_reset_next = '1;
					rx_data_next = rx_data;
					rx_bit_next = 0;
					state_next = (~rx_stable) ? `STATE_WAIT : `STATE_STOP;
				end
			endcase
		end
		
		rx_finish = (state == `STATE_STOP) & ~rx_stable;
	end
	
	always_ff @(posedge clock) begin
		rx_clock_reset <= rx_clock_reset_next;
		rx_bit <= rx_bit_next;
		rx_data <= rx_data_next;
		state <= state_next;
		rx_stable <= rx;
	end
	
endmodule

module UartFIFO #(
	parameter LENGTH = 16
) (
	input reset,
	input clock,
	
	output is_full,
	input insert,
	input [7:0] data_in,
	
	output is_empty,
	input remove,
	output [7:0] data_out
);
	
	logic [31:0] write_index;
	logic [31:0] write_index_inc;
	logic write_index_wrap;
	logic [31:0] write_index_inc_wrapped;
	logic [31:0] write_index_next;
	
	logic [31:0] read_index;
	logic [31:0] read_index_inc;
	logic read_index_wrap;
	logic [31:0] read_index_inc_wrapped;
	logic [31:0] read_index_next;

	logic empty;
	logic full;
	logic do_insert;
	logic do_remove;
	
	logic [7:0] fifo [LENGTH-1:0];
	
	logic [7:0] read_data;
		
	assign is_empty = empty;
	assign is_full = full;
	assign data_out = read_data;
	
	always_comb begin
		
		write_index_inc = write_index + 1;
		write_index_wrap = write_index_inc == LENGTH;
		write_index_inc_wrapped = write_index_wrap ? 0 : write_index_inc;
		
		read_index_inc = read_index + 1;
		read_index_wrap = read_index_inc == LENGTH;
		read_index_inc_wrapped = read_index_wrap  ? 0 : read_index_inc;
		
		empty = write_index == read_index;
		full = write_index_inc_wrapped == read_index;
		
		do_remove = remove & ~empty;
		do_insert = insert & ~full;
		
		read_index_next = do_remove ? read_index_inc_wrapped : read_index;
		write_index_next = do_insert ? write_index_inc_wrapped : write_index;
		
		read_data = fifo[read_index];
		
	end

	always_ff @(posedge clock) begin
		
		if (reset) begin
			read_index <= 0;
			write_index <= 0;
		end else begin
			read_index <= read_index_next;
			write_index <= write_index_next;
			if (do_insert) begin
				fifo[write_index] <= data_in;
			end
		end
		
	end
	
endmodule


