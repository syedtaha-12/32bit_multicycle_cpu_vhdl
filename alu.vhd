library ieee;
use ieee.std_logic_1164.all;

entity alu is
port(
	a      : in std_logic_vector(31 downto 0);
	b      : in std_logic_vector(31 downto 0);
	op     : in std_logic_vector(2 downto 0);
	result : out std_logic_vector(31 downto 0);
	zero   : out std_logic;
	cout   : out std_logic
);
end alu;

architecture Behaviour of alu is
	component adder32
		port(
			Cin  : in std_logic;
			X, Y : in std_logic_vector(31 downto 0);
			S    : out std_logic_vector(31 downto 0);
			Cout : out std_logic
		);
	end component;

	signal result_s   : std_logic_vector(31 downto 0) := (others => '0');
	signal result_add : std_logic_vector(31 downto 0) := (others => '0');
	signal result_sub : std_logic_vector(31 downto 0) := (others => '0');
	signal cout_s     : std_logic := '0';
	signal cout_add   : std_logic := '0';
	signal cout_sub   : std_logic := '0';
begin

	add0 : adder32 port map('0', a, b, result_add, cout_add);
	sub0 : adder32 port map('1', a, not b, result_sub, cout_sub);

	process(a, b, op, result_add, result_sub, cout_add, cout_sub)
	begin
		case op is
			when "000" =>  -- AND
				result_s <= a and b;
				cout_s <= '0';

			when "001" =>  -- OR
				result_s <= a or b;
				cout_s <= '0';

			when "010" =>  -- ADD
				result_s <= result_add;
				cout_s <= cout_add;

			when "011" =>  -- PASS B
				result_s <= b;
				cout_s <= '0';

			when "110" =>  -- SUB
				result_s <= result_sub;
				cout_s <= not cout_sub;

			when "100" =>  -- ROL: A << 1 (per CPU spec)
				result_s <= a(30 downto 0) & '0';
				cout_s <= a(31);

			when "101" =>  -- ROR: A >> 1 (per CPU spec)
				result_s <= '0' & a(31 downto 1);
				cout_s <= a(0);

			when others =>
				result_s <= a;
				cout_s <= '0';
		end case;
	end process;

	result <= result_s;
	cout <= cout_s;
	zero <= '1' when result_s = x"00000000" else '0';

end Behaviour;