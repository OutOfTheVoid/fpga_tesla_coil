module SignalGenerator #(
	parameter INITIAL_PERIOD = 100
) (
	input clock,
	input reset,
	input [31:0] period_in,
	input set_period,
	output out,
	output cycle_end
);
	
	reg [31:0] period;
	reg [31:0] counter;
	
	logic [31:0] period_next;
	logic [31:0] counter_next;
	logic counter_rollover;
	logic half_cycle;
	
	always_comb begin
		counter_rollover = counter >= period;
		half_cycle = counter < {'0, period[31:1]};
		if (reset) begin
			period_next = INITIAL_PERIOD;
			counter_next = 0;
		end else begin
			period_next = set_period ? period_in : period;
			counter_next = counter_rollover ? 0 : counter + 1;
		end
	end
	
	always_ff @(posedge clock) begin
		period <= period_next;
		counter <= counter_next;
	end
	
	assign out = half_cycle;
	assign cycle_end = counter_rollover;
	
endmodule
