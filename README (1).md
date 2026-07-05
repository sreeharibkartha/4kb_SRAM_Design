# SRAM Architecture

A structured walkthrough of 6T SRAM bitcell design and the surrounding circuitry that makes a memory array work — from the bitcell itself up through timing sequences. Written to go from fundamentals to system-level behavior, with each section building on the last.

## Summary

Static RAM (SRAM) stores a single bit using a bistable latch made of six transistors (6T). Unlike DRAM, it needs no refresh — the cross-coupled inverter pair holds its state as long as power is applied. But that simplicity hides a lot of analog nuance: the same access transistors used to read a cell can accidentally disturb the value stored in it, the cell has to be weak enough to be overwritten during a write but strong enough to survive a read, and an entire support ecosystem (precharge, sense amps, write drivers, decoders, timing control) exists purely to make that narrow operating window usable at scale.

This document covers, in order:

1. **6T SRAM bitcell operation** — the core storage element and how it holds a bit.
2. **Read/write stability** — why a cell that reads well may write poorly, and vice versa.
3. **Butterfly curve** — the standard graphical tool for visualizing cell stability.
4. **Read disturb** — how the act of reading can accidentally flip a cell.
5. **Write margin** — how much "push" is available to force a new value into a cell.
6. **Precharge circuit** — preparing bitlines before every read.
7. **Wordline control** — how a single row of cells is selected.
8. **Bitline behaviour** — what actually happens electrically on BL/BLB during access.
9. **Sense amplifier concept** — detecting a tiny voltage difference quickly.
10. **Write driver concept** — forcing a new value onto the bitlines.
11. **Row/column decoder basics** — turning an address into a selected cell.
12. **SRAM timing sequence** — how all of the above are sequenced in one access cycle.

Each section below is self-contained but assumes familiarity with the one before it.

---

## 1. 6T SRAM Bitcell Operation

### 1.1 Structure

The classic SRAM bitcell uses six transistors:

- **Two cross-coupled inverters** (4 transistors: 2 NMOS pull-down, 2 PMOS pull-up) that form a bistable latch.
- **Two access transistors** (NMOS) that connect the latch's internal storage nodes to the bitlines, gated by the wordline (WL).

The two internal storage nodes are conventionally called **Q** and **QB** (Q-bar), and they always hold opposite logic values — if Q is high, QB is low, and vice versa.

### 1.2 The Cross-Coupled Latch

Each inverter's output feeds the other inverter's input. This creates positive feedback: if Q starts drifting toward "1," that pushes QB toward "0," which in turn pushes Q further toward "1." The result is two stable equilibrium points — (Q=1, QB=0) and (Q=0, QB=1) — separated by an unstable third point (both at the midpoint voltage) that the circuit will never rest at under normal conditions.

This is what makes the cell "static" — no clock or refresh signal is needed to keep the data; the feedback loop does it for free as long as VDD is applied.

### 1.3 Access Transistors and the Wordline

The two access transistors (sometimes called pass gates) sit between the storage nodes and the bitlines:

- One access transistor connects **Q** to **BL** (bitline).
- The other connects **QB** to **BLB** (bitline bar / complementary bitline).

Both access transistor gates are tied to the **wordline (WL)**. When WL is low, both access transistors are off, and the latch is fully isolated — this is the "hold" state, and it's where the cell spends the vast majority of its time.

When WL goes high, both access transistors turn on, connecting Q and QB directly to BL and BLB. What happens next depends on whether it's a read or a write — covered in the next sections.

### 1.4 Why Six Transistors

- Fewer transistors (e.g., 4T or 3T cells) exist but sacrifice noise margin, need extra refresh circuitry, or aren't fully static.
- 6T is the standard trade-off point: fully static operation, reasonably compact, and well-understood stability characteristics — which is exactly why it's the default cell in most SRAM arrays.

---

## 2. Read/Write Stability

### 2.1 The Central Tension

A 6T cell has to satisfy two conflicting requirements:

- **During a read**, the cell must be strong enough that connecting Q and QB to the bitlines (which are usually pre-charged to VDD) doesn't accidentally flip the stored value.
- **During a write**, the cell must be weak enough that the write driver, pushing a new value through the same access transistors, *can* overpower the latch and force a flip.

Both operations go through the identical access transistors and gate signal (WL). The cell can't tell the difference between "someone is reading me" and "someone is writing me" — it only feels a change in voltage at Q or QB through the access transistor. This is the fundamental design tension in every 6T cell.

### 2.2 Sizing as the Lever

