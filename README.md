# crc with NOC bus acting as a Bus Master as well as the Slave
Name: Ishwaki Thakkar
Graduate student at San Jose State University.

TDesigned and Synthesized the Cyclic Redundancy Check (CRC) with Network on Chip bus according to the NXP Specifications that generates 16/32-bit CRC code for error detection and provides a programmable polynomial and other parameters required to implement a 16-bit or 32-bit CRC standard.
The Bus Master NOC connected CRC engine expands on the existing CRC design enhancing the NOC controller, to be a bus master. The bus master logic uses the NOC interface to fetch and store data to a memory in Testbench


The System Verilog Files modules name are written in the Script Files for Synopsis VCS tool.
CRC Module: crc.sv,
CRC Interface with Testbench : crcif.sv,
Testbench : tbcrc.sv, 

Design 2 Implemented with Busmaster and a slave.
Bus module : Bm.sv (lies between nocif.sv, and crcif.sv)
Testbench Interface with nocif.sv
Interface of crc with busmaster : crcif.sv
Testbench : tbcrcn.sv

Simulate using ./sv_uvm tbcrc.sv , ./sv_uvm tbcrcn.sv
Synthesis : ./sss
