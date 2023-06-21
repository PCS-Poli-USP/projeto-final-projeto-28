library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_W_CACHE is
    port (
		clk	  : in  std_logic;
		adv   : in  std_logic;
        rst   : in  std_logic;
        dout  : out std_logic_vector (15 downto 0);
		empty : out std_logic;
		full : out std_logic
    );
end RAM_W_CACHE;

architecture rtl of RAM_W_CACHE is
	 
	component ram_write_cache IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	END component ram_write_cache;
	 
	signal count : unsigned(9 downto 0) := (others => '0');
	signal ram_addr : std_logic_vector(9 downto 0);
	 
begin
	cnt: process(clk,rst) is
	begin
		if rst = '0' then
			count <= (others => '0');
		elsif falling_edge(clk) and adv = '1' then
			if count /= "1111111111" then
				count <= count + 1;
			end if;
		end if;
	end process;
	
	
	
	Read_cache: ram_write_cache
	PORT MAP
	(
		address		=> ram_addr,
		clock		=> clk,
		data		=> x"0000",
		wren		=> '0',
		q			=> dout
	);
	
	ram_addr <= std_logic_vector(count);
	full <= '1' when count = 0 else '0';
	empty <= '1' when count = 1023 else '0';
	
	
	
end architecture;