The way this tension is resolved is transistor sizing — specifically, the relative strength (width/length ratio) between three transistor types in the cell:

- **Pull-down NMOS** (in the inverters) — needs to be strong to resist read disturb.
- **Access transistor NMOS** — sits in the middle; its strength relative to the pull-down affects read stability, and its strength relative to the pull-up affects write margin.
- **Pull-up PMOS** (in the inverters) — generally kept weak, since a strong pull-up fights against writes.

These ratios have names:

- **Cell ratio (CR)** = pull-down strength / access transistor strength. Higher CR improves read stability.
- **Pull-up ratio (PR)** = pull-up strength / access transistor strength. Lower PR improves write margin.

### 2.3 Why This Matters at Scale

A single cell can usually be sized to work fine in isolation. The real difficulty is that a memory array contains thousands to millions of identical cells, all subject to manufacturing variation (random dopant fluctuation, line-edge roughness, etc.). A design that has healthy margins on average can still have a small fraction of cells that fail, and at large array sizes even a small failure probability becomes a real yield problem. This is why read/write stability isn't just a design nicety — it drives statistical analysis (Monte Carlo simulation, sigma-based margin targets) in real SRAM design.

---

## 3. Butterfly Curve

### 3.1 What It Is

The butterfly curve is the standard visual tool for read stability analysis. It's constructed by plotting the voltage transfer characteristic (VTC) of both inverters in the cross-coupled pair on the same graph, with one inverter's curve mirrored (swapping its axes) so both curves appear on the same Q-vs-QB plane.

The result looks like two "eyes" or lobes facing each other — hence "butterfly."

### 3.2 Reading the Curve

- The two curves intersect at **three points**: two stable operating points near the corners (representing (Q≈VDD, QB≈0) and (Q≈0, QB≈VDD)), and one unstable point near the center.
- Inside each lobe, the largest square that can be inscribed touching both curves represents the **Static Noise Margin (SNM)** — the maximum DC noise voltage the cell can tolerate at its internal nodes before it's forced out of its current stable state.
- A **larger inscribed square** = more stability = better read margin. A **smaller or lopsided square** = the cell is closer to accidentally flipping.

### 3.3 Two Versions of the Curve

- **Hold SNM**: butterfly curve plotted with WL low (access transistors off) — measures pure static stability with no external disturbance.
- **Read SNM**: butterfly curve plotted with WL high and bitlines pre-charged — measures stability *during* the read access itself, which is always worse than hold SNM because the access transistors are now loading the storage nodes.

Read SNM is the more conservative and more commonly reported number, since it reflects the actual worst-case condition during operation.

### 3.4 Why It's the Standard Tool

The butterfly curve turns an abstract stability question ("will this cell flip?") into a simple geometric one ("how big is the square?"). It's intuitive to read visually, directly comparable across different sizing choices, and forms the basis for the numerical SNM metric used in papers, datasheets, and simulation reports.

---

## 4. Read Disturb

### 4.1 The Mechanism

Read disturb is the failure mode where the act of reading a cell corrupts the value it's storing. Here's how it happens:

1. Before a read, both bitlines (BL and BLB) are pre-charged to VDD.
2. WL goes high, turning on both access transistors.
3. Suppose Q is storing "0" (so QB is "1"). The access transistor connected to Q now ties the pre-charged BL (at VDD) directly to the "0" node.
4. This creates a voltage divider between the pre-charged bitline (through the access transistor) and the pull-down NMOS (which is trying to hold Q at 0). If the access transistor is too strong relative to the pull-down, Q gets pulled up toward VDD rather than staying near 0V.
5. If Q rises high enough to cross the inverter's switching threshold, the cross-coupled feedback takes over and **flips the cell** — the read has destroyed the data it was trying to retrieve.

### 4.2 Why It's Called "Disturb," Not Just "Failure"

The term specifically describes a read causing an unintended write. It's distinguished from other read problems (like a bitline signal being too weak to sense correctly) because disturb is about the *cell itself losing its stored value*, not just the sense circuitry misreading it.

### 4.3 Mitigations

- **Sizing (Cell Ratio):** the primary defense — make the pull-down NMOS strong enough relative to the access transistor that the voltage divider never pushes Q past the switching threshold. This is exactly the "read stability" trade-off from Section 2.
- **Lowering WL voltage during read (or boosting cell VDD):** reduces the access transistor's drive strength during read without touching the write path, widening the read margin without hurting writability. Used in some low-voltage designs.
- **Read assist techniques:** more advanced array-level techniques exist (e.g., negative bitline schemes, separate read ports in 8T cells) that sidestep the problem entirely, at the cost of extra transistors or complexity.

