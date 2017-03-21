The project implements CNN forward propagation for image processing accelerator on the Xilinx ZYNQ Soc/FPGA platform with PetaLinux. The accelerator implementation is done in VHDL/System Verilog, the control code is written in C++ under PetaLinux running on ZYNQ.

The CNN used as a reference was implemented in https://github.com/patryk-oleniuk/emotion_recognition and implemented in python/tensorflow. The purpose if this particular, 7-layer CNN was to determine emotions from 48x48 greyscale picture. 
Features implemented:
- generic image convolution
- image max pooling 2x2 
- ReLU

Author of the project:
Patryk Oleniuk, Processor Architecture Lab, EPFL