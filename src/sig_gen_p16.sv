module B4To16SigDecoder (
	input reset,
	input clock,
	input [3:0] in,
	input in_high,
	input in_transition,
	output [15:0] out
);
	
	reg [3:0] in_registered;
	reg in_high_registered;
	reg in_transition_registered;
	
	reg flip_outputs;
	reg [15:0] transition_outputs;
	reg [15:0] outputs_flipped;
	logic [15:0] outputs;
	logic [15:0] outputs_flipped_next;
	logic [15:0] transition_outputs_next;
	
	always_comb begin
		case (in_registered)
			4'b00000: transition_outputs_next = 'b1111_1111_1111_1111;
			4'b00001: transition_outputs_next = 'b0111_1111_1111_1111;
			4'b00010: transition_outputs_next = 'b0011_1111_1111_1111;
			4'b00011: transition_outputs_next = 'b0001_1111_1111_1111;
			4'b00100: transition_outputs_next = 'b0000_1111_1111_1111;
			4'b00101: transition_outputs_next = 'b0000_0111_1111_1111;
			4'b00110: transition_outputs_next = 'b0000_0011_1111_1111;
			4'b00111: transition_outputs_next = 'b0000_0001_1111_1111;
			4'b01000: transition_outputs_next = 'b0000_0000_1111_1111;
			4'b01001: transition_outputs_next = 'b0000_0000_0111_1111;
			4'b01010: transition_outputs_next = 'b0000_0000_0011_1111;
			4'b01011: transition_outputs_next = 'b0000_0000_0001_1111;
			4'b01100: transition_outputs_next = 'b0000_0000_0000_1111;
			4'b01101: transition_outputs_next = 'b0000_0000_0000_0111;
			4'b01110: transition_outputs_next = 'b0000_0000_0000_0011;
			4'b01111: transition_outputs_next = 'b0000_0000_0000_0001;
		endcase
		
		outputs = in_transition_registered ? transition_outputs : 'h0000;
		
		if (reset) begin
			outputs_flipped_next = flip_outputs ? ~outputs : outputs;
		end else begin
			outputs_flipped_next = '0;
		end
	end
	
	always_ff @(posedge clock) begin
		in_registered <= in;
		in_high_registered <= in_high;
		in_transition_registered <= in_transition;
		flip_outputs <= in_high_registered;
		transition_outputs <= transition_outputs_next;
		outputs_flipped <= outputs_flipped_next;
	end
		
	assign out = {<<{outputs_flipped}};
	
endmodule

