# Simulation Notes

Supplementary documentation for the 12 per-block netlists and the standalone 6T bitcell simulation in this repository. Part 1 gives a short description for each block's netlist. Part 2 documents recurring errors encountered while building these circuits in xschem/ngspice. Part 3 summarizes the successful bitcell simulation run.

---

## Part 1 — Netlist Descriptions (one per block)

### 1. 6T SRAM Bitcell Operation
This netlist implements the core cross-coupled inverter pair with two NMOS access transistors, verifying that the cell holds a stable, non-oscillating value at Q and QB under DC bias. It confirms the latch reaches one of its two intended stable states rather than settling at an invalid mid-rail voltage.

### 2. Read/Write Stability
This netlist runs the same bitcell under two bias conditions — wordline low (hold) and wordline high with bitlines pre-charged (read) — to compare how much the stored value shifts under access. It's used to check whether the cell's sizing keeps Q and QB safely on their correct side of the switching threshold during a read.

### 3. Butterfly Curve
This netlist sweeps the input of one inverter in the cross-coupled pair across the supply range while measuring the other inverter's output, generating the two voltage transfer curves needed to construct the butterfly plot. The resulting curve pair is used to visually and numerically extract the static noise margin of the cell.

### 4. Read Disturb
This netlist pre-charges both bitlines to VDD, asserts the wordline, and monitors the internal storage node holding a "0" to see how far it gets pulled toward VDD before the wordline is released. It's used to determine whether the read access alone is capable of flipping the cell without any intentional write occurring.

### 5. Write Margin
This netlist drives one bitline to 0V and the other to VDD, asserts the wordline, and tracks how quickly and completely the internal nodes flip to match the forced bitline values. It's used to find the minimum bitline drive condition (write trip voltage) at which the cell reliably changes state.

### 6. Precharge Circuit
This netlist models the PMOS precharge and equalization transistors driving both bitlines toward VDD from an arbitrary starting voltage. It verifies that both bitlines reach the same final voltage within the intended precharge window before any wordline activity begins.

### 7. Wordline Control
This netlist isolates the wordline driver stage, applying an input pulse and measuring the propagation delay and rise/fall time at the far end of a wordline modeled with representative RC parasitics. It's used to confirm the driver is strong enough to fully assert the wordline within the allotted pulse width.

### 8. Bitline Behaviour
This netlist connects a single cell to a bitline pair modeled with lumped capacitance, then triggers a read access to observe the resulting small-signal voltage difference that develops between BL and BLB. It's used to quantify how much differential signal is actually available for the sense amplifier to detect.

### 9. Sense Amplifier Concept
This netlist applies a small pre-set voltage difference to the sense amplifier's two input nodes, then fires the sense-enable signal to observe how quickly and cleanly that difference is amplified to a full-swing output. It's used to check the amplifier's minimum detectable input offset and its regeneration speed.

### 10. Write Driver Concept
This netlist exercises the write driver with a toggling data input and write-enable signal, measuring how quickly and how fully it drives the two bitlines to opposite rail voltages. It's used to confirm the driver is strong enough to win the write contest against the cell's internal pull-up transistors.

### 11. Row/Column Decoder Basics
This netlist applies all combinations of address bits to a small decoder block and verifies that exactly one output line goes high for each unique input combination, with all others remaining low. It's used to confirm correct decode logic and to measure address-to-wordline propagation delay.

### 12. SRAM Timing Sequence
This netlist stitches together precharge, wordline assertion, sense-enable, and write-enable signals on a shared timeline to model one full read cycle followed by one full write cycle. It's used to verify that the relative timing between all control signals matches the intended sequence with no overlaps or race conditions.

---

## Part 2 — Errors Encountered (xschem / ngspice)

