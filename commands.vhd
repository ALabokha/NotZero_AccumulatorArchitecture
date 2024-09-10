library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package commands is

constant RAM_chunk_size: integer := 8;
constant RAM_address_width: integer := 6;
subtype RAM_chunk is std_logic_vector(RAM_chunk_size-1 downto 0);
subtype RAM_address_chunk is std_logic_vector(RAM_address_width-1 downto 0);

constant ROM_command_width: integer := 4;
constant ROM_operand_width: integer := RAM_chunk_size;
constant ROM_chunk_size: integer := ROM_command_width + ROM_operand_width;
constant ROM_address_width: integer := 6;
subtype ROM_chunk is std_logic_vector(ROM_chunk_size-1 downto 0);
subtype operand_chunk is std_logic_vector(ROM_operand_width-1 downto 0);
subtype command_chunk is std_logic_vector(ROM_command_width-1 downto 0);
subtype ROM_address_chunk is std_logic_vector(ROM_address_width-1 downto 0);

constant CMD_CLRF: command_chunk := (others => '0');	-- 0
constant CMD_MOVF: command_chunk := CMD_CLRF + "1";	-- 1
constant CMD_MOVWF: command_chunk := CMD_MOVF + "1";	-- 10
constant CMD_SUBLW: command_chunk := CMD_MOVWF + "1";	-- 11
constant CMD_SUBFW: command_chunk := CMD_SUBLW + "1";		-- 100
constant CMD_BTFSC: command_chunk := CMD_SUBFW + "1";		-- 101
constant CMD_BTFSS: command_chunk := CMD_BTFSC + "1";		-- 110
constant CMD_GOTO: command_chunk := CMD_BTFSS + "1";		-- 111
constant CMD_INCF: command_chunk := CMD_GOTO + "1";			-- 1000
constant CMD_DECF: command_chunk := CMD_INCF + "1";			-- 1001
constant CMD_END: command_chunk := CMD_DECF + "1";		-- 1010

constant REGFile_chunk_size: integer := RAM_address_width;
constant REGFile_address_width: integer := 2;
subtype REGFile_chunk is std_logic_vector(REGFile_chunk_size-1 downto 0);
subtype REGFile_address_chunk is std_logic_vector(REGFile_address_width-1 downto 0);

constant RAMAddressMax : integer := 2 ** RAM_address_width - 1;
type RAM_inner_data is array (0 to RAMAddressMax) of RAM_chunk;
constant REGFileAddressMax : integer := 2 ** REGFile_address_width - 1;
type REGFile_inner_data is array (0 to REGFileAddressMax) of REGFile_chunk;
constant ROMAddressMax : integer := 2 ** ROM_address_width - 1;
type ROM_inner_data is array (0 to ROMAddressMax) of ROM_chunk;

constant FSR_register: RAM_chunk := "00000010";
constant INDF_register: RAM_chunk := FSR_register + "1";

constant ROM_data_amount: ROM_inner_data := (
0 => CMD_CLRF & "00000000",			--clear result
1 => CMD_CLRF & "00000001",			--clear error code
2 => CMD_MOVF & "00000101",			--CMD_PUSH_R min_address
3 => CMD_SUBLW & "00000111",		--SUBSTRACT literal from top stack value
4 => CMD_BTFSC & "00000000", 		--BTFSC STATUS, 0
5 => CMD_GOTO & "00011100",			--GOTO SET ERROR CODE
6 => CMD_MOVF & "00000110",			--CMD_PUSH_R max_address
7 => CMD_SUBLW & "10000000",		--SUBSTRACT literal from top stack value
8 => CMD_BTFSS & "00000000", 		--BTFSC STATUS, 0
9 => CMD_GOTO & "00011100",			--GOTO SET ERROR CODE
10 => CMD_MOVF & "00000110",			--CMD_PUSH_R min address
11 => CMD_SUBFW & "00000101",	
12 => CMD_BTFSC & "00000000", 		--BTFSC STATUS, 0
13 => CMD_GOTO & "00011100",		--GOTO SET ERROR CODE
14 => CMD_MOVF & "00000110",		--CMD_PUSH_R max_address
15 => CMD_MOVWF & "00000100",		--CMD_POP to cur_address
--cycle 10000
16 => CMD_MOVF & "00000100",	
17 => CMD_MOVWF & FSR_register,		
18 => CMD_MOVF & INDF_register, 		
19 => CMD_SUBLW & "00000000",		--substract zero
20 => CMD_BTFSS & "00000001", 		--BTFSC STATUS, 2
21 => CMD_INCF & "00000000", 		--Inc non zero amount if zero flag isn't set
22 => CMD_DECF & "00000100", 		--decr current address
23 => CMD_MOVF & "00000100",		
24 => CMD_SUBFW & "00000101",		--SUB cur_address - min address
25 => CMD_BTFSS & "00000000", 		--BTFSS STATUS, 0
26 => CMD_GOTO & "00010000", 		--goto cycle
27 => CMD_GOTO & "00011101",		--GOTO WRITE RESULT
--set error code 11100
28 => CMD_INCF & "00000001",		--set, that error occured
--finish execution 11101
29 => CMD_END & "00000000",			--end
others => (others => '0')
);

constant ROM_data_amount_fast: ROM_inner_data := (
0 => CMD_CLRF & "00000000",			--clear result
1 => CMD_CLRF & "00000001",			--clear error code
2 => CMD_MOVF & "00000110",		--CMD_PUSH_R max_address
3 => CMD_MOVWF & "00000100",		--CMD_POP to cur_address
--cycle 00100
4 => CMD_MOVF & "00000100",	
5 => CMD_MOVWF & FSR_register,		
6 => CMD_MOVF & INDF_register, 		
7 => CMD_SUBLW & "00000000",		--substract zero
8 => CMD_BTFSS & "00000001", 		--BTFSC STATUS, 2
9 => CMD_INCF & "00000000", 		--Inc non zero amount if zero flag isn't set
10 => CMD_DECF & "00000100", 		--decr current address
11 => CMD_MOVF & "00000100",		
12 => CMD_SUBFW & "00000101",		--SUB cur_address - min address
13 => CMD_BTFSS & "00000000", 		--BTFSS STATUS, 0
14 => CMD_GOTO & "00000100", 		--goto cycle
15 => CMD_END & "00000000",			--end
others => (others => '0')
);

constant RAM_data_amount: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
--2 and 3 addresses reserved for FSR and INDF
4 => "00000000", 	--current address
5 => "00000111", 	--min_address
6 => "01111111", 	--max_address
--data array 0 to 7
7 => "00010011",
10 => "00000111",
11 => "10000000",
12 => "00001010", 
others => (others => '0')
);

constant RAM_wrong_adresses: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
--2 and 3 addresses reserved for FSR and INDF
4 => "00000000", 	--current address
5 => "00000110", 	--min_address
6 => "00001110", 	--max_address
--data array 0 to 7
7 => "00000000",	
8 => "00110000",		
9 => "00010011",
10 => "00000000",
11 => "00000000",
12 => "00000111",
13 => "10000000",
14 => "00001010", 
others => (others => '0')
);

end commands;

--package body commands is
--end commands;
