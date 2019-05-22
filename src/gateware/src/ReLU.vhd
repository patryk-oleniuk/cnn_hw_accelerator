-- Combinatorial ReLU Recitifier for forward propagation- realises the funtion y=max(0,x) for single pixel.
-- Version of the accelerator : based on the paper Optimizing Loop Operation and Dataflow in FPGA
-- Acceleration of Deep Convolutional Neural Networks, Arizona State University
-- @author Patryk Oleniuk, patryk.leniuk@epfl.ch, LAP, EPFL 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cnn_conv.all;

entity ReLU is
	port (
		pix_in      : in  std_logic_vector(BIT_ACCURACY - 1 downto 0);
		pix_out     : out  std_logic_vector(BIT_ACCURACY - 1 downto 0)
	);
end entity ReLU;

architecture RTL of ReLU is
	
begin
	pix_out <= pix_in when pix_in(BIT_ACCURACY - 1) = '0' else (others => '0');

end architecture RTL;
