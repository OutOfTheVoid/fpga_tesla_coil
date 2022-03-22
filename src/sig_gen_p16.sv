module B4To16Decoder (
	input [3:0] in,
	output [15:0] out
);
	
	logic [15:0] outputs;
	
	always_comb begin
		case (in)
			4'b0000: outputs = 16'b0000_0000_0000_0001;
			4'b0001: outputs = 16'b0000_0000_0000_0010;
			4'b0010: outputs = 16'b0000_0000_0000_0100;
			4'b0011: outputs = 16'b0000_0000_0000_1000;
			4'b0100: outputs = 16'b0000_0000_0001_0000;
			4'b0101: outputs = 16'b0000_0000_0010_0000;
			4'b0110: outputs = 16'b0000_0000_0100_0000;
			4'b0111: outputs = 16'b0000_0000_1000_0000;
			4'b1000: outputs = 16'b0000_0001_0000_0000;
			4'b1001: outputs = 16'b0000_0010_0000_0000;
			4'b1010: outputs = 16'b0000_0100_0000_0000;
			4'b1011: outputs = 16'b0000_1000_0000_0000;
			4'b1100: outputs = 16'b0001_0000_0000_0000;
			4'b1101: outputs = 16'b0010_0000_0000_0000;
			4'b1110: outputs = 16'b0100_0000_0000_0000;
			4'b1111: outputs = 16'b1000_0000_0000_0000;
			default: outputs = 16'd0;
		endcase
	end
		
endmodule

module B4To16SigDecoder (
	input [3:0] in,
	input in_high,
	input in_transition,
	output [15:0] out
);

	logic [15:0] outputs;
	
	always_comb begin
		if (in_transition) begin
			case ({in_high, in})
				5'b00000: outputs = 'b0000_0000_0000_0001;
				5'b00001: outputs = 'b0000_0000_0000_0011;
				5'b00010: outputs = 'b0000_0000_0000_0111;
				5'b00011: outputs = 'b0000_0000_0000_1111;
				5'b00100: outputs = 'b0000_0000_0001_1111;
				5'b00101: outputs = 'b0000_0000_0011_1111;
				5'b00110: outputs = 'b0000_0000_0111_1111;
				5'b00111: outputs = 'b0000_0000_1111_1111;
				5'b01000: outputs = 'b0000_0001_1111_1111;
				5'b01001: outputs = 'b0000_0011_1111_1111;
				5'b01010: outputs = 'b0000_0111_1111_1111;
				5'b01011: outputs = 'b0000_1111_1111_1111;
				5'b01100: outputs = 'b0001_1111_1111_1111;
				5'b01101: outputs = 'b0011_1111_1111_1111;
				5'b01110: outputs = 'b0111_1111_1111_1111;
				5'b01111: outputs = 'b1111_1111_1111_1111;
				5'b10000: outputs = 'b1111_1111_1111_1110;
				5'b10001: outputs = 'b1111_1111_1111_1100;
				5'b10010: outputs = 'b1111_1111_1111_1000;
				5'b10011: outputs = 'b1111_1111_1111_0000;
				5'b10100: outputs = 'b1111_1111_1110_0000;
				5'b10101: outputs = 'b1111_1111_1100_0000;
				5'b10110: outputs = 'b1111_1111_1000_0000;
				5'b10111: outputs = 'b1111_1111_0000_0000;
				5'b11000: outputs = 'b1111_1110_0000_0000;
				5'b11001: outputs = 'b1111_1100_0000_0000;
				5'b11010: outputs = 'b1111_1000_0000_0000;
				5'b11011: outputs = 'b1111_0000_0000_0000;
				5'b11100: outputs = 'b1110_0000_0000_0000;
				5'b11101: outputs = 'b1100_0000_0000_0000;
				5'b11110: outputs = 'b1000_0000_0000_0000;
				5'b11111: outputs = 'b0000_0000_0000_0000;
			endcase
		end else begin
			outputs = in_high ? 16'd0 : 16'hFFFF;
		end
	end
		
	assign out = outputs;
	
endmodule

module SignalGenP16 #(
	parameter INITIAL_PERIOD = 1600	
) (
	input reset,
	input p_clock,
	input [31:0] period_in,
	input set_period,
	output [15:0] p_out,
	output [15:0] p_cycle_end
);
	
	reg [31:0] period_in_sticky;
	reg set_period_sticky;
	reg [31:0] period;
	reg [31:0] counter;
	reg sig_start_high;
	
	logic set_period_sticky_next;
	logic [31:0] period_in_sticky_next;
	logic [31:0] period_next;
	logic [31:0] half_period;
	
	logic [31:0] counter_next;
	logic counter_rollover;
	logic [3:0] t_rollover;
	logic [15:0] p_rollover;
	
	logic half_transition;
	logic [3:0] t_half;

	logic sig_start_high_next;
	logic [3:0] sig_transition_t;
	logic sig_transition;
	logic [15:0] signal;

	assign half_period = {1'd0, period[31:1]};
	
	B4To16Decoder t_rollover_decode (
		.in(t_rollover),
		.out(p_rollover)
	);
	assign p_cycle_end = p_rollover;
	
	B4To16SigDecoder signal_decoder(
		.in(sig_transition_t),
		.in_high(sig_start_high),
		.in_transition(sig_transition),
		.out(signal)
	);
	
	always_comb begin
		if (reset) begin
			set_period_sticky_next = 0;
			period_in_sticky_next = INITIAL_PERIOD;
			
			period_next = INITIAL_PERIOD;
			counter_next = 0;
			
			counter_rollover = 0;
			t_rollover = 0;
			t_half = 0;
			
			sig_start_high_next = 1;
			sig_transition = 0;
			sig_transition_t = 0;
		end else begin
			set_period_sticky_next = (set_period_sticky_next & ~counter_rollover) | set_period;
			period_in_sticky_next = set_period ? period_in : period_in_sticky;
			
			counter_rollover = (counter + 15) >= period;
			t_rollover = (period - counter);
			
			half_transition = (counter + 15) >= half_period & sig_start_high;
			t_half = (half_period - counter);
			
			sig_start_high_next = counter_rollover | (sig_start_high_next & ~half_transition);
			
			sig_transition = half_transition | counter_rollover;
			sig_transition_t = counter_rollover ? t_rollover : t_half;
			
			period_next = (set_period_sticky_next & counter_rollover) ? period_in_sticky : period;
			counter_next = counter_rollover ? {28'd0, t_rollover} : counter + 16;
		end
	end
	
	always_ff @(posedge p_clock) begin
		set_period_sticky <= set_period_sticky_next;
		period <= period_next;
		counter <= counter_next;
		sig_start_high <= sig_start_high_next;
	end
	
endmodule
