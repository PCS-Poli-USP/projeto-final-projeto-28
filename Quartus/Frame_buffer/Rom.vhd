library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_linha is
	port (
      addr  : in std_logic_vector (11 downto 0);
	  data  : out std_logic_vector(11 downto 0)
	);
end rom_linha;

architecture arch of rom_linha is
	type mem_t is array (0 to 4095) of std_logic_vector(11 downto 0);
	signal mem : mem_t;
begin
	
	reggen: for i in 0 to 1364 generate
		mem(i) <= x"f00";
	end generate;
	
	reggen2: for i in 1365 to 2729 generate
		mem(i) <= x"0f0";
	end generate;
	
	reggen3: for i in 2730 to 4095 generate
		mem(i) <= x"00f";
	end generate;
	
	data <= mem(to_integer(unsigned(addr)));
end architecture;