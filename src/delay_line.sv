module DelayLine(
	input clock,
	input reset,
	input in,
	input [9:0] phase_0,
	input [9:0] phase_1,
	input [9:0] phase_2,
	input [9:0] phase_3,
	output out_0,
	output out_1,
	output out_2,
	output out_3
);
	
	reg [1023:0] delay_line;
	logic [1023:0] delay_line_next;
	logic read_0;
	logic read_1;
	logic read_2;
	logic read_3;
	
	assign out_0 = read_0;
	assign out_1 = read_1;
	assign out_2 = read_2;
	assign out_3 = read_3;
	
	always_comb begin
		if (reset)
			delay_line_next = 0;
		else begin
			delay_line_next[1023:1] = delay_line[1022:0];
			delay_line_next[0] = in;
		end
		
		read_0 = delay_line[phase_0];
		read_1 = delay_line[phase_1];
		read_2 = delay_line[phase_2];
		read_3 = delay_line[phase_3];
	end
	
	always_ff @(posedge clock) begin
		delay_line <= delay_line_next;
	end
	
endmodule