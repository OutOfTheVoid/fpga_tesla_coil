module ClockDiv # (
	parameter DIVIDE_BY = 2
) (
	input logic reset,
	input logic clock_in,
	output logic clock_en
);
	
	reg [31:0] counter;
	logic [31:0] counter_inc;
	logic [31:0] counter_next;
	logic counter_rollover;
	
	always_comb begin
		counter_inc = counter + 1;
		counter_rollover = counter >= DIVIDE_BY;
		counter_next = (counter_rollover | reset) ? 0 : counter_inc;
	end
	
	assign clock_en = counter_rollover & ~reset;
	
	always_ff @(posedge clock_in) begin
		counter <= counter_next;
	end
	
endmodule
