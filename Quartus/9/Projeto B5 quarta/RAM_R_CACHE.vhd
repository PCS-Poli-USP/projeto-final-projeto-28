library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_R_CACHE is
    port (
		rd_clk: in  std_logic;
		wr_clk: in  std_logic;
        rst   : in  std_logic;
		we	  : in  std_logic;
        din   : in  std_logic_vector (15 downto 0);
		addr  : in  std_logic_vector (11 downto 0);
		cnt   : out std_logic_vector (11 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		empty : out std_logic;
		full  : out std_logic
    );
end RAM_R_CACHE;

architecture rtl of RAM_R_CACHE is
	
	component DPRAM_4Kx16b IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	end component DPRAM_4Kx16b;
	 
	signal fifo_we : std_logic;
	signal stop_we : std_logic;
	signal count : unsigned(11 downto 0) := (others => '0');
begin
	process(wr_clk,rst)
	begin
		if rst = '1' then
			count <= (others => '0');
			stop_we <= '0';
		elsif rising_edge(wr_clk) and we = '1' then
			if count /= x"fff" then
				count <= count + 1;
			else
				stop_we <= '1';
			end if;
		end if;
	end process;	
	
	fifo_we <= we when stop_we = '0' else '0';

	Read_cache: DPRAM_4Kx16b
	PORT MAP
	(
		data		=> din,
		rdaddress	=> addr,
		rdclock		=> rd_clk,
		wraddress	=> std_logic_vector(count),
		wrclock		=> wr_clk,
		wren		=> fifo_we,
		q			=> dout
	);
	
	cnt <= std_logic_vector(count);
	full <= '1' when count = 4095 else '0';
	empty <= '1' when count = 0 else '0';
	
	
	
end architecture;