---

## 5. Write Margin

### 5.1 What It Measures

Write margin quantifies how easily a new value can be forced into the cell — essentially the mirror image of read stability. It's usually expressed as the **Write Trip Voltage (WTV)**: the bitline voltage at which the cell successfully flips during a write attempt. A lower WTV (closer to 0) is generally better, meaning less "effort" is needed from the bitline to force the flip.

### 5.2 How a Write Physically Happens

1. The write driver forces one bitline low (say BLB goes to 0V) while the other stays high (BL stays near VDD), based on the value being written.
2. WL goes high, connecting the bitlines to Q and QB through the access transistors.
3. The access transistor pulling QB toward 0V has to fight against the PMOS pull-up (in the inverter) that's trying to hold QB high.
4. If the access transistor wins that fight, QB gets pulled low enough to cross the switching threshold, triggering the cross-coupled feedback to flip the whole cell to the new value.

### 5.3 The Sizing Trade-off, Revisited

Write margin improves when:

- The access transistor is **strong** relative to the PMOS pull-up (opposite of what read stability wants relative to the pull-down).
- The PMOS pull-up is **weak**.

This is why cell design is fundamentally a balancing act: strengthening the access transistor helps write margin but can hurt read stability (Section 4), and there's no sizing choice that maximizes both simultaneously — only a workable middle ground, verified against both the read-disturb condition and the write-trip condition.

### 5.4 Write Margin and Voltage Scaling

As supply voltage drops (common in modern low-power designs), the difference between the pull-up's holding strength and the access transistor's pulling strength shrinks, making writes harder. This is one of the key reasons SRAM often struggles to scale to very low voltages compared to logic circuits, and why write-assist techniques (temporarily weakening the pull-up, boosting the wordline, or lowering cell VDD during write) are common in modern designs.

---

## 6. Precharge Circuit

### 6.1 Purpose

Before any read access, both bitlines (BL and BLB) need to be at a known, equal starting voltage — almost always VDD (or occasionally VDD/2 in some sensing schemes). The precharge circuit's job is to quickly drive both bitlines to this voltage and then get out of the way before the actual access happens.

### 6.2 Typical Structure

A precharge circuit for one bitline pair typically consists of:

- **Two PMOS transistors**, each connecting one bitline (BL, BLB) to VDD.
- **One PMOS equalization transistor**, connecting BL and BLB directly to each other.

All three are gated by a common **precharge enable signal** (often active-low, so a "PC" or "PCB" pulse turns them on).

### 6.3 Why Equalization Matters

The equalization transistor isn't strictly necessary to charge both lines to VDD individually, but it ensures BL and BLB start at *exactly* the same voltage, even if there's some mismatch in how fast each PMOS charges its own line. Since a read later depends on detecting a tiny voltage difference between BL and BLB (see Section 8 and 9), any leftover mismatch from an uneven precharge directly eats into the sensing margin — so equalization is there to guarantee a clean, symmetric starting point.

### 6.4 Timing Relationship to the Rest of the Cycle

Precharge must complete *before* WL goes high for a read. If WL rises while bitlines are still mid-charge, the read will start from an inconsistent baseline, and the resulting voltage difference read by the sense amplifier will be inaccurate or too small to reliably detect. This is why precharge timing is tightly controlled as part of the overall SRAM timing sequence, covered in Section 12.

---

## 7. Wordline Control

### 7.1 Role of the Wordline

The wordline (WL) is the signal that "selects" an entire row of cells simultaneously by turning on their access transistors. Every cell in a given row shares the same physical wordline, while every cell in a given column shares the same bitline pair. This row/column structure is what lets a single address select exactly one cell (or one word, if multiple bit-columns are grouped) out of the whole array — covered further in Section 11.

### 7.2 Wordline Driver

The wordline itself is a long metal line spanning an entire row, which represents significant capacitive and resistive load, especially in large arrays. Driving it requires a dedicated **wordline driver** — typically a chain of progressively larger inverter or buffer stages — strong enough to charge/discharge that line quickly without excessive delay.

### 7.3 Pulse Width Considerations

The WL pulse can't be arbitrarily short or arbitrarily long:

- **Too short**, and there isn't enough time for the bitline to develop a sufficient voltage difference for the sense amplifier to detect (read) or for the write driver to force a full flip (write).
- **Too long**, and the cell is exposed to the read-disturb condition (Section 4) for longer than necessary, and overall cycle time suffers.

WL pulse width is therefore a carefully tuned parameter, balanced against bitline RC characteristics and sense amplifier speed.

