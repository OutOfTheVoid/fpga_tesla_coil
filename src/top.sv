/*module Top (
	input clock,
	input reset_n,
	input fire_button,
	input antenna,
	output enable_n,
	output signal,
	output [5:0] leds
);
	
	logic pll_clock;
	logic system_clock;
	logic enable;
	assign enable_n = ~enable;
	
	logic reset;
	assign reset = ~reset_n;
	
	MasterPLL pll(
		.clkout(pll_clock), //output clkout
		.clkin(clock) //input clkin
	);
	
	ClockDiv4 clock_div(
		.clkout(system_clock), //output clkout
		.hclkin(pll_clock), //input hclkin
		.resetn(reset_n) //input resetn
	);
	
	logic gen_signal;
	logic [31:0] fc_period;
	logic fc_period_valid;
	
	FrequencyCounter freq_counter (
		.clock(system_clock),
		.reset(reset | ~interrupter_signal),
		.in(antenna),
		.period_out(fc_period),
		.period_valid(fc_period_valid)
	);
	
	logic period_set;
	assign period_set = fc_period_valid & interrupter_signal;
	
	SignalGenerator #(.INITIAL_PERIOD(56)) sig_gen (
		.clock(system_clock),
		.reset(reset | ~interrupter_signal),
		.period_in(fc_period),
		.set_period(period_set),
		.out(gen_signal)
	);
	
	logic interrupter_signal;
	
	BasicInterrupter #(.CYCLES_ON(20000), .CYCLES_OFF(2700000)) interrupter (
		.clock(clock),
		.reset(reset),
		.enable(~fire_button),
		.out(interrupter_signal)
	);
	
	assign signal = gen_signal;
	assign enable = interrupter_signal;
	assign leds[5:0] = {~interrupter_signal, fire_button, gen_signal, '0, '0, '0};
	
endmodule*/

module Top (
	input clock,
	input reset_n,
	output clock_out,
	output gen_out,
	output gen2_out
);
	
	logic reset;
	logic system_clock;
	logic signal;
	logic signal2;
	
	assign reset = ~reset_n;
	assign clock_out = clock;
	assign gen_out = signal;
	assign gen2_out = signal2;
	
	ClockDiv8 clock_divider (
		.resetn(reset_n),
		.hclkin(clock),
		.clkout(system_clock)
	);
	
	logic [15:0] signal_p16;
	logic [15:0] signal2_p16;
	
	SignalGenP16 #(.INITIAL_PERIOD(70)) signal_generator (
		.reset(reset),
		.p_clock(system_clock),
		.period_in('d70),
		.set_period('0),
		.p_out(signal_p16),
		.p2_out(signal2_p16),
		.phase2_in('d1023),
		.set_phase2('1)
	);

	Output16Serial signal_serializer (
		.reset(reset),
		.clock_8(clock),
		.clock(system_clock),
		.data(signal_p16),
		.out(signal)
	);
	
	Output16Serial signal2_serializer (
		.reset(reset),
		.clock_8(clock),
		.clock(system_clock),
		.data(signal2_p16),
		.out(signal2)
	);
	
endmodule
