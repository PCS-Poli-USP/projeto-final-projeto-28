library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_R_CACHE is
    port (
		clk	  : in  std_logic;
        rst   : in  std_logic;
		we	  : in std_logic;
        din   : in  std_logic_vector (15 downto 0);
		addr  : in  std_logic_vector (9 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		empty : out std_logic;
		full : out std_logic
    );
end RAM_R_CACHE;

architecture rtl of RAM_R_CACHE is
	 
	component ram_read_cache IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	END component ram_read_cache;
	 
	 
	 signal count : unsigned(9 downto 0) := (others => '0');
	 signal ram_addr : std_logic_vector(9 downto 0);
	 signal en: std_logic := '1';
	 signal fifo_we : std_logic;
	 
begin
	process(clk,rst)
	begin
		if rst = '0' then
			count <= (others => '0');
		elsif rising_edge(clk) and we = '1' then
			count <= count + 1;
		end if;
	end process;
	

	fifo_we <= we when en = '1' else '0';
	
	
	Read_cache: ram_read_cache
	PORT MAP
	(
		address		=> ram_addr,
		clock		=> clk,
		data		=> din,
		wren		=> fifo_we,
		q			=> dout
	);
	
	ram_addr <= addr when fifo_we = '0' else std_logic_vector(count);
	full <= '1' when count = 1023 else '0';
	empty <= '1' when count = 0 else '0';
	
	
	
end architecture;