### 7.4 Only One Wordline Active at a Time

In normal operation, only one wordline in the array is driven high during any given access — this is what the row decoder (Section 11) enforces. If multiple wordlines were accidentally active simultaneously, multiple cells in different rows would try to drive the same bitline pair at once, corrupting the read/write entirely.

---

## 8. Bitline Behaviour

### 8.1 Structure

Each column of cells shares a pair of bitlines: **BL** and **BLB**. These are long vertical metal lines running through every row, connecting to one access transistor per cell in that column. Like wordlines, they carry significant parasitic capacitance because of their length and the many transistor connections along them.

### 8.2 Bitline Behaviour During a Read

1. Both BL and BLB start pre-charged to VDD (Section 6).
2. WL goes high for the selected row.
3. Depending on the stored value, one bitline gets pulled down slightly by the cell (through the access transistor and the pull-down NMOS it connects to), while the other bitline stays essentially unchanged.
4. This produces a **small voltage difference** between BL and BLB — often just tens to a couple hundred millivolts, not a full swing — because the cell's pull-down transistor is deliberately kept weak (for read stability, Section 2) compared to the bitline's large capacitance.
5. This small difference is what the sense amplifier (Section 9) is designed to detect and amplify into a full logic-level output.

### 8.3 Bitline Behaviour During a Write

1. The write driver forces one bitline to 0V and lets the other stay at (or return to) VDD, based on the data being written — this is a **full-swing** drive, not the subtle difference seen in reads.
2. WL goes high, and the strongly-driven bitlines fight the cell's internal feedback through the access transistors until the cell flips (or fails to, if write margin is insufficient — Section 5).

### 8.4 Why the Read/Write Bitline Behaviour Looks So Different

This asymmetry — subtle voltage difference on read, full-swing forcing on write — is intentional and directly reflects the read/write stability trade-off (Section 2). A read is designed to gently probe the cell without disturbing it, while a write is designed to aggressively override it. The same physical wires (BL, BLB) are doing very different electrical jobs depending on which operation is underway.

---

## 9. Sense Amplifier Concept

### 9.1 Why It's Needed

As covered in Section 8, a read produces only a small voltage difference between BL and BLB — not a clean logic level. Waiting for the bitline to swing all the way to a full digital "0" or "1" on its own would be far too slow, given the large capacitance of a long bitline. The sense amplifier's job is to detect that small difference quickly and amplify it into a fast, full-swing digital output.

### 9.2 Basic Concept

A sense amplifier is essentially a **differential comparator** optimized for speed rather than raw gain in the classic op-amp sense. The most common style used in SRAM is a **cross-coupled latch-type sense amp**, structurally similar in spirit to the bitcell itself: two cross-coupled inverters that, once triggered ("fired"), rapidly regeneratively amplify whatever small imbalance exists between their two input nodes toward full rail values.

### 9.3 Operating Sequence (Conceptual)

1. The sense amp's internal nodes are typically pre-equalized (similar concept to bitline precharge) before firing.
2. BL and BLB, carrying their small developed voltage difference, are connected to the sense amp's inputs.
3. A **sense enable** signal fires the amplifier — this is precisely timed to occur only after the bitline difference has had enough time to develop to a reliably detectable level, but not so late that it wastes cycle time.
4. Once fired, the positive feedback in the cross-coupled structure takes even a few tens of millivolts of difference and rapidly drives it to a full VDD/0V output.

### 9.4 Why Timing the Sense Enable Matters

Firing the sense amp too early risks amplifying noise or an insufficiently developed signal into the *wrong* value (a hard read failure). Firing it too late needlessly slows down the memory's access time. This is why sense amp timing is one of the most carefully tuned aspects of overall SRAM timing (Section 12), often controlled by a replica-path or delay-matched timing generator rather than a fixed delay.

---

## 10. Write Driver Concept

### 10.1 Role

The write driver is the circuit responsible for taking the incoming data bit (the value to be written) and driving the bitline pair (BL, BLB) to the appropriate full-swing voltages to force that value into the selected cell.

### 10.2 Basic Structure

A typical write driver is built around a pair of **tri-state or gated inverter/buffer stages**, one driving BL and one driving BLB, controlled by:

- The **data input** (the bit to write).
- A **write enable** signal, which ensures the driver only actively drives the bitlines during an actual write operation — at all other times (including reads), the driver is disconnected (high-impedance), letting the precharge circuit and the cell itself control the bitline voltages instead.

### 10.3 Why It Needs to Be Strong

