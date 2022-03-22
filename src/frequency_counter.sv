module FrequencyCounter (
	input clock,
	input reset,
	input in,
	output [31:0] period_out,
	output period_valid
);
	
	reg [31:0] counter;
	reg [31:0] period;
	reg in_stable;
	reg in_last;
	reg valid_start;
	reg valid_period;
	
	logic [31:0] counter_next;
	logic [31:0] period_next;
	logic valid_start_next;
	logic valid_period_next;
	
	always_comb begin
		if (reset) begin
			counter_next = 0;
			period_next = 0;
			valid_start_next = 0;
			valid_period_next = 0;
		end else begin
			if (~in_last & in_stable) begin
				counter_next      = 0;
				period_next       = counter;
				valid_period_next = valid_start;
				valid_start_next  = 1;
			end else begin
				counter_next      = counter + 1;
				period_next       = period;
				valid_start_next  = valid_start;
				valid_period_next = 0;
			end
		end
	end
	
	always_ff @(posedge clock) begin
		counter      <= counter_next;
		period       <= period_next;
		valid_start  <= valid_start_next;
		valid_period <= valid_period_next;
		in_stable <= in;
		in_last <= in_stable;
	end
	
	assign period_out = period;
	assign period_valid = valid_period;

endmodule
	