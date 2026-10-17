library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pc is
port(
	clr  	: in std_logic; -- clears the bit register
	clk 	: in std_logic; -- clock
	ld		: in std_logic; -- load/enable
	inc 	: in std_logic; -- increment
	d 		: in std_logic_vector (31 downto 0);
	q 		: out std_logic_vector (31 downto 0) -- output
);
end pc;

architecture Behaviour of pc is
	component add
		port( A : in std_logic_vector (31 downto 0);
				B : out std_logic_vector (31 downto 0));
	end component;
	component mux2to1
		port( s		 : in std_logic;
				w0, w1 : in std_logic_vector (31 downto 0);
				f 		 : out std_logic_vector (31 downto 0));
	end component;
	component register32
		port ( 	d  	: in std_logic_vector (31 downto 0);
					ld 	: in std_logic; --load/enable
					clr	: in std_logic;
					clk 	: in std_logic;
					Q 		: out std_logic_vector (31 downto 0) --output
		);
	end component;
	signal add_out  : std_logic_vector (31 downto 0);
	signal mux_out  : std_logic_vector (31 downto 0);
	signal q_out 	 : std_logic_vector (31 downto 0);
	-- signal ld    : std_logic = '1';
begin
	add0: add port map(q_out, add_out);
	mux0: mux2to1 port map(inc, d, add_out, mux_out);
	reg0: register32 port map(mux_out, ld, clr, clk, q_out);
	q <= q_out;
end Behaviour;
