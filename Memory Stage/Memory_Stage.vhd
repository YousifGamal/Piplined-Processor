LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

ENTITY Memory_stage_entity IS
	PORT(
		clk,reset,
		reg1_wr_ex,reg2_wr_ex : IN std_logic;
		dst1_add_ex,dst2_add_ex : IN std_logic_vector(2 downto 0);
		mem_rd_ex,mem_wr_ex,out_ex,in_ex,
		call_ex,inc_ex,dec_ex,ret_ex,rti_ex,int_ex,
		ALU,dp1,dp2: IN  std_logic;
		address_dst1_ex,data_dst2_ex,dst1_mem,dst2_mem,pc_ex_mem,input_port  : IN  std_logic_vector(31 DOWNTO 0);
		reg1_wr_ex_output,reg2_wr_ex_output : OUT std_logic;
		dst1_add_ex_output,dst2_add_ex_output : OUT std_logic_vector(2 downto 0);
		dst1_mem_output,dst2_mem_output,out_port_output,mem_data_to_fetch : OUT std_logic_vector(31 DOWNTO 0);
		flag_from_execute : in std_logic_vector(3 downto 0);
		flag_to_execute : out std_logic_vector(3 downto 0);
		jz_flag_input : in std_logic
		);
END ENTITY Memory_stage_entity;

ARCHITECTURE Memory_stage_arch OF Memory_stage_entity IS

--Latch component
component WAR_latch is
  port (
    d: in std_logic;
    clk: in std_logic;
    clear: in std_logic;
enable: in std_logic;
    q: out std_logic

  ) ;
 end component;

--generic latch component
component generic_WAR_reg is
GENERIC(
   REG_WIDTH : INTEGER := 16);
  port (
    d: in std_logic_vector (REG_WIDTH - 1 downto 0);
    clk: in std_logic;
    clear: in std_logic;
enable: in std_logic;
    q: out std_logic_vector (REG_WIDTH - 1 downto 0)

  ) ;
end component; 
 
--stack reg component
component stack_reg is
GENERIC(
   REG_WIDTH : INTEGER := 16);
  port (
    d: in std_logic_vector (REG_WIDTH - 1 downto 0);
    clk: in std_logic;
    clear: in std_logic;
enable: in std_logic;
    q: out std_logic_vector (REG_WIDTH - 1 downto 0)

  ) ;
end component; 

--mux2_generic component
component mux2_generic is
GENERIC(
   INPUT_WIDTH : INTEGER := 1);
  port (
    in1,in2: in std_logic_vector (INPUT_WIDTH - 1 downto 0);
sel: in std_logic;
    mux_out: out std_logic_vector (INPUT_WIDTH - 1 downto 0)
    );

end component;

--mux4_generic component
component mux4_generic is
GENERIC(
   INPUT_WIDTH : INTEGER := 16);
  port (
    inp0: IN std_logic_vector (INPUT_WIDTH - 1 downto 0);
	 inp1: IN std_logic_vector (INPUT_WIDTH - 1 downto 0);
 inp2: IN std_logic_vector (INPUT_WIDTH - 1 downto 0);
 inp3: IN std_logic_vector (INPUT_WIDTH - 1 downto 0);
    sel: in std_logic_vector (1 downto 0);
    mux_output: out std_logic_vector(INPUT_WIDTH - 1 downto 0)
  ) ;
end component ;

-- data memory component
component dataMemory IS
	PORT(
		clk : IN std_logic;
		we  : IN std_logic;
		re : IN std_logic;
		address : IN  std_logic_vector(31 DOWNTO 0);
		datain  : IN  std_logic_vector(31 DOWNTO 0);
		dataout : OUT std_logic_vector(31 DOWNTO 0));
END component;


signal RF,SF,FlagRegEnable,WR_sig,RD_sig,
		incSpWire,decSpWire,
		int_latch_out : std_logic;
signal FlagRegInput,Flag4BitsOutput : std_logic_vector(3 downto 0);
signal Flag_CT,current_address,current_address_final,
	current_data,datamem1,dataMem2,dp1MuxOutput,dataInputCurrentData,
	dst2_mem_wire,
	pc_ex_mem_latch,pc_ex_mem_wire : std_logic_vector(31 downto 0);

