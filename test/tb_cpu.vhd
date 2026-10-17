library ieee; use ieee.std_logic_1164.all;
entity tb_cpu is generic (CPU_HALF : time := 50 ns); end;
architecture sim of tb_cpu is
  signal cpuClk, memClk : std_logic := '0';
  signal rst : std_logic := '1';
  signal outA, outB, outIR, outPC, mdo, mdi : std_logic_vector(31 downto 0);
  signal outC, outZ, wEn, wen_mem, en_mem : std_logic;
  signal addrOut : std_logic_vector(5 downto 0);
  signal T : std_logic_vector(2 downto 0);
  signal done : boolean := false;
begin
  -- memClk 50 ns period; its falling edges line up with cpuClk rising edges
  memClk <= '1', '0' after 25 ns when now = 0 ns else not memClk after 25 ns when not done;
  process begin
    wait for 25 ns;
    while not done loop cpuClk <= '1'; wait for CPU_HALF; cpuClk <= '0'; wait for CPU_HALF; end loop;
    wait;
  end process;
  dut: entity work.CPU_TEST_Sim port map(cpuClk, memClk, rst, outA, outB, outC, outZ, outIR, outPC, addrOut, wEn, mdo, mdi, T, wen_mem, en_mem);
  process begin
    wait for 4*CPU_HALF; rst <= '0';
    for i in 0 to 200 loop
      wait until falling_edge(cpuClk);
      if T = "001" and outIR /= x"00000000" then  -- T0: previous instruction has completed
        report "after IR=" & to_hstring(outIR) & "  PC=" & to_hstring(outPC(7 downto 0)) & " A=" & to_hstring(outA) & " B=" & to_hstring(outB) & " C=" & std_logic'image(outC) & " Z=" & std_logic'image(outZ);
        assert outIR /= x"0000DEAD" report "EXECUTED A SKIPPED INSTRUCTION" severity error;
        if outIR = x"0000600D" then
          assert outA = x"0000600D" and outB = x"00000002" report "FINAL STATE WRONG" severity error;
          report "PROGRAM COMPLETED"; exit;
        end if;
      end if;
    end loop;
    done <= true; wait;
  end process;
end;
