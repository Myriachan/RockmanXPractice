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
eval controller_data_2 $7E00AA
eval state_vars $7E1F70
eval current_level $7E1F7A
eval life_count $7E1F80
eval weapon_power $7E1F87
eval intro_completed $7E1F9B
eval stage_intro 0
eval stage_sigma1 9
eval stage_sigma2 10
eval stage_sigma3 11
eval stage_sigma4 12


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
	lda.w {controller_data_2}
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
