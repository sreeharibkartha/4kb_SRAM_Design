* NGSPICE file created from cell6t.ext - technology: scmos

.global Vdd Gnd 

.subckt cell6t
M1000 a_18_20# a_14_16# vdd vdd pfet w=3u l=4u
+  ad=19p pd=18u as=31p ps=26u
M1001 a_18_20# a_14_16# gnd gnd nfet w=8u l=2u
+  ad=30p pd=18u as=72p ps=34u
M1002 a_18_20# wl bl gnd nfet w=4u l=2u
+  ad=30p pd=18u as=20p ps=18u
M1003 vdd a_18_20# a_14_16# vdd pfet w=3u l=4u
+  ad=19p pd=18u as=19p ps=18u
M1004 gnd a_18_20# a_14_16# gnd nfet w=8u l=2u
+  ad=40p pd=26u as=30p ps=18u
M1005 a_14_16# wl br gnd nfet w=4u l=2u
+  ad=30p pd=18u as=20p ps=18u
C0 vdd a_18_20# 4.093f
C1 wl gnd 9.564f
C2 br vdd 1.1f
C3 wl bl 0.872f
C4 a_14_16# gnd 4.524f
C5 a_14_16# bl 0.95f
C6 br a_18_20# 0.133f
C7 a_14_16# vdd 2.079f
C8 wl a_18_20# 0.812f
C9 bl gnd 1.726f
C10 wl br 0.72f
C11 gnd vdd 6.28f
C12 a_14_16# a_18_20# 0.48f
C13 a_14_16# br 4.13f
C14 bl vdd 1.413f
C15 gnd a_18_20# 2.894f
C16 a_14_16# wl 0.812f
C17 br gnd 1.113f
C18 bl a_18_20# 0.176f
.ends