Unlike the cell's own pull-down transistors (which are deliberately kept weak for read stability), the write driver needs to be a comparatively strong, low-impedance driver. Its entire job is to win the "tug of war" against the cell's internal pull-up transistors during a write (Section 5) — a weak or slow write driver directly translates into poor write margin and potential write failures, regardless of how well the cell itself is sized.

### 10.4 Interaction with Column Multiplexing

In many real array designs, more than one column shares a single write driver (through a column multiplexer/decoder, Section 11), since dedicating a full driver to every single column would be wasteful of area. The multiplexer selects which specific bitline pair, among several sharing that driver, actually gets connected during a given write cycle.

---

## 11. Row/Column Decoder Basics

### 11.1 The Addressing Problem

A memory array might contain millions of bitcells, but a processor only wants to access one specific word at a time, identified by an address. Decoders are the circuits that translate a binary address into "select exactly this row, and exactly this column(s)."

### 11.2 Row Decoder

- Takes the row-address bits and activates exactly **one wordline** out of the many in the array (Section 7).
- Structurally, this is typically built from a tree of AND-style logic (often implemented as NAND/NOR gate stages followed by an inverting buffer), where each unique combination of address bits routes to a unique output line.
- For an array with 2^N rows, an N-bit row address is needed, and the decoder must have 2^N output lines, only one of which is driven high for any given address.

### 11.3 Column Decoder / Column Multiplexer

- Takes the column-address bits and selects which bitline pair(s) actually connect to the sense amplifiers (for reads) and write drivers (for writes) — since, as mentioned in Section 10, multiple columns often share a single sense amp/write driver pair to save area.
- This is implemented with pass-transistor or transmission-gate multiplexers controlled by decoded column-select signals.

### 11.4 Why Decoding Speed Matters

The row decoder sits directly in the critical timing path — nothing else in the read or write sequence can begin until the correct wordline is actually asserted. Decoder speed (and the wordline driver strength discussed in Section 7) is therefore a major contributor to overall SRAM access time, which is why decoders are typically built with buffered, optimized logic stages rather than simple unbuffered gates.

---

## 12. SRAM Timing Sequence

### 12.1 Bringing It All Together

Every concept above participates in a tightly choreographed sequence during a single memory access. Below is the conceptual order of events for a **read** and for a **write**, assuming the address has already arrived.

### 12.2 Read Cycle Sequence

1. **Precharge phase:** BL and BLB for the target column(s) are driven to VDD and equalized (Section 6). This typically happens continuously between accesses, or at the start of each cycle depending on the design style.
2. **Row decode:** the row address is decoded, and the corresponding wordline driver begins asserting WL for the selected row (Sections 7, 11).
3. **Access/bitline development:** once WL is high, the selected cells begin pulling their respective bitline (BL or BLB) down slightly, developing a small voltage difference (Section 8).
4. **Sense enable:** after a carefully timed delay — long enough for a reliable voltage difference to develop, but no longer — the sense amplifier is fired, rapidly amplifying that difference to a full logic level (Section 9).
5. **Output latch/data out:** the sense amplifier's output is captured and driven out as the read data.
6. **Wordline off / precharge restart:** WL is deasserted, and the bitlines are precharged again in preparation for the next access.

### 12.3 Write Cycle Sequence

1. **Write driver setup:** the write driver receives the incoming data bit and, once write-enable is asserted, begins driving BL and BLB to full-swing opposite values corresponding to that data (Section 10).
2. **Row decode:** as with a read, the row address is decoded and the target WL is asserted (Sections 7, 11). Note that unlike a read, bitlines are *not* left in a precharged, high-impedance state — they're actively driven by the write driver.
3. **Cell flip:** with WL high and the bitlines strongly driven, the access transistors force the internal storage nodes toward the new value, and the cross-coupled feedback completes the flip if write margin is sufficient (Section 5).
4. **Wordline off:** WL is deasserted once enough time has passed to guarantee the flip completed reliably.
5. **Bitline release / precharge restart:** the write driver releases the bitlines (returns to high-impedance), and the precharge circuit takes back over in preparation for the next access.

### 12.4 Why the Sequencing Order Can't Change

Each step depends on the one before it: sensing before the bitline difference develops produces garbage; asserting WL before precharge completes corrupts the read baseline; releasing the write driver before the cell has fully flipped can let the cell's own feedback fight back and reject the write. This strict ordering is why SRAM timing is typically generated by a dedicated **timing control block**, often using replica bitlines/wordlines (dummy structures matched to the real array) to self-time these transitions accurately across process, voltage, and temperature variation, rather than relying on fixed external clock delays alone.

---

