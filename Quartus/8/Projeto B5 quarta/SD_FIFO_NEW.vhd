library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SD_FIFO_16x1K is
    port (
		wr_clk	  : in  std_logic;
		r_clk	  : in  std_logic;
		load_b: in  std_logic;
		rst   : in  std_logic;
		din   : in  std_logic_vector (7 downto 0);
		dout  : out std_logic_vector (15 downto 0);
		handshake: out  std_logic;
		we	   : in std_logic;
		re		: in std_logic;
		empty : out std_logic;
		full  : out std_logic;
		w_data   : out STD_LOGIC_VECTOR (15 downto 0);
		f_we  : out std_logic
    );
end SD_FIFO_16x1K;

architecture rtl of SD_FIFO_16x1K is

	component FIFO_16x1K IS
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC
	);
	END component FIFO_16x1K;

	 
	type estados is (espera1, espera2, byte1, byte2, dump, dump2);
	signal estado: estados := espera1;
	
	signal count : unsigned(12 downto 0) := (others => '0');
	signal ram_data : std_logic_vector(15 downto 0) := (others => '0');
	signal fifo_we  : std_logic;
	 
begin

	process(wr_clk,rst)
	begin
		if rst = '1' then
			estado <= espera1;
			count <= (others => '0');
			fifo_we <= '0';
		elsif rising_edge(wr_clk) and we='1' then
			case estado is
			when espera1 =>
				fifo_we <= '0';
				handshake <= '0';
				if load_b = '1' then
					estado <= byte1;
				end if;
			when byte1 =>
				handshake <= '1';
				estado <= espera2;
			when espera2 =>
				ram_data(15 downto 8) <= din;
				handshake <= '0';
				if load_b = '1' then
					estado <= byte2;
				end if;
			when byte2 =>
				handshake <= '0';
				estado <= dump;
				fifo_we <= '0';
			when dump =>
				ram_data(7 downto 0) <= din;
				handshake <= '1';
				estado <= dump2;
				fifo_we <= '0';
			when dump2 =>
				handshake <= '0';
				estado <= espera1;
				fifo_we <= '1';
				count <= count + 1;
			end case;
		end if;
	end process;
	
	w_data <= ram_data;
	f_we <= fifo_We;
	
	fifo_1: FIFO_16x1K
	PORT MAP
	(
		aclr    	=> rst,
		data		=> ram_data,
		rdclk		=> r_clk,
		rdreq		=> re,
		wrclk		=> wr_clk,
		wrreq		=> fifo_we,
		q			=> dout,
		rdempty		=> empty,
		wrfull		=> full
	);
end architecture;
