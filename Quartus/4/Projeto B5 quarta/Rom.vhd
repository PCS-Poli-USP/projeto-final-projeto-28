library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_linha is
	port (
      addr  : in std_logic_vector(10 downto 0);
		data  : out std_logic_vector(11 downto 0)
	);
end rom_linha;

architecture arch of rom_linha is
	type mem_t is array (0 to 2047) of std_logic_vector(11 downto 0);
	signal mem : mem_t;
begin
	
	reggen: for i in 0 to 455 generate
		mem(i) <= x"00f";
	end generate;
	
	reggen2: for i in 456 to 910 generate
		mem(i) <= x"fff";
	end generate;
	
	reggen3: for i in 911 to 2047 generate
		mem(i) <= x"00f";
	end generate;
	
	data <= mem(to_integer(unsigned(addr)));
end architecture;