### Error 1: Reversed Drain/Source Wiring on Cross-Coupled Transistors
While wiring the pull-down NMOS transistors (M1, M2) and pull-up PMOS transistors (M5, M6) in xschem, two of the six transistors ended up with their drain and source connections swapped relative to their intended positions. This wasn't visible from the schematic at a glance because the wires still appeared to connect to the right general area, and only became clear when the generated netlist was inspected line by line. Because the 2N7002 and DMP2035U models used are specific, directional device models rather than an ideal symmetric MOSFET, this reversal genuinely changed circuit behavior instead of being harmless. The fix required manually deleting and redrawing the wires on the affected pins with drain and source explicitly swapped. This error emphasized the importance of verifying the generated netlist text directly rather than relying on visual inspection of the schematic alone.

### Error 2: Missing SPICE Model Definitions
The first attempt to run the generated netlist in ngspice failed immediately with a "could not find a valid modelname" error, because the netlist referenced the transistor model names M2N7002 and DMP2035U without any accompanying `.model` statement defining their electrical parameters. A filesystem search confirmed that no manufacturer SPICE model files for either part existed locally, and the one partial match found belonged to a different simulator's library with an incompatible model name. Rather than sourcing exact datasheet models, generic Level-1 NMOS and PMOS `.model` definitions with placeholder threshold voltages were added directly in the schematic's SPICE directive block. This resolved the immediate blocking error and allowed the simulation to proceed, though it meant the resulting voltage levels were only qualitatively meaningful rather than matching real device datasheets. This highlighted that a netlist referencing a transistor by name is not sufficient on its own — every referenced model name must be explicitly defined somewhere in the simulation deck.

### Error 3: Insufficient Transistor Terminal Count
After adding the model definitions, ngspice returned a new error reading "not enough nodes" on the same transistor lines that had previously failed on the missing model. This occurred because a standard SPICE MOSFET model line requires four terminals — drain, gate, source, and bulk/body — while the schematic symbol used only exposed three pins (drain, gate, source), so the exported netlist line was one terminal short of what the model card expected. The fix involved manually editing the generated netlist to add a fourth terminal to each transistor line, tying the bulk node to the source terminal as a standard simplification for discrete-style devices. This was a temporary, file-level fix rather than a schematic-level one, meaning it would be overwritten the next time xschem regenerated the netlist. It illustrated that the number of pins on a schematic symbol and the number of terminals expected by the underlying SPICE model must match exactly, or the mismatch surfaces only at simulation time rather than at schematic-drawing time.

### Error 4: Multi-Statement Directive Block Collapsing to One Line
The SPICE directive text box used to hold the `.model` and `.control` statements silently collapsed all typed lines into a single continuous line of text within the property editor, rather than preserving them as separate SPICE statements. Because SPICE treats each `.model`, `.control`, and simulation command as its own line-based statement, having them concatenated onto one line caused ngspice to parse only the first `.model` statement and silently discard everything typed after it on that same line, including the second `.model` definition and the `.control` block itself. This error was especially difficult to catch because it produced no direct syntax error — the simulation appeared to proceed, just with one of the two transistor types permanently unrecognized. The fix required opening the generated netlist file directly in a plain text editor and manually re-entering each statement with a genuine line break between them, rather than relying on the schematic property editor's text box. This error demonstrated that a text field accepting multi-line input inside a GUI tool does not guarantee that input is preserved as multiple lines in the exported output, and that generated files should be inspected directly when debugging parser-level issues.

---

## Part 3 — Successful Simulation Summary

After resolving the wiring, model-definition, terminal-count, and directive-formatting issues above, the 6T SRAM bitcell netlist was successfully simulated end-to-end in ngspice with no parser or convergence errors. The transient analysis confirmed a stable DC operating point with Q and QB settling to two distinct voltages rather than an indeterminate midpoint, and the wordline pulse waveform was correctly generated and visible in the resulting plot alongside the two storage-node traces — confirming the cross-coupled latch topology behaves as a functional bistable element under simulation.

A follow-up write test, performed by forcing one bitline low while the wordline pulsed, produced a measurable shift in the corresponding storage node's voltage, demonstrating that the access transistors and bitline path are correctly influencing the internal latch nodes rather than being electrically isolated from them. While the exact voltage levels reflect generic placeholder transistor models rather than datasheet-accurate parts, the topology, connectivity, and qualitative read/hold/write behavior of the cell were all verified as functioning as intended, closing out this stage of the SRAM bitcell verification effort.
