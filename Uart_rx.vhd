library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx is
	generic (
		baudrate	: integer := 300;
		DATA_WIDTH	: integer := 8
	);
	port (
		clock		: in  std_logic; --Entrar com o clock de 50MHz do FPGA
		reset		: in  std_logic; --Reset, Lembre q o FPGA é active low, se aperta o botao o reset vai para 0
		sin			: in  std_logic; --Entrada da antena
		dado		: out std_logic_vector(7 downto 0); --Saida do receptor
		fim			: out std_logic --Sinal de controle da saida, So ler o valor de dado quando este sinal estiver em 1
	);
end rx;
		  									    		          	  
architecture exemplo of rx is 

	signal clockdiv  : std_logic := '0';
	signal IQ		 : unsigned(25 downto 0);
	signal IQ2		 : unsigned(3 downto 0);
	signal buff		 : std_logic_vector(8 downto 0);
	signal tick      : std_logic;
	signal encount	 : std_logic;
	signal resetcount: std_logic;
	
	type tipo_estado is (inicial, sb, dx, final);
	signal estado   : tipo_estado;

begin 
	
	-- ===========================
	-- Divisor de clock
	-- ===========================
	process(clock, reset, IQ, clockdiv)
	begin
		if reset = '1' then
			IQ <= (others => '0');
		elsif clock'event and clock = '1' then
			if IQ = 50000000/(baudrate*16*2) then
				clockdiv <= not(clockdiv);
				IQ <= (others => '0');
			else
				IQ <= IQ + 1;
			end if;
		end if;
	end process;

	-- ===========================
	-- Superamostragem 16x
	-- ===========================		
	process(clockdiv, resetcount, encount)
	begin
		if resetcount = '1' then
			IQ2	  <= (others => '0');
		elsif clockdiv'event and clockdiv = '1' and encount = '1' then
			IQ2 <= IQ2 + 1;
		end if;
	end process;

	tick <= '1' when IQ2 = 8 else '0';

	-- ===========================
	-- Maquina de Estados do Transmissor
	-- ===========================
	process(clockdiv, reset, sin, tick, estado)
	variable i: integer := 0;
	begin
		if reset = '1' then
			estado <= inicial;
			
		elsif clockdiv'event and clockdiv = '1' then
			case estado is
				
				when inicial => if 	  sin = '0' then estado   <= sb;
								else estado   <= inicial; 
								end if;
				
				when sb      => if 	 tick = '1' then estado   <= d0;
								else estado   <= sb;
								end if;
								buff <= "000000000";
									 
				when dx      => if 	 tick = '1' and i = DATA_WIDTH then estado   <= d1;
									buff(i)  <= sin;
									i := i + 1;
								else estado   <= dx;
								end if;
									 					 
				when final   => if 	 tick = '1' then 
									estado   <= inicial;
									i := 0;
								else estado   <= final;
								end if;		
									 
				when others => estado <= inicial;
			end case;
		end if;
	end process;
	
	with estado select encount <=
		'0' when inicial,
		'1' when others;

	with estado select resetcount <=
		'1' when inicial,
		'0' when others;
		
	-- ===========================
	-- Logica de saida
	-- ===========================
	with estado select fim <=
		'1' when final,
		'0' when others;
		
	dado <= buff(7 downto 0);
end exemplo;