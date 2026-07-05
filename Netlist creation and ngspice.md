# Netlist Descriptions

### 1. 6T SRAM Bitcell Operation
This netlist implements the core cross-coupled inverter pair with two NMOS access transistors, verifying that the cell holds a stable, non-oscillating value at Q and QB under DC bias. It confirms the latch reaches one of its two intended stable states rather than settling at an invalid mid-rail voltage.

'''
* 6T SRAM Bitcell - Generic Models
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VBL  BL  0 DC 1.8
VBLB BLB 0 DC 1.8
VWL  WL  0 DC 0

M1 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M3 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M5 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M6 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

.ic V(Q)=1.8 V(QB)=0

.control
tran 10p 10n
plot v(Q) v(QB) v(WL)
.endc
.end

'''

### 2. Read/Write Stability
This netlist runs the same bitcell under two bias conditions — wordline low (hold) and wordline high with bitlines pre-charged (read) — to compare how much the stored value shifts under access. It's used to check whether the cell's sizing keeps Q and QB safely on their correct side of the switching threshold during a read.
'''
* Read/Write Stability - WL pulsed
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VWL WL 0 PULSE(0 1.8 2n 0.1n 0.1n 3n 8n)
VBL  BL  0 DC 1.8
VBLB BLB 0 DC 1.8

M1 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M3 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M5 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M6 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

.ic V(Q)=1.8 V(QB)=0

.control
tran 10p 20n
plot v(Q) v(QB) v(WL) v(BL) v(BLB)
.endc
.end
'''


### 3. Butterfly Curve
This netlist sweeps the input of one inverter in the cross-coupled pair across the supply range while measuring the other inverter's output, generating the two voltage transfer curves needed to construct the butterfly plot. The resulting curve pair is used to visually and numerically extract the static noise margin of the cell.

'''
* Butterfly Curve - two inverters, DC sweep
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VQ  Qf 0 DC 0
VQB QBf 0 DC 0

M1 QB_int Qf VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 QB_int Qf 0   0   NMOS_GEN W=0.64u L=0.15u
M3 Q_int QBf VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 Q_int QBf 0   0   NMOS_GEN W=0.64u L=0.15u

.control
dc VQ 0 1.8 0.01
plot QB_int
dc VQB 0 1.8 0.01
plot Q_int
.endc
.end
'''


### 4. Read Disturb
This netlist pre-charges both bitlines to VDD, asserts the wordline, and monitors the internal storage node holding a "0" to see how far it gets pulled toward VDD before the wordline is released. It's used to determine whether the read access alone is capable of flipping the cell without any intentional write occurring.

'''
* Read Disturb - Q holds 0, check bump when WL pulses
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VBL  BL  0 DC 1.8
VBLB BLB 0 DC 1.8
VWL  WL  0 PULSE(0 1.8 1n 0.05n 0.05n 5n 10n)

M1 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M3 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M5 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M6 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

.ic V(Q)=0 V(QB)=1.8

.control
tran 5p 15n
plot v(Q) v(WL)
meas tran vbump MAX v(Q) FROM=1n TO=6n
.endc
.end
'''
### 5. Write Margin
This netlist drives one bitline to 0V and the other to VDD, asserts the wordline, and tracks how quickly and completely the internal nodes flip to match the forced bitline values. It's used to find the minimum bitline drive condition (write trip voltage) at which the cell reliably changes state.

''' 
* Write Margin - force BL/BLB opposite to stored value
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VWL  WL  0 PULSE(0 1.8 1n 0.05n 0.05n 8n 12n)
VBL  BL  0 DC 0
VBLB BLB 0 DC 1.8

M1 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M3 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M5 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M6 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

.ic V(Q)=1.8 V(QB)=0

.control
tran 5p 12n
plot v(Q) v(QB) v(WL)
meas tran t_flip WHEN v(Q)=0.9 RISE=0 FALL=1
.endc
.end
'''

### 6. Precharge Circuit
This netlist models the PMOS precharge and equalization transistors driving both bitlines toward VDD from an arbitrary starting voltage. It verifies that both bitlines reach the same final voltage within the intended precharge window before any wordline activity begins.

'''
* Precharge circuit - PMOS precharge + equalizer
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VPRE PRE_b 0 PULSE(1.8 0 1n 0.1n 0.1n 3n 10n)

M1 BL  PRE_b VDD  VDD PMOS_GEN W=0.84u L=0.15u
M2 BLB PRE_b VDD  VDD PMOS_GEN W=0.84u L=0.15u
M3 BL  PRE_b BLB  VDD PMOS_GEN W=0.84u L=0.15u

CBL  BL  0 20f
CBLB BLB 0 20f

.ic V(BL)=0 V(BLB)=0.5

.control
tran 10p 10n
plot v(BL) v(BLB) v(PRE_b)
.endc
.end
'''
### 7. Wordline Control
This netlist isolates the wordline driver stage, applying an input pulse and measuring the propagation delay and rise/fall time at the far end of a wordline modeled with representative RC parasitics. It's used to confirm the driver is strong enough to fully assert the wordline within the allotted pulse width.

'''
* Wordline driver - two-stage inverter buffer + RC line
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VROWSEL ROWSEL 0 PULSE(0 1.8 1n 0.1n 0.1n 5n 10n)

M1 n1 ROWSEL VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 n1 ROWSEL 0   0   NMOS_GEN W=0.42u L=0.15u
M3 WL n1     VDD VDD PMOS_GEN W=1.0u  L=0.15u
M4 WL n1     0   0   NMOS_GEN W=1.0u  L=0.15u

RWL WL WL_far 500
CWL WL_far 0 30f

.control
tran 10p 10n
plot v(ROWSEL) v(WL) v(WL_far)
.endc
.end
'''
### 8. Bitline Behaviour
This netlist connects a single cell to a bitline pair modeled with lumped capacitance, then triggers a read access to observe the resulting small-signal voltage difference that develops between BL and BLB. It's used to quantify how much differential signal is actually available for the sense amplifier to detect.

