arch snes.cpu

// LoROM org macro - see bass's snes-cpu.asm "seek" macro
macro reorg n
	org (({n} & 0x7f0000) >> 1) | ({n} & 0x7fff)
	base {n}
endmacro

// Allows going back and forth
define savepc push origin, base
define loadpc pull base, origin

// Copy the original ROM
{reorg $808000}
incbin "Rockman X (J) (V1.0) [!].smc"


// Constants
eval stage_intro 0
eval stage_sigma1 9
eval stage_sigma2 10
eval stage_sigma3 11
eval stage_sigma4 12
eval magic_sram_tag_lo $5550  // Combined, these say "PURR"
eval magic_sram_tag_hi $5252
// RAM addresses
eval controller_1_current $7E00A7
eval controller_1_unknown $7E00A9
eval controller_1_unknown2 $7E00AB
eval controller_1_new_presses $7E00AD
eval screen_control_shadow $7E00B3
eval nmi_control_shadow $7E00C2
eval hdma_control_shadow $7E00C3
eval state_vars $7E1F70
eval current_level $7E1F7A
eval life_count $7E1F80
eval weapon_power $7E1F87
eval intro_completed $7E1F9B
eval spc_state_shadow $7EFFFE
// ROM addresses
eval rom_play_sound $8088B6
eval rom_nmi_after_pushes $808173
// SRAM addresses for saved states
eval sram_start $700000
eval sram_wram_7E0000 $710000
eval sram_wram_7E8000 $720000
eval sram_wram_7F0000 $730000
eval sram_wram_7F8000 $740000
eval sram_vram_0000 $750000
eval sram_vram_8000 $760000
eval sram_cgram $772000
eval sram_dma_bank $770000
eval sram_validity $774000
eval sram_saved_sp $774004
eval sram_vm_return $774006
eval sram_size $080000


// Header edits
{savepc}
	// Change SRAM size to 256 KB
	{reorg $80FFD8}
	db $08
{loadpc}


// Disable protection routines (needed because we add SRAM)
// Thanks to devin of The Cutting Room Floor for documenting these checks.
{savepc}
	{reorg $81816F}
	lda.b #$01
	nop
	nop
	{reorg $81852A}
	lda.b #$01
	nop
	nop
	{reorg $849D0B}
	lda.b #$01
	nop
	nop
	{reorg $84A471}
	lda.b #$01
	nop
	nop
{loadpc}


// Disable stage intros.
{savepc}
	// bne 9597 -> bra 9597
	{reorg $8095A2}
	bra $809597
{loadpc}


// Disable interstage password screen.
{savepc}
	// Always use password screen state 3, which is used to exit to stage select.
	// States are offsets into a jump table, so they're multiplied by 2.
	{reorg $80EFC2}
	ldx.b #3 * 2
{loadpc}


// Disable ending - return to stage select after Sigma 4.
{savepc}
	// Make check for completing Sigma 4 fail.
	{reorg $809C01}
	bra $809C06
{loadpc}


// Stage select hack
{savepc}
	{reorg $80BFED}
stage_choice_hack:
	// We come in when the user chooses an option in stage select.
	// A=00 through 0F, where A=(x * 4) + y, with x and y in 0-3.
	tax
	lda.l .stage_map, x

	sta.w {current_level}
	php
	rep #$30
	pha
	phx
	phy
	sep #$20

	// Special-case holding select.
	// Check whether select is being held.
	tax
	lda.w {controller_1_unknown}
	and.b #$20
	beq .not_holding_select

	// Is this a level we care about?
	txa
	cmp.b #8  // Chill Penguin
	beq .special_penguin
	cmp.b #3  // Armored Armadillo
	bne .not_holding_select
	// Fall through if 3 (Armadillo).

	// Load special data since select was held.
.special_armadillo:
	ldx.w #state_vars_armadillo_ex
	bra .state_vars_copy
.special_penguin:
	ldx.w #state_vars_penguin_ex
	bra .state_vars_copy

