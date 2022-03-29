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
				5'b00000: outputs = 'b1111_1111_1111_1111;
				5'b00001: outputs = 'b0111_1111_1111_1111;
				5'b00010: outputs = 'b0011_1111_1111_1111;
				5'b00011: outputs = 'b0001_1111_1111_1111;
				5'b00100: outputs = 'b0000_1111_1111_1111;
				5'b00101: outputs = 'b0000_0111_1111_1111;
				5'b00110: outputs = 'b0000_0011_1111_1111;
				5'b00111: outputs = 'b0000_0001_1111_1111;
				5'b01000: outputs = 'b0000_0000_1111_1111;
				5'b01001: outputs = 'b0000_0000_0111_1111;
				5'b01010: outputs = 'b0000_0000_0011_1111;
				5'b01011: outputs = 'b0000_0000_0001_1111;
				5'b01100: outputs = 'b0000_0000_0000_1111;
				5'b01101: outputs = 'b0000_0000_0000_0111;
				5'b01110: outputs = 'b0000_0000_0000_0011;
				5'b01111: outputs = 'b0000_0000_0000_0001;
				5'b10000: outputs = 'b0000_0000_0000_0000;
				5'b10001: outputs = 'b1000_0000_0000_0000;
				5'b10010: outputs = 'b1100_0000_0000_0000;
				5'b10011: outputs = 'b1110_0000_0000_0000;
				5'b10100: outputs = 'b1111_0000_0000_0000;
				5'b10101: outputs = 'b1111_1000_0000_0000;
				5'b10110: outputs = 'b1111_1100_0000_0000;
				5'b10111: outputs = 'b1111_1110_0000_0000;
				5'b11000: outputs = 'b1111_1111_0000_0000;
				5'b11001: outputs = 'b1111_1111_1000_0000;
				5'b11010: outputs = 'b1111_1111_1100_0000;
				5'b11011: outputs = 'b1111_1111_1110_0000;
				5'b11100: outputs = 'b1111_1111_1111_0000;
				5'b11101: outputs = 'b1111_1111_1111_1000;
				5'b11110: outputs = 'b1111_1111_1111_1100;
				5'b11111: outputs = 'b1111_1111_1111_1110;
			endcase
		end else begin
			outputs = in_high ? 16'hFFFF : 16'h0000;
		end
	end
		
	assign out = {<<{outputs}};
	
endmodule

module SignalGenP16 #(
	parameter INITIAL_PERIOD = 1600	
) (
	input reset,
	input p_clock,
	input [31:0] period_in,
	input set_period,
	output [15:0] p_out
);
	
	reg [31:0] period_in_sticky;
	reg period_set_sticky;
	reg [31:0] period;
	reg [31:0] counter;
	reg signal_high;
	
	logic [31:0] period_in_sticky_next;
	logic period_set_sticky_next;
	
	logic [31:0] period_next;
	logic [31:0] counter_next;
	
	logic signal_high_next;
	
  	logic [31:0] half_period;
	logic [31:0] counter_incremented;
	logic [31:0] counter_rollover;
	logic transition;
	logic rollover;
	logic half;
	logic [3:0] t_transition;
	logic [3:0] t_rollover;
	logic [3:0] t_half;
	
	assign internal_transition = transition;
	assign internal_t_transition = t_transition;
	
	B4To16SigDecoder signal_decoder(
      .in(t_transition),
      .in_high(signal_high),
      .in_transition(transition),
      .out(p_out)
    );
	
	always_comb begin
		counter_incremented = counter + 'd16;
		counter_rollover = counter_incremented - period;
      	
      	half_period = {'0, period[31:1]};
      	
      	t_rollover = period - counter;
      	t_half = half_period - counter;
      	t_transition  = signal_high ? t_half : t_rollover;
		
		if (reset) begin
			rollover = '0;
			half = '0;
			transition = '0;
			
			signal_high_next = '1;
			
			counter_next = '0;
          	
			period_in_sticky_next = INITIAL_PERIOD;
			period_set_sticky_next = 0;
			period_next = INITIAL_PERIOD;
		end else begin
			rollover = counter_incremented >= period;
			half = counter_incremented >= half_period;
			transition = (half & signal_high) | rollover;
			
          	signal_high_next = signal_high ^ transition;
          	
			counter_next = (rollover) ? counter_rollover : counter_incremented;
			
			period_in_sticky_next = (set_period) ? period_in : period_in_sticky;
			period_set_sticky_next = (period_set_sticky ^ rollover) | set_period;
			period_next = (rollover & period_set_sticky) ? period_in_sticky : period;
		end
	end
	
	always_ff @(posedge p_clock) begin
		period_in_sticky <= period_in_sticky_next;
      	period_set_sticky <= period_set_sticky_next;
      	period <= period_next;
      	counter <= counter_next;
      	signal_high <= signal_high_next;
	end
	
endmodule
