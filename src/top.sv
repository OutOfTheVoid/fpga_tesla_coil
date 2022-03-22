module Top (
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
	
endmodule