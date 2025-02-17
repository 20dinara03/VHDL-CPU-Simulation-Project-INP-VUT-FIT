-- cpu.vhd: Simple 8-bit CPU (BrainFuck interpreter)
-- Copyright (C) 2022 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Garipova Dinara <xgarip00@stud.fit.vutbr.cz>
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(12 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_RDWR  : out std_logic;                    -- cteni (0) / zapis (1)
   DATA_EN    : out std_logic;                    -- povoleni cinnosti
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna
   IN_REQ    : out std_logic;                     -- pozadavek na vstup data
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- LCD je zaneprazdnen (1), nelze zapisovat
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is

--CNT--
 signal cnt_inc : std_logic;
 signal cnt_dec : std_logic;
 signal cnt_reg : std_logic_vector (12 downto 0) := (others => '0');

--PC--
  signal pc_reg : std_logic_vector (12 downto 0) := (others => '0');
  signal pc_inc : std_logic;
  signal pc_dec : std_logic;

--PTR--
 signal ptr_reg : std_logic_vector (12 downto 0) := (others => '0');
 signal ptr_inc : std_logic;
 signal ptr_dec : std_logic;

--MUL1--
 signal mul1_select : std_logic;

--MUL2--
 signal mul2_select : std_logic_vector (1 downto 0);

--STATES--
 type FSM_state is (
  s_begin,
  s_fetch,
  s_decode,
  s_ptr_inc,
  s_ptr_dec,
  s_value_inc,
  s_value_inc_end,
  s_value_dec,
  s_value_dec_end,
  s_while_start,
  s_while_start_1,
  s_while_start_2,
  s_while_end,
  s_while_end_1,
  s_while_end_2,
  s_do_while_start,
  s_do_while_end,
  s_do_while_end_1,
  s_do_while_end_2,
  s_putchar,
  s_putchar_end,
  s_getchar,
  s_null,
  s_new

);
signal FSM_cur_state : FSM_state := s_begin;
signal FSM_next_state : FSM_state;

begin

  --DATA_ADDR <= mul1_output;
  --DATA_WDATA <= mul2_output;
  --OUT_DATA <= DATA_RDATA; 

 --CNT--
 CNT: process (CLK,RESET,cnt_inc,cnt_dec) is
  begin
    if RESET = '1' then
      cnt_reg <= (others => '0');
    elsif rising_edge(CLK) then
      if cnt_inc = '1' then
        cnt_reg <= cnt_reg + 1;
      elsif cnt_dec = '1' then
        cnt_reg <= cnt_reg - 1;
      end if;
    end if;
  end process CNT;

  --PC--
  PC: process (CLK,RESET,pc_inc,pc_dec) is
  begin
    if RESET = '1' then
      pc_reg <= (others => '0');
    elsif rising_edge(CLK) then
      if pc_inc = '1' then
        pc_reg <= pc_reg + 1;
      elsif pc_dec = '1' then
        pc_reg <= pc_reg - 1;
      end if;
    end if;
  end process PC;

  --PTR--
  PTR: process (CLK,RESET,ptr_inc,ptr_dec) is
  begin
    if RESET = '1' then
      ptr_reg <= "1000000000000";
    elsif rising_edge(CLK) then
      if ptr_inc = '1' then
        ptr_reg <= ptr_reg + 1;
      elsif ptr_dec = '1' then
        ptr_reg <= ptr_reg - 1;
      end if;
    end if;
  end process PTR;

  --MUL1--  
  MUL1: process (CLK,RESET,mul1_select,ptr_reg, pc_reg) is
  begin
      if mul1_select = '0' then
        DATA_ADDR <= pc_reg;
      elsif mul1_select = '1' then
        DATA_ADDR <= ptr_reg;
      end if;
  end process MUL1;

  --MUL2--
  MUL2: process (CLK,RESET,mul2_select,IN_DATA,DATA_RDATA) is
  begin
      if mul2_select = "00" then
        DATA_WDATA <= IN_DATA;
      elsif mul2_select = "01" then
        DATA_WDATA <= DATA_RDATA - 1;
      elsif mul2_select = "10" then
        DATA_WDATA <= DATA_RDATA + 1;
      elsif mul2_select = "11" then
        DATA_WDATA <= (others => '0');
      end if;
  end process MUL2;

  

  --FSM current state--
  FSM_cur_state_proc: process (CLK,RESET, EN) is
  begin
    if RESET = '1' then
      FSM_cur_state <= s_begin;
    elsif rising_edge(CLK) and (EN = '1') then
      FSM_cur_state <= FSM_next_state;
    end if;
  end process;

  --FSM--
  FSM: process (FSM_cur_state, OUT_BUSY, IN_VLD, DATA_RDATA, cnt_reg) is
  begin
    pc_inc <= '0';
    ptr_inc <= '0';
    cnt_inc <= '0';
    pc_dec <= '0';
    ptr_dec <= '0';
    cnt_dec <= '0';
    mul1_select <= '0';
    mul2_select <= "11";
    IN_REQ <= '0';
    OUT_WE <= '0';
    DATA_RDWR <= '0';
    DATA_EN <= '0';

    if FSM_cur_state = s_begin then
      FSM_next_state <= s_fetch;
    elsif FSM_cur_state = s_fetch then
      DATA_EN <= '1';
      DATA_RDWR <= '0';
      mul1_select <= '0';
      FSM_next_state <= s_decode;
    elsif FSM_cur_state <= s_decode then
      if DATA_RDATA = X"3E" then
        FSM_next_state <= s_ptr_inc;
      elsif DATA_RDATA = X"3C" then
        FSM_next_state <= s_ptr_dec;
      elsif DATA_RDATA = X"2B" then
        FSM_next_state <= s_value_inc;
      elsif DATA_RDATA = X"2D" then
        FSM_next_state <= s_value_dec;
      elsif DATA_RDATA = X"5B" then
        FSM_next_state <= s_while_start;
      elsif DATA_RDATA = X"5D" then
        FSM_next_state <= s_while_end;
      elsif DATA_RDATA = X"28" then
        FSM_next_state <= s_do_while_start;
      elsif DATA_RDATA = X"29" then
        FSM_next_state <= s_do_while_end;
      elsif DATA_RDATA = X"2E" then
        FSM_next_state <= s_putchar;
      elsif DATA_RDATA = X"2C" then
        FSM_next_state <= s_getchar;
      elsif DATA_RDATA = X"00" then
        FSM_next_state <= s_null;
      else
         pc_inc <= '1';
         FSM_next_state <= s_new;
      end if;
      DATA_EN <= '1';
	  DATA_RDWR <= '0';
      mul1_select <= '0';
    --
    elsif FSM_cur_state = s_new then
      FSM_next_state <= s_fetch;
    
    --
    elsif FSM_cur_state = s_ptr_inc then
      pc_inc <= '1';
      ptr_inc <= '1';
      FSM_next_state <= s_fetch;
          
    elsif FSM_cur_state = s_ptr_dec then
      pc_inc <= '1';
      ptr_dec <= '1';
      FSM_next_state <= s_fetch;


    elsif FSM_cur_state = s_value_inc then
      DATA_EN <= '1';
	  DATA_RDWR <= '0';
      mul1_select <= '1';
      FSM_next_state <= s_value_inc_end;
      
    
    elsif FSM_cur_state = s_value_inc_end then
      mul2_select <= "10";
      DATA_EN <= '1';
      DATA_RDWR <= '1';
      pc_inc <= '1';
      mul1_select <= '1';
      Fsm_next_state <= s_fetch;

    elsif FSM_cur_state = s_value_dec then
      mul1_select <= '1';
      DATA_EN <= '1';
      DATA_RDWR <= '0';
      FSM_next_state <= s_value_dec_end;
    
    elsif FSM_cur_state = s_value_dec_end then
      DATA_EN <= '1';
      DATA_RDWR <= '1';
      mul2_select <= "01";
      mul1_select <= '1';
      pc_inc <= '1';
      Fsm_next_state <= s_fetch;

    elsif FSM_cur_state = s_putchar then
      DATA_EN <= '1';
      DATA_RDWR <= '0';
      mul1_select <= '1'; 
      if OUT_BUSY = '0' then 
      FSM_next_state <= s_putchar_end;
     elsif OUT_BUSY = '0' then
      FSM_next_state <= s_putchar;
    end if;

  elsif FSM_cur_state = s_putchar_end then
    OUT_WE <= '1';
    pc_inc <= '1';
    OUT_DATA <= DATA_RDATA;
    FSM_next_state <= s_fetch;

  elsif FSM_cur_state = s_getchar then
    IN_REQ <= '1';
    mul2_select <= "00";
    mul1_select <= '1';
    DATA_EN <= '1';
    if IN_VLD = '1' then 
     DATA_RDWR <= '1';
     pc_inc <= '1';
     FSM_next_state <= s_fetch;
    else
      FSM_next_state <= s_getchar;
    end if;


  elsif FSM_cur_state = s_while_start then
    pc_inc <= '1';
    mul1_select <= '1';
    FSM_next_state <= s_while_start_1;

  elsif FSM_cur_state = s_while_start_1 then
    if DATA_RDATA = "00000000" then 
     DATA_EN <= '1';
     DATA_RDWR <= '0';
     mul1_select <= '0';
     FSM_next_state <= s_while_start_2;
    else
      FSM_next_state <= s_fetch;
    end if;
  elsif FSM_cur_state = s_while_start_2 then
    DATA_EN <= '1';
    DATA_RDWR <= '0';
    mul1_select <= '0';
    if DATA_RDATA = X"5D" then
     FSM_next_state <= s_fetch;
    else
      FSM_next_state <= s_while_start_2;
    end if;
    pc_inc <= '1';

  elsif FSM_cur_state = s_while_end then
    DATA_EN <= '1';
    DATA_RDWR <= '0';
    mul1_select <= '1';
    FSM_next_state <= s_while_end_1;

  elsif FSM_cur_state = s_while_end_1 then
    mul1_select <= '0';
    if DATA_RDATA /= "00000000" then 
     FSM_next_state <= s_while_end_2;
    else
      FSM_next_state <= s_fetch;
      pc_inc <= '1';
    end if;
  elsif FSM_cur_state = s_while_end_2 then
    DATA_EN <= '1';
    DATA_RDWR <= '0';
    mul1_select <= '0';
    pc_dec <= '1';
    if DATA_RDATA = X"5B" then
     FSM_next_state <= s_fetch;
     pc_inc <= '1';
     pc_dec <= '0';
    else
     FSM_next_state <= s_while_end_2;
    end if; 
  
  elsif FSM_cur_state = s_do_while_start then
    pc_inc <= '1';
    FSM_next_state <= s_fetch;
  elsif FSM_cur_state = s_do_while_end then
    DATA_EN <= '1';
    DATA_RDWR <= '0';
    mul1_select <= '1';
    FSM_next_state <= s_do_while_end_1;
  
  elsif FSM_cur_state = s_do_while_end_1 then
    mul1_select <= '0';
    if DATA_RDATA /= "00000000" then 
      FSM_next_state <= s_do_while_end_2;
    else
      FSM_next_state <= s_fetch;
      pc_inc <= '1';
    end if;
  elsif FSM_cur_state = s_do_while_end_2 then
    pc_dec <= '1';
    DATA_EN <= '1';
    DATA_RDWR <= '0';
    mul1_select <= '0';
    if DATA_RDATA = X"28" then
      FSM_next_state <= s_fetch;
      pc_inc <= '1';
      pc_dec <= '0';
    else
      FSM_next_state <= s_do_while_end_2;
    end if; 
    
    elsif FSM_cur_state = s_null then
        FSM_next_state <= s_null;

    end if;

      end process FSM;
  end behavioral;

