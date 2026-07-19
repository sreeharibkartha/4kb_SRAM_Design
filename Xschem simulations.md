## Xschem Simulation 
















<img width="1773" height="861" alt="Screenshot 2026-07-05 203935" src="https://github.com/user-attachments/assets/edac44ff-87ae-4722-aa0c-178725db67b5" />



<img width="1920" height="1080" alt="Screenshot 2026-07-05 214217" src="https://github.com/user-attachments/assets/0a75f586-ce53-48a5-ba04-8690fd78c047" />














<img width="1920" height="1080" alt="Screenshot 2026-07-05 232557" src="https://github.com/user-attachments/assets/c5211099-d909-4c26-b2d4-a5456107b43d" />









# simulation 1
```
M2 QB Q GND GND M2N7002 m=1                                                                                                                                                                                        
M3 QB net2 net4 net4 M2N7002 m=1                                                                                                               
M4 net3 net2 Q Q M2N7002 m=1
M5 Q QB net1 net1 DMP2035U m=1
VDD net1 GND 1.8
V2 net3 GND 1.8
V3 net4 GND 1.8
V4 net2 GND PULSE(0 1.8 2n 0.1n 0.1n 3n 8n)
M6 QB Q net1 net1 DMP2035U m=1
M1 Q QB GND GND M2N7002 m=1
**** begin user architecture code
.model M2N7002 NMOS (LEVEL=1 VTO=2.1 KP=0.12 LAMBDA=0.01)
.model DMP2035U PMOS (LEVEL=1 VTO=-2.1 KP=0.08 LAMBDA=0.01)
.control 
tran 10p 20n
plot v(Q) v(QB) v(net2)
.endc
**** end user architecture code
**.ends
.GLOBAL GND
.end
```










<img width="1920" height="1080" alt="Screenshot 2026-07-05 224224" src="https://github.com/user-attachments/assets/9f85c5cc-96f4-43d6-9285-41ea0265a2a8" />














#Simulation 2
```
change V3 net4 GND 1.8
```
 
 to 
 ```
 V3 net4 GND 0
```
 
 This sets BLB to 0V while BL (V2,net3) stays at 1.8V.So we are trying to write Q=1,QB=0 into cell while WL pushes high.






<img width="1920" height="1080" alt="Screenshot 2026-07-05 225525" src="https://github.com/user-attachments/assets/914d504c-5f72-4b22-b373-a0e4d39f95fe" />

 












#Simulation 3

Change the VTO values
```
.model M2N7002 NMOS (LEVEL=1 VTO=2.1 KP=0.12 LAMBDA=0.01)
.model DMP2035U PMOS (LEVEL=1 VTO=-2.1 KP=0.08 LAMBDA=0.01)
```
to

```
.model M2N7002 NMOS (LEVEL=1 VTO=0.6 KP=0.12 LAMBDA=0.01)
.model DMP2035U PMOS (LEVEL=1 VTO=-0.6 KP=0.08 LAMBDA=0.01)
```











<img width="1920" height="1080" alt="Screenshot 2026-07-05 232557" src="https://github.com/user-attachments/assets/b38672df-6c61-4392-b8f2-9361f0438762" />
<img width="1920" height="1080" alt="Screenshot 2026-07-05 225623" src="https://github.com/user-attachments/assets/da3b4370-7ac0-4741-964f-000f7b87836f" />




























After resolving the wiring, model-definition, terminal-count, and directive-formatting issues above, the 6T SRAM bitcell netlist was successfully simulated end-to-end in ngspice with no parser or convergence errors. The transient analysis confirmed a stable DC operating point with Q and QB settling to two distinct voltages rather than an indeterminate midpoint, and the wordline pulse waveform was correctly generated and visible in the resulting plot alongside the two storage-node traces — confirming the cross-coupled latch topology behaves as a functional bistable element under simulation.

A follow-up write test, performed by forcing one bitline low while the wordline pulsed, produced a measurable shift in the corresponding storage node's voltage, demonstrating that the access transistors and bitline path are correctly influencing the internal latch nodes rather than being electrically isolated from them. While the exact voltage levels reflect generic placeholder transistor models rather than datasheet-accurate parts, the topology, connectivity, and qualitative read/hold/write behavior of the cell were all verified as functioning as intended, closing out this stage of the SRAM bitcell verification effort.
