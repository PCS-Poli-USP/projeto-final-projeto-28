library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_linha is
	port (
      addr  : in std_logic_vector(8 downto 0);
		data  : out std_logic_vector(11 downto 0)
	);
end rom_linha;

architecture arch of rom_linha is
	type mem_t is array (0 to 511) of std_logic_vector(11 downto 0);
	signal mem : mem_t;
begin
	
	reggen: for i in 0 to 479 generate
		mem(i) <= std_logic_vector(to_unsigned(i*4, 12));
	end generate;
	
	reggen2: for i in 480 to 511 generate
		mem(i) <= (others => '0');
	end generate;

	
	data <= mem(to_integer(unsigned(addr)));
end architecture;