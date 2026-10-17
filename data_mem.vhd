library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_mem is
port( 
	clk 			:	in std_logic; -- clock
	addr 			: 	in unsigned(7 downto 0); -- 8 bit address
	data_in 		: 	in std_logic_vector (31 downto 0); -- data_in
	wen			: 	in std_logic; -- write enable
	en				:  in std_logic; -- enable
	data_out 	:  out std_logic_vector(31 downto 0) -- data_out
);
end data_mem;

architecture Behaviour of data_mem is
	type RAM is array (0 to 255) of std_logic_vector(31 downto 0);
	signal DATAMEM : RAM;
begin
	process(clk, en, wen)
	begin
		if(clk'event and clk = '0') then
			if(en = '0') then 
				data_out <= (others => '0');
			else
				if(wen = '0') then 
					data_out <= DATAMEM(to_integer(addr));
				end if;
				if(wen = '1') then
					DATAMEM(to_integer(addr)) <= data_in; 
					data_out <= (others => '0');
				end if;
			end if;
		end if;
	end process;
end Behaviour;