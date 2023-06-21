--------------------------------------------------------------
-- fpgagate.com: FPGA Projects, VHDL Tutorials, VHDL projects 
-- VHDL seven segment decoder
--------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HEX2Seg is
	Port (
		hex : in STD_LOGIC_VECTOR (3 downto 0);
		seg : out STD_LOGIC_VECTOR (6 downto 0)
	);
end HEX2Seg;

architecture Behavioral of HEX2Seg is

begin
seg(6 downto 0) <=
        --  gfedcba 
           "1000000" when HEX="0000" else--0
           "1001111" when HEX="0001" else--1
           "0100100" when HEX="0010" else--2
           "0110000" when HEX="0011" else--3
           "0011001" when HEX="0100" else--4
           "0010010" when HEX="0101" else--5
           "0000010" when HEX="0110" else--6
           "1111000" when HEX="0111" else--7
           "0000000" when HEX="1000" else--8
           "0010000" when HEX="1001" else--9
           "0001000" when HEX="1010" else--A
           "0000011" when HEX="1011" else--b
           "1000110" when HEX="1100" else--C
           "0100001" when HEX="1101" else--d
           "0000110" when HEX="1110" else--E
           "0001110" when HEX="1111" else--F
           "0000000";       
end Behavioral;