.not_holding_select:
	// Restore A after checking for select button.
	txa

	// Copy the state variables in.
	// Multiply by 48 = 3 * 16.  Do the math with the * 3 first because we
	// only have 1 byte of temporary storage.
	sta.b $02  // the replaced code zeros this anyway; see below.
	asl  // clears carry because number is small enough (max is $0C)
	adc.b $02
	// The multiply by 3 won't overflow into the high byte (A was 00-0C), but
	// this multiply by 16 can.
	rep #$30
	and.w #$00FF
	asl
	asl
	asl
	asl  // clears carry because number is small enough (max is $0240)
	// memcpy the state variables we want.
	adc.w #state_vars_per_level
	tax

.state_vars_copy:
	sep #$20
	ldy.w #{state_vars}

	// For some reason, I couldn't get mvn to work!
	lda.b #$30
	sta.b $02
.copy_loop:
	lda.l state_vars_per_level & $FF0000, x
	sta 0, y
	inx
	iny
	dec.b $02
	bne .copy_loop

	rep #$20
	// Restore state.
	ply
	plx
	pla
	plp

	// Replaced code to trigger starting a level.
	inc.b $01
	inc.b $01
	stz.b $02
	inc.b $15
	rts

.stage_map:
	db  9,  1,  8, 10
	db  3,  0,  0,  4
	db  5,  0,  0,  7
	db 11,  6,  2, 12
{loadpc}


// Infinite lives hack
{savepc}
	{reorg $809B40}
patch_infinite_lives:
	bra .nextline
.nextline:
	lda.w {life_count}
{loadpc}


// Start at stage select instead of intro
{savepc}
	{reorg $8094EF}
patch_skip_intro:
	// Replaces "stz".  A is already $10, conveniently =)
	sta.w {intro_completed}
{loadpc}


// Show all stages as highlighted regardless of game state
{savepc}
	{reorg $80C141}
patch_always_unbeaten:
	and.b #$00
{loadpc}


// Set stage select cursor according to previous level.
{savepc}
	{reorg $80BD16}
	// Don't set Launch Octopus as selected level if previous level was intro.
	// Done by deleting code.
patch_fix_stage_select_cursor:
	bra .always
	// Old code
	lda.b #1
	sta.w {current_level}
.always:
	// Delete check for Sigma levels; handle Sigma levels normally.
	ldx.b $1E
	bra .always2
	lda.b #9
.always2:
	// Load correct coordinates for the map ID, with Sigma levels and intro.
	sta.b $1D  // not sure what this does
	nop  // remove decrement!
	tax
	lda.w stage_select_inverse_x, x
	sta.b $04
	lda.w stage_select_inverse_y, x
	sta.b $07
{loadpc}
{savepc}
	{reorg $86FC00}
stage_select_inverse_x:
	db 1, 1, 2, 0, 3, 0, 1, 3, 2, 0, 3, 0, 3
stage_select_inverse_y:
	db 1, 0, 3, 1, 1, 2, 3, 2, 0, 0, 0, 3, 3
{loadpc}

// Change "Game Start" to "Practice"
{savepc}
	{reorg $86934D}
	db "PRACTICE   "
	{reorg $869379}
	db "PRACTICE   "
	{reorg $8693A5}
	db "PRACTICE   "
{loadpc}


// Make "ESCAPE.U" always work
{savepc}
	{reorg $80C950}
escape_u_hack:
	lda.w {current_level}
	bra .nextline1  // replace
.nextline1:
	cmp.b #{stage_sigma1}
	bra .nextline2
.nextline2:
	asl
	tax
	lda.w {weapon_power} - 2 + 1, x
	lda.b #$40
	bra .nextline3
.nextline3:
	rts
{loadpc}


// Added code/data
{reorg $80FBD0}

