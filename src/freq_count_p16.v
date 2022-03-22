module EdgeDetector16P (
	input start_level,
	input [15:0] in_p16,
	output edge_detect,
	output [3:0] edge_t
);
	
	logic is_edge;
	logic t_edge;
	
	always_comb begin
		casez ({start_level, in_p16})	
			17'b0_???????????????1: begin is_edge = 1; t_edge = 0; end
			17'b0_??????????????10: begin is_edge = 1; t_edge = 1; end
			17'b0_?????????????100: begin is_edge = 1; t_edge = 2; end
			17'b0_????????????1000: begin is_edge = 1; t_edge = 3; end
			17'b0_???????????10000: begin is_edge = 1; t_edge = 4; end
			17'b0_??????????100000: begin is_edge = 1; t_edge = 5; end
			17'b0_?????????1000000: begin is_edge = 1; t_edge = 6; end
			17'b0_????????10000000: begin is_edge = 1; t_edge = 7; end
			17'b0_???????100000000: begin is_edge = 1; t_edge = 8; end
			17'b0_??????1000000000: begin is_edge = 1; t_edge = 9; end
			17'b0_?????10000000000: begin is_edge = 1; t_edge = 10; end
			17'b0_????100000000000: begin is_edge = 1; t_edge = 11; end
			17'b0_???1000000000000: begin is_edge = 1; t_edge = 12; end
			17'b0_??10000000000000: begin is_edge = 1; t_edge = 13; end
			17'b0_?100000000000000: begin is_edge = 1; t_edge = 14; end
			17'b0_1000000000000000: begin is_edge = 1; t_edge = 15; end
			17'b1_???????????????0: begin is_edge = 1; t_edge = 0; end
			17'b1_??????????????01: begin is_edge = 1; t_edge = 1; end
			17'b1_?????????????011: begin is_edge = 1; t_edge = 2; end
			17'b1_????????????0111: begin is_edge = 1; t_edge = 3; end
			17'b1_???????????01111: begin is_edge = 1; t_edge = 4; end
			17'b1_??????????011111: begin is_edge = 1; t_edge = 5; end
			17'b1_?????????0111111: begin is_edge = 1; t_edge = 6; end
			17'b1_????????01111111: begin is_edge = 1; t_edge = 7; end
			17'b1_???????011111111: begin is_edge = 1; t_edge = 8; end
			17'b1_??????0111111111: begin is_edge = 1; t_edge = 9; end
			17'b1_?????01111111111: begin is_edge = 1; t_edge = 10; end
			17'b1_????011111111111: begin is_edge = 1; t_edge = 11; end
			17'b1_???0111111111111: begin is_edge = 1; t_edge = 12; end
			17'b1_??01111111111111: begin is_edge = 1; t_edge = 13; end
			17'b1_?011111111111111: begin is_edge = 1; t_edge = 14; end
			17'b1_0111111111111111: begin is_edge = 1; t_edge = 15; end
			17'b0_0000000000000000: begin is_edge = 0; t_edge = 0; end
			17'b1_1111111111111111: begin is_edge = 0; t_edge = 0; end
			default: begin is_edge = 0; t_edge = 0; end
		endcase
	end
	
endmodule


module FreqCounter16P (
	input clock,
	input reset,
	input [15:0] in_p16,
	output period_valid,
	output [31:0] period
);
	
	reg last_edge;
	reg [31:0] counter;
	reg [31:0] period;
	reg valid_start;
	reg valid_period;
	
	logic last_edge_next;
	logic [31:0] counter_next;
	logic [31:0] period_next;
	logic valid_start_next;
	logic valid_period_next;
	
	logic [3:0] edge_t;
	logic is_edge;
	
	EdgeDetector16P edge_detector (
		.start_level(last_edge),
		.in_p16(in_p16),
		.edge_detect(is_edge),
		.edge_t(edge_t)
	);
	
	always_comb begin
		if (reset) begin
			last_edge_next = 0;
			counter_next = 0;
			period_next = 0;
			valid_start_next = 0;
			valid_period_next = 0;
		end else begin
			if (is_edge) begin
				last_edge_next = ~last_edge;
				if (~last_edge) begin
					counter_next      = 15 - edge_t;
					period_next       = counter + edge_t;
					valid_period_next = valid_start;
					valid_start_next  = 1;
				end else begin
					counter_next      = counter + 16;
					period_next       = period;
					valid_start_next  = valid_start;
					valid_period_next = 0;
				end
			end else begin
				last_edge_next = last_edge;
				counter_next      = counter + 16;
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
		last_edge <= last_edge_next;
	end
	
endmodule
