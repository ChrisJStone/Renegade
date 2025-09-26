{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R+,S-,V-}
{
 04/18/2022 - gutted this, some parts moved to common2
}

UNIT MyIO;

INTERFACE

TYPE
  WindowRec = ARRAY[0..8000] OF Byte;
  ScreenType = ARRAY [0..3999] OF Byte;

VAR
  Wind: WindowRec;
  MonitorType: Byte ABSOLUTE $0000:$0449;
  ScreenAddr: ScreenType ABSOLUTE $B800:$0000;
  ScreenSize: Integer;
  MaxDisplayRows,
  MaxDisplayCols: Byte;

PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer);
PROCEDURE Cursor(b: BOOLEAN);
PROCEDURE SaveScreen(VAR Wind: WindowRec);
PROCEDURE RemoveWindow(VAR Wind: WindowRec);

IMPLEMENTATION

USES
  CRT;

PROCEDURE Cursor(b: BOOLEAN); ASSEMBLER;
ASM
  cmp b, 1
  je @turnon
  mov ch, 9
  mov cl, 0
  jmp @goforit
  @turnon:
  mov ch, 6
  mov cl, 7
  @goforit:
  mov ah,1
  int 10h
END;

PROCEDURE SaveScreen(VAR Wind: WindowRec);
BEGIN
  Move(ScreenAddr[0],Wind[0],ScreenSize);
END;

PROCEDURE RemoveWindow(VAR Wind: WindowRec);
BEGIN
  Move(Wind[0],ScreenAddr[0],ScreenSize);
END;



{
        Free Pascal does not support Borland/Turbo Pascal inline
 statement for direct machine code insertion. Original code appears
 to have been a direct copy from uncrunch.pas with all comments removed.
 Replaced inline statements with commented x86 asm and comment from
 uncrunch.pas in tdraw463 archive.
}
PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer); ASSEMBLER;
ASM
 PUSH    DS;                    {Save data segment.}
 LDS     SI,[Addr1];            {Source Address}
 LES     DI,[Addr2];            {Destination Addr}
 MOV     CX,[BlkLen];           {Length of block}
 JCXZ    @Done
 MOV     DX,DI;                 {Save X coordinate for later.}
 XOR     AX,AX;                 {Set Current attributes.}
 CLD
@LOOPA:
 LODSB;                         {Get next character.}
 CMP     AL,32;                 {If a control character, jump.}
 JC      @ForeGround
 STOSW;                         {Save letter on screen.}
@Next:
  LOOP    @LOOPA
  JMP      @Done
@ForeGround:
  CMP     AL,16;                {If less than 16, then change the}
  JNC     @BackGround;          {foreground color.  Otherwise jump.}
  AND     AH,0F0H;              {Strip off old foreground.}
  OR      AH,AL
  JMP     @Next
@BackGround:
  CMP     AL,24;                {If less than 24, then change the}
  JZ      @NextLine;            {background color.  If exactly 24,}
  JNC     @FlashBitToggle;      {then jump down to next line.}
  SUB     AL,16;                {Otherwise jump to multiple output}
  ADD     AL,AL;                {routines.}
  ADD     AL,AL
  ADD     AL,AL
  ADD     AL,AL
  AND     AH,8FH;               {Strip off old background.}
  OR      AH,AL
  JMP     @Next
@NextLine:
  ADD     DX,160;               {If equal to 24,}
  MOV     DI,DX;                {then jump down to}
  JMP     @Next;                {the next line.}
@FlashBitToggle:
  CMP     AL,27;                {Does user want to toggle the blink}
  JC      @MultiOutput;         {attribute?}
  JNZ     @Next
  XOR     AH,128;               {Done.}
  JMP     @Next
@MultiOutput:
  CMP     AL,25;                {Set Z flag if multi-space output.}
  MOV     BX,CX;                {Save main counter.}
  LODSB;                        {Get count of number of times}
  MOV     CL,AL;                {to display character.}
  MOV     AL,32
  JZ      @StartOutput;         {Jump here if displaying spaces.}
  LODSB;                        {Otherwise get character to use.}
  DEC     BX;                   {Adjust main counter.}
@StartOutput:
  XOR     CH,CH
  INC     CX
  REP STOSW
  MOV     CX,BX
  DEC     CX;                   {Adjust main counter.}
  LOOPNZ  @LOOPA;               {Loop if anything else to do...}
@Done:
  POP     DS;                   {Restore data segment.}
END;

END.