// Values of state_vars per level in a "waterful" run.
state_vars_per_level:
	// Intro stage
	//db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 \
	//db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  > True values. Not using so doesn't repeat.
	//db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$00,$00,$00,$00,$00 /
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$04,$00,$00,$00,$00
	// Launch Octopus
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00
	db $02,$00,$01,$8E,$8E,$83,$00,$00,$00,$00,$00,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$1A,$04,$76,$00,$00,$00
	// Sting Chameleon
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00
	db $02,$00,$01,$8E,$8E,$86,$00,$00,$DC,$00,$00,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$1C,$04,$F6,$00,$00,$00
	// Armored Armadillo
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$86,$80,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$18,$04,$74,$00,$00,$00
	// Flame Mammoth
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $02,$00,$01,$82,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$19,$14,$04,$24,$00,$00,$00
	// Storm Eagle
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$12,$10,$20,$00,$00,$00
	// Spark Mandrill
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$82,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$9B,$16,$04,$34,$00,$00,$00
	// Boomer Kuwanger
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
	// Chill Penguin
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$04,$00,$00,$00,$00
	// Sigma 1
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$C0,$00,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
	// Sigma 2
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
	// Sigma 3
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
	// Sigma 4
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
state_vars_penguin_ex:
	// Heart (Chill Penguin)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$40,$00,$00,$00
	db $02,$00,$01,$8E,$8E,$88,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DF,$1E,$10,$FE,$00,$00,$00
state_vars_armadillo_ex:
	// Visits (Armored Armadillo)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$40,$00,$01,$00
	db $03,$00,$01,$8E,$8E,$8E,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DF,$20,$04,$FF,$00,$00,$00


// Saved state hacks
{savepc}
	{reorg $80FFA4}
	jml nmi_hook
{loadpc}

{reorg $84EE00}
nmi_hook:

	// Rather typical NMI prolog code - same as real one.
	rep #$38
	pha
	phx
	phy
	phd
	phb
	lda.w #$0000
	tcd

	// Don't interfere with NMI as much as possible.
	// Only execute when select is pressed.
	lda.b {controller_1_current}
	bit.w #$2000
	beq .return_normal_no_rep

	// Mask controller.
	bit.b {controller_1_unknown2}
	beq .return_normal_no_rep

	// Check for Select + R.
	and.w #$2030
	cmp.w #$2010
	beq .select_r
	cmp.w #$2020
	bne .return_normal_no_rep
	jmp .select_l

// Resume NMI handler, skipping the register pushes.
.return_normal:
	rep #$38
.return_normal_no_rep:
	jml {rom_nmi_after_pushes}

// Play an error sound effect.
.error_sound_return:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	sep #$20
	lda.b #$74
	jsl {rom_play_sound}
	bra .return_normal


// Select and R pushed = save.
.select_r:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	// Mark SRAM's contents as invalid.
	lda.w #$1234
	sta.l {sram_validity} + 0
	sta.l {sram_validity} + 2

	// Test SRAM to verify that 256 KB is present.  Protects against bad
	// behavior on emulators and Super UFO.
	sep #$10
	lda.w #$1234
	ldy.b #{sram_start} >> 16

	// Note that we can't do a write-read-write-read pattern due to potential
	// "open bus" issues, and because mirroring is also possible.
	// Essentially, this code verifies that all 8 banks are storing
	// different data simultaneously.
.sram_test_write_loop:
	phy
	plb
	sta.w $0000
	inc
	iny
	cpy.b #({sram_start} + {sram_size}) >> 16
	bne .sram_test_write_loop

	// Read the data back and verify it.
	lda.w #$1234
	ldy.b #{sram_start} >> 16
.sram_test_read_loop:
	phy
	plb
	cmp.w $0000
	bne .error_sound_return
	inc
	iny
	cpy.b #({sram_start} + {sram_size}) >> 16
	bne .sram_test_read_loop

	// Store DMA registers' values to SRAM.
	rep #$30
	ldy.w #0
	phy
	plb
	plb
	tyx

	sep #$20
.save_dma_reg_loop:
	lda.w $4300, x
	sta.l {sram_dma_bank}, x
	inx
	iny
	cpy.w #$000B
	bne .save_dma_reg_loop
	cpx.w #$007B
	beq .save_dma_regs_done
	inx
	inx
	inx
	inx
	inx
	ldy.w #0
	jmp .save_dma_reg_loop
	// End of DMA registers to SRAM.

.save_dma_regs_done:
	// Run the "VM" to do a series of PPU writes.
	rep #$30

	// X = address in this bank to load from.
	// B = bank to read from and write to
	ldx.w #.save_write_table
