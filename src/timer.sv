module Timer (
	input reset,
	input clock,
	input count_en,
	input [31:0] period_in,
	input period_set,
	input start,
	input acknowledge,
	output alarm
);
	
	`define STATE_READY 2'd0
	`define STATE_RUNNING 2'd1
	`define STATE_ALARM 2'd2
	
	logic [1:0] state;
	logic [1:0] state_next;
	
	logic [31:0] period;
	logic [31:0] period_next;
	
	logic [31:0] counter;
	logic [31:0] counter_inc;
	logic [31:0] counter_next;
	logic timer_finish;
	
	always_comb begin
		counter_inc = counter + 32'd1;
		timer_finish = counter_inc >= period;
		period_next = period_set ? period_in : period;
		
		if (reset) begin
			state_next = start ? `STATE_RUNNING : `STATE_READY;
			counter_next = 32'd0;
		end else begin
			case (state)
				`STATE_READY: begin
					state_next = start ? `STATE_RUNNING : `STATE_READY;
					counter_next = 32'd0;
				end
				`STATE_RUNNING: begin
					state_next = (count_en & timer_finish) ? `STATE_ALARM : `STATE_RUNNING;
					counter_next = (count_en & ~timer_finish) ? counter_inc : counter;
				end
				default: begin
					state_next = acknowledge ? (start ? `STATE_RUNNING : `STATE_READY) : `STATE_ALARM;
					counter_next = 32'd0;
				end
			endcase
		end
	end
	
	assign alarm = state == `STATE_ALARM;
	
	always_ff @(posedge clock) begin
		state <= state_next;
		period <= period_next;
		counter <= counter_next;
	end
	
endmodule
