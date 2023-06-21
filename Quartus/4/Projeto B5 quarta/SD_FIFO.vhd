library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SD_FIFO_512 is
    port (
		  clk	  : in  std_logic;
        load_b: in  std_logic;
        rst   : in  std_logic;
        din   : in  std_logic_vector (7 downto 0);
		  addr  : in  std_logic_vector (7 downto 0);
        dout  : out std_logic_vector (15 downto 0);
		  handshake: out  std_logic
    );
end SD_FIFO_512;

architecture rtl of SD_FIFO_512 is
    type reg_array is array (0 to 255) of std_logic_vector(15 downto 0);
    signal regs: reg_array := (others => (others => '0'));
	 signal count : unsigned(7 downto 0) := (others => '0');
	 
	 type estados is (espera1, espera2, byte1, byte2);
	 signal estado: estados := espera1;
	 
	 
	 component detector_borda is
		generic (
			subida : boolean := true
		);
		port (
			clk	: in std_logic;
			rst	: in std_logic;
			borda	: in std_logic;
			update: out std_logic
		);
	end component detector_borda;
	 
	 signal update : std_logic;
begin

	sync: detector_borda
	port map(
		clk	=> clk,
		rst	=> '1',
		borda	=> load_b,
		update=> update
	);
	 
	process(clk)
	begin
		if rst = '1' then
			regs <= (others => (others => '0'));
			estado <= espera1;
			count <= (others => '0');
		elsif rising_edge(clk) then
			case estado is
			when espera1 =>
				handshake <= '0';
				if load_b = '1' then
					estado <= byte1;
				end if;
			when byte1 =>
				handshake <= '1';
				regs(to_integer(count)) <= din&x"00";
				estado <= espera2;
			when espera2 =>
				handshake <= '0';
				if load_b = '1' then
					estado <= byte2;
				end if;
			when byte2 =>
				handshake <= '1';
				regs(to_integer(count)) <= regs(to_integer(count))(15 downto 8)&din;
				estado <= espera1;
				count <= count + 1;
			end case;
		end if;
	end process;
	
	dout <= regs(to_integer(unsigned(addr)));
	
end architecture;
