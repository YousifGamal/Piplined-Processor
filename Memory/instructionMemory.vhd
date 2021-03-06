LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY instructionMemory IS
	PORT(
		clk : IN std_logic;
		we  : IN std_logic;
		PCaddress : IN  std_logic_vector(31 DOWNTO 0);
		datain : IN std_logic_vector(15 DOWNTO 0 );
		instruction : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY instructionMemory;

ARCHITECTURE instructionMemoryArch OF instructionMemory IS

	TYPE ram_type IS ARRAY(0 TO 2047) OF std_logic_vector(15 DOWNTO 0);
	SIGNAL ram : ram_type ;
	
	BEGIN
		PROCESS(clk) IS
			BEGIN
				IF rising_edge(clk) THEN
				--THE RAM WOULD RETRIVE NOTHING IN CASE OF ADDRESS = "ZZZZZZ"  
					IF we = '1' THEN
						ram(to_integer(unsigned(PCaddress))) <= datain;
					END IF;
				END IF;
		END PROCESS;
		--THE RAM WOULD RETRIVE NOTHING IN CASE OF ADDRESS = "ZZZZZZ"
		instruction <= ram(to_integer(unsigned(PCaddress)));
END instructionMemoryArch;

