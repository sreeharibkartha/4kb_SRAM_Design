# READ AND WRITE STABILITY
1. A 6T SRAM cell is a tiny memory circuit made from six transistors that stores a single bit (a 0 or a 1) as long as power is supplied to it.

2. Inside the cell, two inverters (each an inverter is 2 transistors, so 4 total) are "cross-coupled" — the output of one feeds the input of the other, and vice versa. This loop latches onto whichever state it's in and holds it stubbornly, which is how the cell remembers data.

3. The two storage points in this loop are called Q and QB. They always hold opposite values — if Q is 1, QB is 0, and if Q is 0, QB is 1. Whichever value Q holds is considered the "stored bit."

4. The remaining two transistors are access transistors. Their job is to connect (or disconnect) the internal nodes Q and QB to the outside world so data can be read out or written in.

5. The wordline (WL) is the control signal that turns the access transistors on. When WL is high, the cell is "opened up" for reading or writing; when WL is low, the cell is sealed off and just quietly holds its value.

6. The bitlines (BL and BLB) are the wires that carry data into or out of the cell. BL connects to Q and BLB connects to QB through the access transistors. Before any operation, both bitlines are "precharged" to a high voltage.

7. To read the cell: WL is raised, connecting Q and QB to BL and BLB. Whichever internal node holds a 0 starts pulling its bitline slightly down, while the other bitline stays high. Sensing circuitry detects this small voltage difference to determine the stored bit.

8. Read operations must be gentle — the small pull-down on the bitline shouldn't be strong enough to flip Q or QB. If the access transistor pulls too hard on an internal node, it can accidentally overwrite the stored bit, which is called a "read disturb," and a good design avoids this.

9. To write the cell: WL is raised again, but this time the write driver circuitry forcefully drives one bitline low (say BL, to write a 0 on Q) while the other stays high. This forces Q low and, through the cross-coupled loop, flips QB high, overwriting whatever was stored before.

10. The sizing (relative transistor strength) of the pull-down transistors inside the inverters versus the access transistors is critical. For read stability, the pull-down transistors need to be strong enough relative to the access transistors so reads don't disturb the data. For write ability, the access transistors need to be strong enough relative to the pull-up transistors so writes can actually flip the cell.

11. This creates a balancing act: making the cell too "read-stable" (strong pull-downs) can make it hard to write, while making it too "easy to write" (strong access transistors) can make reads risk disturbing the data. Designers tune these transistor sizes carefully to satisfy both.

12. A typical test sequence — write 0, read (confirm 0), write 1, read (confirm 1) — shows the waveforms on WL, BL, BLB, Q, and QB toggling in the expected pattern each time. If each read correctly reports back exactly what was last written, without any unintended flips, it proves the cell can reliably store, retain, and be both written to and read from correctly.
## AI PROMPT
Write a complete, ready-to-run ngspice SPICE netlist for a standard 6T SRAM cell, using standard PMOS/NMOS level 1 or BSIM-compatible models (define simple .model statements for NMOS and PMOS if needed so the file runs standalone). The circuit should include two cross-coupled CMOS inverters forming the storage nodes Q and QB, plus two NMOS access transistors connecting Q to bitline BL and QB to bitline BLB, both gated by a shared wordline signal WL. Drive WL with a pulsed voltage source that goes high during read and write windows and low otherwise, and drive BL/BLB with voltage sources that precharge high between operations and are forced appropriately (one line pulled low relative to the other) during a write pulse to flip the stored value, followed by a read pulse where both bitlines are left floating-high/precharged to observe the small differential development. Include a .control block that runs a transient simulation (tran) covering an initial write-0, read, write-1, read sequence with clearly commented time windows, then automatically plots the voltages of WL, BL, BLB, Q, and QB on a single graph (or clearly labeled separate plots) so I can visually verify correct write and read behavior, and make sure all node names, transistor connections, and timing values are explicit and consistent so the netlist can be copy-pasted directly into ngspice and simulated without modification.
## NETLIST 1 GENERATED
```
* Read/Write Stability - WL pulsed
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)
VDD VDD 0 DC 1.8
* WL pulses: read(2-5n), write0(8-11n), read(13-16n), write1(19-22n), read(24-27n)
VWL WL 0 PWL(0 0 2n 0 2.1n 1.8 5n 1.8 5.1n 0
+                8n 0 8.1n 1.8 11n 1.8 11.1n 0
+                13n 0 13.1n 1.8 16n 1.8 16.1n 0
+                19n 0 19.1n 1.8 22n 1.8 22.1n 0
+                24n 0 24.1n 1.8 27n 1.8 27.1n 0)
* Bitlines - just tied high, no write drive
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
tran 10p 30n
plot v(Q) v(QB) v(WL) v(BL) v(BLB)
.endc
.end      is this correct
```
## OUTPUT OF NETLIST1







