--------------------------------------------------------------
-- fpgagate.com: FPGA Projects, VHDL Tutorials, VHDL projects 
-- VHDL seven segment decoder
--------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HEX2Seg is
	Port (
		hex : in STD_LOGIC_VECTOR (3 downto 0);
		seg : out std_logic_vector(7 downto 0)
	);
end HEX2Seg;

architecture Behavioral of HEX2Seg is

begin
seg(7 downto 0) <=
        --  gfedcba 
           "11000000" when HEX="0000" else--0
           "11001111" when HEX="0001" else--1
           "10100100" when HEX="0010" else--2
           "10110000" when HEX="0011" else--3
           "10011001" when HEX="0100" else--4
           "10010010" when HEX="0101" else--5
           "10000010" when HEX="0110" else--6
           "11111000" when HEX="0111" else--7
           "10000000" when HEX="1000" else--8
           "10010000" when HEX="1001" else--9
           "10001000" when HEX="1010" else--A
           "10000011" when HEX="1011" else--b
           "11000110" when HEX="1100" else--C
           "10100001" when HEX="1101" else--d
           "10000110" when HEX="1110" else--E
           "10001110" when HEX="1111" else--F
           "00000000";       
end Behavioral;