* 6T Bitcell corner characterization
.option scale=1e-6
.temp 25

.include cell6t_pex.sp
* NOTE: adjust .include path below to your real sky130 model file if different
.lib "SKY130_MODEL_PATH" tt
* Duplicate .control blocks below with ff/ss corners as needed

VDD vdd 0 1.8
VBL bl 0 PULSE(0 1.8 0 0.1n 0.1n 2n 4n)
VBR br 0 PULSE(1.8 0 0 0.1n 0.1n 2n 4n)
VWL wl 0 PULSE(0 1.8 1n 0.1n 0.1n 2n 4n)

.control
tran 0.01n 10n
meas tran t_access trig v(wl) val=0.9 rise=1 targ v(bl) val=0.9 rise=1
meas tran i_leak find i(VDD) at=0.5n
meas tran p_dynamic avg power from=1n to=3n
print t_access i_leak p_dynamic
.endc
.end