SIGNAL current_address_value  : integer := 0;
SIGNAL spInputData  : std_logic_vector (31 downto 0) := ("00000000000000000000001111111111");
SIGNAL spOutputData,updateSpInput,updateSpPlusTwo,updateSpMinusTwo,dp1MuxStackPointerOutput : std_logic_vector(31 downto 0);
SIGNAL spInputDataAux,spOutputDataAux,updateSpInputAux,data_dst_dp : std_logic_vector(31 downto 0);
signal currentDataSel,updateSpSel : std_logic_vector(1 downto 0);
signal data_mem_flag : std_logic_vector(3 downto 0);
BEGIN

	--RF signal
		RFlatch : WAR_latch port map(rti_ex,clk,reset,'1',RF); 
	--SF signal
		SF <= int_ex;	
	--int latch
		Intlatch : WAR_latch port map(int_ex,clk,reset,'1',int_latch_out);
	--pc temp latch
		pcTempLatch: generic_WAR_reg GENERIC MAP (REG_WIDTH => 32) port map(pc_ex_mem,clk,reset,'1',pc_ex_mem_latch);

	--Flag Register Part
		-- 4 Bit Flag Register
		data_mem_flag <= datamem1(3) & datamem1(2) & datamem1(1) & datamem1(0);
		FlagRegMux: mux2_generic GENERIC MAP (INPUT_WIDTH => 4) port map(flag_from_execute,data_mem_flag,RF,FlagRegInput); -- take careajfdsjfsjfjsdjfsadfjsadjfsadjfljsadfjsjfj
		FlagRegEnable <= RF or ALU or jz_flag_input; -- jz_flag_input is added 
		Flag4BitsReg : generic_WAR_reg GENERIC MAP (REG_WIDTH => 4) port map(FlagRegInput,clk,reset,FlagRegEnable,Flag4BitsOutput);
		flag_to_execute <= Flag4BitsOutput;
		--concatinating the output with 28 bits
		Flag_CT <= "0000000000000000000000000000" & Flag4BitsOutput;
		
	--Current data part
		currentDataSel <= (call_ex or int_latch_out) & SF; --selector of this part
		dp1MuxdstMem1dstMem2 : mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(dst2_mem_wire,dp1MuxOutput,dp1,data_dst_dp);
		pc_ex_mem_wire <= pc_ex_mem_latch when int_latch_out = '1' else pc_ex_mem;
		CurrentDataBlock : mux4_generic GENERIC MAP (INPUT_WIDTH => 32) port map(data_dst_dp,Flag_CT,pc_ex_mem_wire,"UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU",currentDataSel,current_data);
		
	
	
	--Data Memory Part
		dp1Mux: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(address_dst1_ex,dst1_mem,dp1,dp1MuxOutput);
		dp2Mux: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(data_dst2_ex,dst2_mem,dp2,dst2_mem_wire);
		
		--Read and Write signals
		RD_sig <= RF or mem_rd_ex or ret_ex or rti_ex;
		WR_sig <= SF or mem_wr_ex or int_latch_out;
		
		current_address_value <= to_integer(unsigned(current_address));
		current_address_final <= current_address when current_address_value < 1024 and current_address_value >= 0 else "00000000000000000000000000000000"; --sfdfsfsdfadsfjsdlfjasjfjsafjlsdjfldsjfjsddfj
		dataMemComponent : dataMemory port map(clk,WR_sig,RD_sig,current_address_final,current_data,datamem1);
		mem_data_to_fetch <= datamem1;
		
		dp1MuxDataMem1: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(dp1MuxOutput,datamem1,RD_sig,dataMem2);
		inputPortMuxDataMem2: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(dataMem2,input_port,in_ex,dst1_mem_output);
		
	--output port part
		--OutPortLatch : generic_WAR_reg GENERIC MAP (REG_WIDTH => 32) port map(dst2_mem_wire,clk,reset,out_ex,out_port_output); -- here we used wire because we need the dst2_mem output to be "input" in the out port
		out_port_output <= dst2_mem_wire when out_ex = '1' else "00000000000000000000000000000000";
	--sp part
		
		--sp Latch
		spLatch: stack_reg GENERIC MAP (REG_WIDTH => 32) port map(updateSpInput,clk,reset,'1',spOutputData);
		
		--incSpWire
		incSpWire <= inc_ex or RF or rti_ex or ret_ex;
		--decSpWire
		decSpWire <= dec_ex or int_latch_out or call_ex or SF;
		--updateSp Latch
		updateSpPlusTwo <= spOutputData + 1;
		updateSpMinusTwo <= spOutputData - 1;
		--mux41 of assigning the updateSpInput
		updateSpSel <= decSpWire & incSpWire;
		spUpdateInputMux : mux4_generic GENERIC MAP (INPUT_WIDTH => 32) port map(spOutputData,updateSpPlusTwo,updateSpMinusTwo,"UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU",updateSpSel,updateSpInput);
		
		--updateSpLatch: stack_reg GENERIC MAP (REG_WIDTH => 32) port map(updateSpInput,clk,reset,'1',spInputData);
		--dp1MuxOutputMuxspOutput
		dp1MuxOutputMuxspOutput: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(dp1MuxOutput,spOutputData,decSpWire,dp1MuxStackPointerOutput);
		--dp1MuxStackPointerOutput Mux spInput
		dp1MuxSPOutputMuxspInput: mux2_generic GENERIC MAP (INPUT_WIDTH => 32) port map(dp1MuxStackPointerOutput,updateSpInput,incSpWire,current_address);
		
	--Output wires of this stage
		reg1_wr_ex_output <= reg1_wr_ex;
		reg2_wr_ex_output <= reg2_wr_ex;
		dst1_add_ex_output <= dst1_add_ex;
		dst2_add_ex_output <= dst2_add_ex;
		--dst1_mem_output is assigned above
		dst2_mem_output <= dst2_mem_wire;
END Memory_stage_arch;



