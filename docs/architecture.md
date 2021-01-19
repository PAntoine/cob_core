# COB Core #
## Architecture ##

This processor is a 32 bit processor. It may extend to 64bit at some point.
It is highly influenced by the Motorola processors (68k posse represent!)
and the assembler will be definitely recognisable to 68k lot.

The register set will be 64 registers long.

It will BigEndian - as nature intended.

## Instruction Format ##

 The processor is 32 bits wide.

 As all good CPU's should be it's big-endian as this makes assembly
 programming and debugging easier.

                The format of an instruction is:
               
                 3       2       1       0      0
                 1.......3.......5.......8......0
                 UUUIIOOOOOOOOxxxxxxxxxxxxxxxxxxx
               
                 O = Instruction opcde (IO) 8 bits
                 U = Instruction Unit (IU) 3 bits
                 I = Instruction size (IS) 2 bits
                 x = instruction details - 19 bits

## Addressing Modes ##

ImmOp		Immediate in Opcode - The immediate value is loaded from the op code.

Imm			Immediate - the immediate value is loaded from the code, but follows
			the op code.

(ImmOp)		Immediate in Opcode indirect - the value is from/to the address pointed
			at by the immdiate in opcode value.

Reg			Register - the value is from/to the register.

(Reg)		Register indirect - the value is from/to the address pointed to by the
			register value.

Note: There will be others - I do intend to use a form or hardware segmentation 
      to aid in memory safety - so that will be added. It might not be part of the
	  instruction set, i.e. the segment registers may just work for all instructions
	  without being specifically referenced by the instructions. Kind of like TLD
	  but being a little better (TLDs will also be used - makes sense).

## Flag Registers ##



## Instruction Set ##

This is the first version of the instruction set, this will be extended in
later versions but this is the minimum required to get a working OS off the
ground.

### ADC		(add with Carry) ###

#### Description: ####

This function will add the data to the specified register. The result will
be left in the target register and the flags set. The carry bit will be added
in as well.

#### Flags: ####

	neg		- The negative bit set if the register underflows.
	zero	- The zero bit is set if the target register is set to zero.
	carry	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
TBD

### ADD		(add without Carry) ###

#### Description: ####

This function will add the data to the specified register. The result will
be left in the target register and the flags set.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
TBD

### and		(logical bitwise and ) ###

#### Description: ####

This function will add the data to the specified register. The result will
be left in the target register and the flags set.

#### Addressing Modes: ####
Source:
	Immidate	- The Immediate value is added to the target.
	Register	- The value of the specified register is added to the target
	(reg)		- The value pointed to be the register is added to the target.

Target:
	Register	- The content of the specified register is updated.



branch,		/* program branch */
branch_eq,		/* jump on result of a test */
branch_ge		/* jump on greater_than equal to */
branch_gt,		/* jump on greater_than */
branch_le,		/* jump on less_than equal to */
branch_lt,		/* jump on less_than */
branch_ne,		/* jump on result of a test */
call,		/* call function */
dec,		/* decrement */
divide,		/* divide */
endsubr,		/* end subroutine call */
equal,		/* test instruction == */
greater_equal,		/* test instructions >= */
greater_than,		/* test instructions > */
inc,		/* increment */
less_equal,		/* test instruction <= */
less_than,		/* test instruction < */
load,		/* local load */
loop,		/* dec register the loop */
modulo,		/* remainder of division */
multi,		/* multiply */
nop,
not,		/* logical not */
not_eq,		/* test instructions != */
or,		/* logical bitwise or */
pop,		/* pop the stack */
push,		/* push onto the stack */
ret,		/* return from function */
store,		/* local store */
sub,		/* subtract */
subr,		/* sub routine */
test,		/* compare two values/variables */
xor,		/* logical bitwaise xor */