.run_vm:
	pea (.vm >> 16) * $0101
	plb
	plb
	jmp .vm

// List of addresses to write to do the DMAs.
// First word is address; second is value.  $1000 and $8000 are flags.
// $1000 = byte read/write.  $8000 = read instead of write.
.save_write_table:
	// Turn PPU off
	dw $1000 | $2100, $80
	dw $1000 | $4200, $00
	// Single address, B bus -> A bus.  B address = reflector to WRAM ($2180).
	dw $0000 | $4310, $8080  // direction = B->A, byte reg, B addr = $2180
	// Copy WRAM 7E0000-7E7FFF to SRAM 710000-717FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0071  // A addr = $71xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7E8000-7EFFFF to SRAM 720000-727FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0072  // A addr = $72xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7F0000-7F7FFF to SRAM 730000-737FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0073  // A addr = $73xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7F8000-7FFFFF to SRAM 740000-747FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0074  // A addr = $74xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Address pair, B bus -> A bus.  B address = VRAM read ($2139).
	dw $0000 | $4310, $3981  // direction = B->A, word reg, B addr = $2139
	dw $1000 | $2115, $0000  // VRAM address increment mode.
	// Copy VRAM 0000-7FFF to SRAM 750000-757FFF.
	dw $0000 | $2116, $0000  // VRAM address >> 1.
	dw $9000 | $2139, $0000  // VRAM dummy read.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0075  // A addr = $75xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy VRAM 8000-7FFF to SRAM 760000-767FFF.
	dw $0000 | $2116, $4000  // VRAM address >> 1.
	dw $9000 | $2139, $0000  // VRAM dummy read.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0076  // A addr = $76xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy CGRAM 000-1FF to SRAM 772000-7721FF.
	dw $1000 | $2121, $00    // CGRAM address
	dw $0000 | $4310, $3B80  // direction = B->A, byte reg, B addr = $213B
	dw $0000 | $4312, $2000  // A addr = $xx2000
	dw $0000 | $4314, $0077  // A addr = $77xxxx, size = $xx00
	dw $0000 | $4316, $0002  // size = $02xx ($0200), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Done
	dw $0000, .save_return

.save_return:
	// Restore null bank.
	pea $0000
	plb
	plb

	// Mark the save as valid.
	rep #$30
	lda.w #{magic_sram_tag_lo}
	sta.l {sram_validity}
	lda.w #{magic_sram_tag_hi}
	sta.l {sram_validity} + 2

	// Save stack pointer.
	tsa
	sta.l {sram_saved_sp}

.register_restore_return:
	// Restore register state for return.
	sep #$20
	lda.b {nmi_control_shadow}
	sta.w $4200
	lda.b {hdma_control_shadow}
	sta.w $420C
	lda.b {screen_control_shadow}
	sta.w $2100

	// Copy SPC state to SPC state shadow, or the game gets confused.
	lda.w $2142
	sta.l {spc_state_shadow}

	// Wait for V-blank to end then start again.
//.nmi_wait_loop_set:
//	lda.w $4212
//	bmi .nmi_wait_loop_set
//.nmi_wait_loop_clear:
//	lda.w $4212
//	bpl .nmi_wait_loop_clear

	rep #$38
	jml {rom_nmi_after_pushes}   // Jump to normal NMI handler, skipping the
	                             // prolog code, since we already did it.

// Select and L pushed = load.
.select_l:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	// Check whether SRAM contents are valid.
	lda.l {sram_validity} + 0
	cmp.w #{magic_sram_tag_lo}
	bne .jmp_error_sound
	lda.l {sram_validity} + 2
	cmp.w #{magic_sram_tag_hi}
	bne .jmp_error_sound

	// Stop sound effects by sending command to SPC700
	stz.w $2141    // write zero to both $2141 and $2142
	sep #$20
	stz.w $2143
	lda.b #$F1
	sta.w $2140

	// Execute VM to do DMAs
	ldx.w #.load_write_table
	jmp .run_vm

// Needed to put this somewhere.
.jmp_error_sound:
	jmp .error_sound_return

