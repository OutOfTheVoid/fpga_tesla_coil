module BasicInterrupter #(
	parameter CYCLES_ON = 1,
	parameter CYCLES_OFF = 100000000
) (
	input clock,
	input reset,
	input enable,
	output out
);
	
	reg [31:0] counter;
	reg on;
	
	logic [31:0] counter_next;
	logic on_next;
	
	logic on_timeout;
	logic off_timeout;
	
	always_comb begin
		on_timeout = counter >= CYCLES_ON;
		off_timeout = counter >= CYCLES_OFF;
		if (reset) begin
			counter_next = 0;
			on_next = 0;
		end else begin
			if (enable) begin
				if (on)
					counter_next = on_timeout ? 0 : counter + 1;
				else
					counter_next = off_timeout ? 0 : counter + 1;
				
				if (on & on_timeout)
					on_next = 0;
				else if (~on & off_timeout)
					on_next = 1;
				else
					on_next = on;
			end else begin
				counter_next = 0;
				on_next = 0;
			end
		end
	end
	
	always_ff @(posedge clock) begin
		counter <= counter_next;
		on <= on_next;
	end
	
	assign out = on;
	
endmodule
