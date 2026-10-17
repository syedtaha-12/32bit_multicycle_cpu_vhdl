library ieee;
use ieee.std_logic_1164.ALL;

ENTITY Control_NEW IS
	PORT(
			clk, mclk						: IN	STD_LOGIC;
			enable							: IN	STD_LOGIC;
			statusC, statusZ				: IN	STD_LOGIC;
			INST								: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			A_MUX, B_MUX					: OUT	STD_LOGIC;
			IM_MUX1, REG_Mux				: OUT	STD_LOGIC;
			IM_MUX2, DATA_Mux				: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALU_op							: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			inc_PC, ld_PC					: OUT	STD_LOGIC;
			clr_IR							: OUT	STD_LOGIC;
			ld_IR								: OUT	STD_LOGIC;
			clr_A, clr_B, clr_C, clr_Z	: OUT	STD_LOGIC;
			ld_A, ld_B, ld_C, ld_Z		: OUT	STD_LOGIC;
			T									: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			wen, en							: OUT	STD_LOGIC
	);
END Control_NEW;

ARCHITECTURE description OF Control_NEW IS
	TYPE STATETYPE IS (state_0, state_1, state_2);
	SIGNAL present_state: STATETYPE := state_0;
	SIGNAL Instruction_sig: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL Instruction_sig2: STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
	Instruction_sig <= INST(31 DOWNTO 28);
	Instruction_sig2 <= INST(31 DOWNTO 24);
	
	------- OPERATION DECODER -------
	PROCESS (present_state, INST, statusC, statusZ, enable, Instruction_sig, Instruction_sig2)
	BEGIN
		-- Default values to prevent latches
		A_MUX <= '0';
		B_MUX <= '0';
		IM_MUX1 <= '0';
		REG_Mux <= '0';
		IM_MUX2 <= "00";
		DATA_Mux <= "11";
		ALU_op <= "000";
		inc_PC <= '0';
		ld_PC <= '0';
		clr_IR <= '0';
		ld_IR <= '0';
		clr_A <= '0';
		clr_B <= '0';
		clr_C <= '0';
		clr_Z <= '0';
		ld_A <= '0';
		ld_B <= '0';
		ld_C <= '0';
		ld_Z <= '0';
		wen <= '0';
		en <= '0';

		if enable = '1' then
			if present_state = state_0 then
				DATA_Mux <= "00";	-- Fetch next instruction
				ld_IR <= '1';

			elsif present_state = state_1 then
				ld_PC <= '1';
				inc_PC <= '1';
				
				if Instruction_sig = "0010" then -- STA
					REG_Mux <= '0';
					DATA_Mux <= "00";
					en <= '1';
					wen <= '1';
					
				elsif Instruction_sig = "0011" then -- STB
					REG_Mux <= '1';
					DATA_Mux <= "00";
					en <= '1';
					wen <= '1';
					
				elsif Instruction_sig = "1001" then -- LDA
					ld_A <= '1';
					A_MUX <= '0';
					DATA_Mux <= "01";
					en <= '1';
					wen <= '0';
					
				elsif Instruction_sig = "1010" then -- LDB
					ld_B <= '1';
					B_MUX <= '0';
					DATA_Mux <= "01";
					en <= '1';
					wen <= '0';

				elsif Instruction_sig = "0110" or Instruction_sig = "1000" then -- BEQ / BNE
					-- Compare A and B (A - B) so Z is valid for the branch decision in state_2
					ld_Z <= '1';
					ALU_op <= "110";
					IM_MUX1 <= '0';
					IM_MUX2 <= "00";

				elsif Instruction_sig = "0100" then -- LUI
					-- Clear B early so it is 0 when T2 computes UZE(IR) + B
					clr_B <= '1';
				end if;

			elsif present_state = state_2 then
				if Instruction_sig = "0101" then -- JUMP
					ld_PC <= '1';
					inc_PC <= '0';
					
				elsif Instruction_sig = "0110" then -- BEQ
					if statusZ = '1' then
						ld_PC <= '1';
						inc_PC <= '0';
					end if;

				elsif Instruction_sig = "1000" then -- BNE
					if statusZ = '0' then
						ld_PC <= '1';
						inc_PC <= '0';
					end if;
				
				elsif Instruction_sig = "1001" then -- LDA
					ld_A <= '1';
					A_MUX <= '0';
					DATA_Mux <= "01";
					en <= '1';
					wen <= '0';
					
				elsif Instruction_sig = "1010" then -- LDB
					ld_B <= '1';
					B_MUX <= '0';
					DATA_Mux <= "01";
					en <= '1';
					wen <= '0';
					
				elsif Instruction_sig = "0010" then -- STA
					REG_Mux <= '0';
					DATA_Mux <= "00";
					en <= '1';
					wen <= '1';
					
				elsif Instruction_sig = "0011" then -- STB
					REG_Mux <= '1';
					DATA_Mux <= "00";
					en <= '1';
					wen <= '1';
					
				elsif Instruction_sig = "0000" then -- LDAI
					ld_A <= '1';
					A_MUX <= '1';
					
				elsif Instruction_sig = "0001" then -- LDBI
					ld_B <= '1';
					B_MUX <= '1';
					
				elsif Instruction_sig = "0100" then -- LUI
					ld_A <= '1';
					clr_B <= '1';
					ALU_op <= "010"; -- A <= UZE(IR) + B, with B already cleared in T1
					A_MUX <= '0';
					DATA_Mux <= "10";
					IM_MUX1 <= '1';
					IM_MUX2 <= "00";
					
				elsif Instruction_sig2 = "01111001" then -- ANDI
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "000";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "01";
					
				elsif Instruction_sig2 = "01111110" then -- DECA
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "110";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "10";
					
				elsif Instruction_sig2 = "01110000" then -- ADD
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "010";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "00";
					
				elsif Instruction_sig2 = "01110010" then -- SUB
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "110";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "00";
					
				elsif Instruction_sig2 = "01110011" then -- INCA
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "010";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "10";
					
				elsif Instruction_sig2 = "01111011" then -- AND
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "000";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "00";
					
				elsif Instruction_sig2 = "01110001" then -- ADDI
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "010";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "01";
					
				elsif Instruction_sig2 = "01111101" then -- ORI
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "001";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					IM_MUX2 <= "01";
					
				elsif Instruction_sig2 = "01110100" then -- ROL
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "100";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					
				elsif Instruction_sig2 = "01111111" then -- ROR
					ld_A <= '1';
					ld_C <= '1';
					ld_Z <= '1';
					ALU_op <= "101";
					DATA_Mux <= "10";
					IM_MUX1 <= '0';
					
				elsif Instruction_sig2 = "01110101" then -- CLR_A
					clr_A <= '1';
					
				elsif Instruction_sig2 = "01110110" then -- CLR_B
					clr_B <= '1';
					
				elsif Instruction_sig2 = "01110111" then -- CLR_C
					clr_C <= '1';
					
				elsif Instruction_sig2 = "01111000" then -- CLR_Z
					clr_Z <= '1';
					
				elsif Instruction_sig2 = "01111010" then -- TSTZ
					if statusZ = '1' then
						ld_PC <= '1';
						inc_PC <= '1';
					end if;
					
				elsif Instruction_sig2 = "01111100" then -- TSTC
					if statusC = '1' then
						ld_PC <= '1';
						inc_PC <= '1';
					end if;
				end if;
			end if;
		end if;
	END PROCESS;

	-------- STATE MACHINE --------
	PROCESS (clk)
	begin
		if rising_edge(clk) then
			if enable = '0' then
				present_state <= state_0;
			else
				if present_state = state_0 then
					present_state <= state_1;
				elsif present_state = state_1 then
					present_state <= state_2;
				else
					present_state <= state_0;
				end if;
			end if;
		end if;
	END PROCESS;
	
	WITH present_state select
		T <= "001" when state_0,
			  "010" when state_1,
			  "100" when state_2,
			  "001" when others;

END description;