// Register write data table for loading saves.
.load_write_table:
	// Disable HDMA
	dw $1000 | $420C, $00
	// Turn PPU off
	dw $1000 | $2100, $80
	dw $1000 | $4200, $00
	// Single address, A bus -> B bus.  B address = reflector to WRAM ($2180).
	dw $0000 | $4310, $8000  // direction = A->B, B addr = $2180
	// Copy SRAM 710000-717FFF to WRAM 7E0000-7E7FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0071  // A addr = $71xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 720000-727FFF to WRAM 7E8000-7EFFFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0072  // A addr = $72xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 730000-737FFF to WRAM 7F0000-7F7FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0073  // A addr = $73xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 740000-747FFF to WRAM 7F8000-7FFFFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0074  // A addr = $74xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Address pair, A bus -> B bus.  B address = VRAM write ($2118).
	dw $0000 | $4310, $1801  // direction = A->B, B addr = $2118
	dw $1000 | $2115, $0000  // VRAM address increment mode.
	// Copy SRAM 750000-757FFF to VRAM 0000-7FFF.
	dw $0000 | $2116, $0000  // VRAM address >> 1.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0075  // A addr = $75xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 760000-767FFF to VRAM 8000-7FFF.
	dw $0000 | $2116, $4000  // VRAM address >> 1.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0076  // A addr = $76xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 772000-7721FF to CGRAM 000-1FF.
	dw $1000 | $2121, $00    // CGRAM address
	dw $0000 | $4310, $2200  // direction = A->B, byte reg, B addr = $2122
	dw $0000 | $4312, $2000  // A addr = $xx2000
	dw $0000 | $4314, $0077  // A addr = $77xxxx, size = $xx00
	dw $0000 | $4316, $0002  // size = $02xx ($0200), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Done
	dw $0000, .load_return

.load_return:
	// Load stack pointer.  We've been very careful not to use the stack
	// during the memory DMA.  We can now use the saved stack.
	rep #$30
	lda.l {sram_saved_sp}
	tas

	// Restore null bank now that we have a working stack.
	pea $0000
	plb
	plb

	// Rewrite inputs in ram to reflect the loading inputs and not saving inputs
	lda.b {controller_1_current}
	eor.w #$2010
	ora.w #$2020
	sta.b {controller_1_unknown}
	sta.b {controller_1_current}
	sta.b {controller_1_unknown2}

	// Load DMA from SRAM
	ldy.w #0
	ldx.w #0

	sep #$20
.load_dma_regs_loop:
	lda.l {sram_dma_bank}, x
	sta.w $4300, x
	inx
	iny
	cpy.w #$000B
	bne .load_dma_regs_loop
	cpx.w #$007B
	beq .load_dma_regs_done
	inx
	inx
	inx
	inx
	inx
	ldy.w #0
	jmp .load_dma_regs_loop
	// End of DMA from SRAM

.load_dma_regs_done:
	// Restore registers and return.
	jmp .register_restore_return


.vm:
	// Data format: xx xx yy yy
	// xxxx = little-endian address to write to .vm's bank
	// yyyy = little-endian value to write
	// If xxxx has high bit set, read and discard instead of write.
	// If xxxx has bit 12 set ($1000), byte instead of word.
	// If yyyy has $DD in the low half, it means that this operation is a byte
	// write instead of a word write.  If xxxx is $0000, end the VM.
	rep #$30
	// Read address to write to
	lda.w $0000, x
	beq .vm_done
	tay
	inx
	inx
	// Check for byte mode
	bit.w #$1000
	beq .vm_word_mode
	and.w #~$1000
	tay
	sep #$20
.vm_word_mode:
	// Read value
	lda.w $0000, x
	inx
	inx
.vm_write:
	// Check for read mode (high bit of address)
	cpy.w #$8000
	bcs .vm_read
	sta $0000, y
	bra .vm
.vm_read:
	// "Subtract" $8000 from y by taking advantage of bank wrapping.
	lda $8000, y
	bra .vm

.vm_done:
	// A, X and Y are 16-bit at exit.
	// Return to caller.  The word in the table after the terminator is the
	// code address to return to.
	jmp ($0002,x)