<img width="1920" height="1080" alt="Screenshot 2026-07-12 230713" src="https://github.com/user-attachments/assets/8fc6bda9-6608-4156-9d5c-36e54953369f" />







## ERROR

That leaves a gap — roughly 10.6–11ns and 21.6–22ns — where the bitline has already snapped back to precharge (1.8V) while WL is still open. During that gap, the access transistor is still connected, and it tries to pull the node you just wrote back toward the precharged bitline, fighting the cross-coupled inverters that are simultaneously trying to latch the new value. That's exactly the messy, multi-crossing transient you see clustered right after each write pulse — it's contention, not clean settling.
In this run the cell wins that fight and the correct value survives (which is why the reads confirm it), but that's a fragile outcome, not a guaranteed one. With slightly weaker access transistors, a slower corner, or a shorter write pulse, that same contention window could flip the node back and silently corrupt the write — and you'd never know just from eyeballing the plot.
The fix: make the bitline-low interval fully contain (or exactly match) the WL-high interval, so BL/BLB don't release back to precharge until WL has already gone low:


## NETLIST 2 GENERATED

```
* Read/Write Stability - WL pulsed (bitline write pulses now span the FULL WL-high window)
.model NMOS_GEN NMOS (LEVEL=1 VTO=0.7 KP=120u LAMBDA=0.01)
.model PMOS_GEN PMOS (LEVEL=1 VTO=-0.7 KP=40u LAMBDA=0.01)
VDD VDD 0 DC 1.8

* WL pulses: read(2-5n), write0(8-11n), read(13-16n), write1(19-22n), read(24-27n)
VWL WL 0 PWL(0 0 2n 0 2.1n 1.8 5n 1.8 5.1n 0
+                8n 0 8.1n 1.8 11n 1.8 11.1n 0
+                13n 0 13.1n 1.8 16n 1.8 16.1n 0
+                19n 0 19.1n 1.8 22n 1.8 22.1n 0
+                24n 0 24.1n 1.8 27n 1.8 27.1n 0)

* BL: forced low for the ENTIRE write-0 window (8-11n), released only after WL has fallen.
VBL  BL  0 PWL(0 1.8 8n 1.8 8.1n 0 11n 0 11.2n 1.8 30n 1.8)

* BLB: forced low for the ENTIRE write-1 window (19-22n), released only after WL has fallen.
VBLB BLB 0 PWL(0 1.8 19n 1.8 19.1n 0 22n 0 22.2n 1.8 30n 1.8)

M1 Q   QB VDD VDD PMOS_GEN W=0.42u L=0.15u
M2 Q   QB 0   0   NMOS_GEN W=0.64u L=0.15u
M3 QB  Q  VDD VDD PMOS_GEN W=0.42u L=0.15u
M4 QB  Q  0   0   NMOS_GEN W=0.64u L=0.15u
M5 BL  WL Q  0    NMOS_GEN W=0.42u L=0.15u
M6 BLB WL QB 0    NMOS_GEN W=0.42u L=0.15u

.ic V(Q)=1.8 V(QB)=0

.control
tran 10p 30n
* Numeric checks instead of eyeballing the plot
meas tran vQ_read1  find V(Q)  at=4n
meas tran vQ_read2  find V(Q)  at=14n
meas tran vQ_read3  find V(Q)  at=26n
plot v(Q) v(QB) v(WL) v(BL) v(BLB)
.endc
.end

```
## OUTPUT







<img width="1920" height="1080" alt="Screenshot 2026-07-12 231630" src="https://github.com/user-attachments/assets/5039fed4-30ae-4602-9a7e-0fdf85653476" />



## VIDEO SUMMARY
https://drive.google.com/file/d/1PmKQuYvjcRKP3ulfwkVLe6e_yeeE2t8H/view?usp=drive_link



## CONCLUSION
The netlists are generated,outputs are investigated,errors are solved and result is cross-checked.