'''
* Bitline behaviour - precharge then discharge via bitcell
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VPRE_b PRE_b 0 PULSE(1.8 0 1n 0.1n 0.1n 2n 20n)
VWL    WL    0 PULSE(0 1.8 4n 0.1n 0.1n 8n 20n)

M1 BL PRE_b VDD VDD PMOS_GEN W=0.84u L=0.15u
M2 BLB PRE_b VDD VDD PMOS_GEN W=0.84u L=0.15u

M3 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M5 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M6 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M7 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M8 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

CBL  BL  0 20f
CBLB BLB 0 20f

.ic V(Q)=0 V(QB)=1.8

.control
tran 10p 20n
plot v(BL) v(BLB) v(WL) v(PRE_b)
.endc
.end
'''
### 9. Sense Amplifier Concept
This netlist applies a small pre-set voltage difference to the sense amplifier's two input nodes, then fires the sense-enable signal to observe how quickly and cleanly that difference is amplified to a full-swing output. It's used to check the amplifier's minimum detectable input offset and its regeneration speed.

'''
* Sense Amplifier - simplified latch-type
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VSAE SAE 0 PULSE(0 1.8 5n 0.1n 0.1n 5n 10n)
VBL  BL  0 DC 1.7
VBLB BLB 0 DC 1.8

M1 OUT  OUTB VDD VDD  PMOS_GEN W=0.42u L=0.15u
M2 OUT  OUTB SAEn 0   NMOS_GEN W=0.64u L=0.15u
M3 OUTB OUT  VDD VDD  PMOS_GEN W=0.42u L=0.15u
M4 OUTB OUT  SAEn 0   NMOS_GEN W=0.64u L=0.15u
M5 OUT  SAE BL  0     NMOS_GEN W=0.42u L=0.15u
M6 OUTB SAE BLB 0     NMOS_GEN W=0.42u L=0.15u
M7 SAEn SAE 0 0       NMOS_GEN W=0.84u L=0.15u

.ic V(OUT)=0.9 V(OUTB)=0.9

.control
tran 10p 15n
plot v(BL) v(BLB) v(OUT) v(OUTB) v(SAE)
.endc
.end
'''
### 10. Write Driver Concept
This netlist exercises the write driver with a toggling data input and write-enable signal, measuring how quickly and how fully it drives the two bitlines to opposite rail voltages. It's used to confirm the driver is strong enough to win the write contest against the cell's internal pull-up transistors.

'''
* Write Driver - differential driver based on Din
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VDIN DIN 0 PULSE(0 1.8 2n 0.1n 0.1n 5n 10n)

M1 DINB DIN VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 DINB DIN 0   0   NMOS_GEN W=0.42u L=0.15u

M3 BL  DIN  VDD VDD PMOS_GEN W=0.84u L=0.15u
M4 BL  DIN  0   0   NMOS_GEN W=0.84u L=0.15u
M5 BLB DINB VDD VDD PMOS_GEN W=0.84u L=0.15u
M6 BLB DINB 0   0   NMOS_GEN W=0.84u L=0.15u

CBL  BL  0 20f
CBLB BLB 0 20f

.control
tran 10p 12n
plot v(DIN) v(BL) v(BLB)
.endc
.end
'''
### 11. Row/Column Decoder Basics
This netlist applies all combinations of address bits to a small decoder block and verifies that exactly one output line goes high for each unique input combination, with all others remaining low. It's used to confirm correct decode logic and to measure address-to-wordline propagation delay.
'''
* Basic 2:4 row decoder - NAND2 + inverter (Y0 only)
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)

VDD VDD 0 DC 1.8
VA0 A0 0 PULSE(0 1.8 1n 0.1n 0.1n 4n 8n)
VA1 A1 0 PULSE(0 1.8 1n 0.1n 0.1n 8n 16n)

M1 nand_out A0  VDD  VDD  PMOS_GEN W=0.42u L=0.15u
M2 nand_out A1  VDD  VDD  PMOS_GEN W=0.42u L=0.15u
M3 nand_out A0  n_int 0   NMOS_GEN W=0.42u L=0.15u
M4 n_int    A1  0    0    NMOS_GEN W=0.42u L=0.15u

M5 Y0 nand_out VDD VDD PMOS_GEN W=0.42u L=0.15u
M6 Y0 nand_out 0   0   NMOS_GEN W=0.42u L=0.15u

.control
tran 10p 16n
plot v(A0) v(A1) v(Y0)
.endc
.end
'''
### 12. SRAM Timing Sequence
This netlist stitches together precharge, wordline assertion, sense-enable, and write-enable signals on a shared timeline to model one full read cycle followed by one full write cycle. It's used to verify that the relative timing between all control signals matches the intended sequence with no overlaps or race conditions.
'''
* SRAM Timing Sequence - control signal relationships only
VDD VDD 0 DC 1.8
VCLK CLK 0 PULSE(0 1.8 0 0.1n 0.1n 5n 10n)
VPRE_b PRE_b 0 PULSE(1.8 0 0 0.1n 0.1n 1n 10n)
VWL WL 0 PULSE(0 1.8 2n 0.1n 0.1n 4n 10n)
VSAE SAE 0 PULSE(0 1.8 6n 0.1n 0.1n 2n 10n)

.control
tran 10p 10n
plot v(CLK) v(PRE_b) v(WL) v(SAE)
.endc
.end
'''
---