module SignalGenP16 #(
	parameter INITIAL_PERIOD = 1600	
) (
	input reset,
	input p_clock,
	input [31:0] period_in,
	input set_period,
	input [9:0] phase2_in,
	input set_phase2,
	output [15:0] p_out,
	output [15:0] p2_out
);
	
	reg [31:0] period_in_sticky;
	reg period_set_sticky;
	reg [31:0] period;
	reg [31:0] counter;
	reg signal_high;
	reg phase2_signal_high;
	
	reg [9:0] phase2_in_sticky;
	reg phase2_set_sticky;
	
	reg [9:0] phase2;
	reg [31:0] phase2_offset;
	
	logic [31:0] period_in_sticky_next;
	logic period_set_sticky_next;
	
	logic [31:0] period_next;
	logic [31:0] counter_next;
	
	logic [9:0] phase2_next;
	logic [9:0] phase2_in_sticky_next;
	logic phase2_set_sticky_next;
	
	logic [31:0] phase2_scaled;
	logic [31:0] phase2_offset_next;
	
	logic signal_high_next;
	logic phase2_signal_high_next;
	
	logic [31:0] half_period;
	logic [31:0] counter_incremented;
	logic [31:0] counter_rollover;
	logic transition;
	logic rollover;
	logic half;
	logic [3:0] t_transition;
	logic [3:0] t_rollover;
	logic [3:0] t_half;
	
	logic [31:0] counter_phase2_raw;
	logic [31:0] counter_phase2;
	logic [31:0] counter_phase2_incremented;
	logic [31:0] counter_phase2_rollover;
	logic phase2_transition;
	logic phase2_rollover;
	logic phase2_half;
	logic [3:0] phase2_t_transition;
	logic [3:0] phase2_t_rollover;
	logic [3:0] phase2_t_half;
	
	B4To16SigDecoder signal_decoder (
		.reset(reset),
		.clock(p_clock),
		.in(t_transition),
		.in_high(signal_high),
		.in_transition(transition),
		.out(p_out)
	);
	
	B4To16SigDecoder phase2_signal_decoder (
		.reset(reset),
		.clock(p_clock),
		.in(phase2_t_transition),
		.in_high(phase2_signal_high),
		.in_transition(phase2_transition),
		.out(p2_out)
	);
	
	always_comb begin
		counter_incremented = counter + 'd16;
		counter_rollover = counter_incremented - period;
			
		half_period = {'0, period[31:1]};
			
		t_rollover = period - counter;
		t_half = half_period - counter;
		t_transition  = signal_high ? t_half : t_rollover;
		
		phase2_scaled = phase2 * half_period;
		phase2_offset_next = {10'd0, phase2_scaled[31:10]};
		
		counter_phase2_raw = counter + phase2_offset;
		counter_phase2 = counter_phase2_raw >= period ? counter_phase2_raw - period : counter_phase2_raw;
		counter_phase2_incremented = counter_phase2 + 'd16;
		counter_phase2_rollover = counter_phase2 - period;
		
		phase2_t_rollover = period - counter_phase2;
		phase2_t_half = half_period - counter_phase2;
		phase2_t_transition  = phase2_signal_high ? phase2_t_half : phase2_t_rollover;
		
		phase2_next = phase2_set_sticky ? phase2_in_sticky : phase2;
		
		if (reset) begin
			rollover = '0;
			half = '0;
			transition = '0;
			
			signal_high_next = '1;
			
			counter_next = '0;
			
			period_in_sticky_next = INITIAL_PERIOD;
			period_set_sticky_next = 0;
			period_next = INITIAL_PERIOD;
			
			phase2_rollover = '0;
			phase2_half = '0;
			phase2_transition = '0;
			
			phase2_signal_high_next = '1;
			
			phase2_in_sticky_next = '0;
			phase2_set_sticky_next = '0;
		end else begin
			rollover = counter_incremented >= period;
			half = counter_incremented >= half_period;
			transition = (half & signal_high) | rollover;
			
			signal_high_next = signal_high ^ transition;
			
			counter_next = (rollover) ? counter_rollover : counter_incremented;
			
			period_in_sticky_next = (set_period) ? period_in : period_in_sticky;
			period_set_sticky_next = (period_set_sticky ^ rollover) | set_period;
			period_next = (rollover & period_set_sticky) ? period_in_sticky : period;
			
			phase2_rollover = counter_phase2_incremented >= period;
			phase2_half = counter_phase2_incremented >= half_period;
			phase2_transition = (phase2_half & phase2_signal_high) | phase2_rollover;
			
			phase2_signal_high_next = phase2_signal_high ^ phase2_transition;
			
			phase2_in_sticky_next = set_phase2 ? phase2_in : phase2_in_sticky;
			phase2_set_sticky_next = phase2_set_sticky | set_phase2;
		end
	end
	
	always_ff @(posedge p_clock) begin
		period_in_sticky <= period_in_sticky_next;
		period_set_sticky <= period_set_sticky_next;
		period <= period_next;
		counter <= counter_next;
		signal_high <= signal_high_next;
		phase2_in_sticky <= phase2_in_sticky_next;
		phase2_set_sticky <= phase2_set_sticky_next;
		phase2 <= phase2_next;
		phase2_offset <= phase2_offset_next;
		phase2_signal_high <= phase2_signal_high_next;
	end
	
endmodule
