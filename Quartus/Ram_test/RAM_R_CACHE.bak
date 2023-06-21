library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SD_FIFO_16384 is
    port (
		  clk	  : in  std_logic;
        load_b: in  std_logic;
        rst   : in  std_logic;
        din   : in  std_logic_vector (7 downto 0);
		  addr  : in  std_logic_vector (12 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		  handshake: out  std_logic;
		  we	  : in std_logic
    );
end SD_FIFO_16384;

architecture rtl of SD_FIFO_16384 is

	component Ram_SD IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	END component Ram_SD;

	 
	 
	 type estados is (espera1, espera2, byte1, byte2, dump);
	 signal estado: estados := espera1;
	 
	 signal count : unsigned(12 downto 0) := (others => '0');
	 signal ram_addr : std_logic_vector(12 downto 0);
	 signal ram_data : std_logic_vector(15 downto 0);
	 signal fifo_we  : std_logic;
	 
begin
	process(clk,rst)
	begin
		if rst = '1' then
			estado <= espera1;
			count <= (others => '0');
			fifo_we <= '0';
		elsif rising_edge(clk) then
			case estado is
			when espera1 =>
				fifo_we <= '0';
				handshake <= '0';
				if load_b = '1' then
					estado <= byte1;
				end if;
			when byte1 =>
				handshake <= '1';
				ram_data(15 downto 8) <= din;
				estado <= espera2;
			when espera2 =>
				handshake <= '0';
				if load_b = '1' then
					estado <= byte2;
				end if;
			when byte2 =>
				handshake <= '0';
				ram_data(7 downto 0) <= din;
				estado <= dump;
				fifo_we <= '1';
			when dump =>
				handshake <= '1';
				estado <= espera1;
				fifo_we <= '0';
				count <= count + 1;
			end case;
		end if;
	end process;
	
	
	
	R_sd: Ram_SD
	PORT MAP
	(
		address	=> ram_addr,
		clock		=> clk,
		data		=> ram_data,
		wren		=> fifo_We,
		q			=> dout
	);
	ram_addr <= addr when we = '0' else std_logic_vector(count);
	
	
	
end architecture;
