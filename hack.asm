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


// Version tags
eval version_major 2
eval version_minor 0
eval version_revision 0
// Constants
eval stage_intro 0
eval stage_sigma1 9
eval stage_sigma2 10
eval stage_sigma3 11
eval stage_sigma4 12
eval game_config_size $17
eval magic_sram_tag_lo $4143  // Combined, these say "CATS"
eval magic_sram_tag_hi $5354
eval magic_config_tag_lo $4643  // Combined, these say "CFG1"
eval magic_config_tag_hi $3147
// RAM addresses
eval title_screen_option $7E003C
eval controller_1_current $7E00A7
eval controller_1_previous $7E00A9
eval controller_1_new $7E00AB
eval controller_2_current $7E00AD
eval controller_2_previous $7E00AF
eval controller_2_new $7E00B1
eval screen_control_shadow $7E00B3
eval nmi_control_shadow $7E00C2
eval hdma_control_shadow $7E00C3
eval rng_value $7E0BA6
eval controller_1_disable $7E1F48
eval state_vars $7E1F70
eval current_level $7E1F7A
eval life_count $7E1F80
eval midpoint_flag $7E1F81
eval weapon_power $7E1F85
eval intro_completed $7E1F9B
eval config_selected_option $7EFF80
eval config_data $7EFFC0
eval config_shot $7EFFC0
eval config_jump $7EFFC1
eval config_dash $7EFFC2
eval config_select_l $7EFFC3
eval config_select_r $7EFFC4
eval config_menu $7EFFC5
eval config_bgm $7EFFC8
eval config_se $7EFFC9
eval config_sound $7EFFCA
eval spc_state_shadow $7EFFFE
// Temporary storage for load process.  Overlaps game use.
eval load_temporary_rng $7F0000
// ROM addresses
eval rom_play_music $80878B
eval rom_play_sound $8088B6
eval rom_rtl_instruction $808798  // last instruction of rom_play_sound
eval rom_rts_instruction $8087D0  // last instruction of some part of rom_play_music
eval rom_nmi_after_pushes $808173
eval rom_nmi_after_controller $8081DD
eval rom_config_loop $80EAAA
eval rom_config_button $80EB55
eval rom_config_stereo $80EBE8
eval rom_config_bgm $80EC30
eval rom_config_se $80EC74
eval rom_config_exit $80ECC0
eval rom_default_config $86EE23
// SRAM addresses for saved states
eval sram_start $700000
eval sram_wram_7E0000 $710000
eval sram_wram_7E8000 $720000
eval sram_wram_7F0000 $730000
eval sram_wram_7F8000 $740000
eval sram_vram_0000 $750000
eval sram_vram_8000 $760000
eval sram_cgram $772000
eval sram_oam $772200
eval sram_dma_bank $770000
eval sram_validity $774000
eval sram_saved_sp $774004
eval sram_vm_return $774006
eval sram_previous_command $774008
// SRAM addresses for general config.  These are at lower addresses to support
// emulators and cartridges that don't support 256 KB of SRAM.
eval sram_config_valid $700100
eval sram_config_game $700104   // Main game config.  game_config_size bytes.
eval sram_config_extra {sram_config_game} + {game_config_size}
eval sram_config_category {sram_config_extra} + 0
eval sram_config_route {sram_config_extra} + 1
eval sram_config_midpointsoff {sram_config_extra} + 2
eval sram_config_keeprng {sram_config_extra} + 3
eval sram_config_musicoff {sram_config_extra} + 4
eval sram_config_godmode {sram_config_extra} + 5
eval sram_config_extra_size 6   // adjust this as more are added
eval sram_size $080000


// Header edits
{savepc}
	// Change SRAM size to 256 KB
	{reorg $80FFD8}
	db $08
{loadpc}


// Init hook
{savepc}
	{reorg $808012}
	jml init_hook
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

	// We're about to overwrite this memory, so we can use it as temporary
	// storage for these coming lookups.
	sta.w {state_vars}
	stz.w {state_vars} + 1   // for 16-bit adc below
	php
	rep #$30
	pha
	phx
	phy

	// Convert route to index into state_table_lookup.
	sep #$20
	lda.l {sram_config_category}
	asl
	asl  // clears carry since category is small
	adc.l {sram_config_route}
	asl

	rep #$21  // clear carry
	and.w #$00FF
	tax
	lda.l state_table_lookup, x

	// After finding the right table, add 2 times the level.
	adc.w {state_vars}
	adc.w {state_vars}
	tax

	// Is select being held?
	sep #$20
	lda.w {controller_1_current}+1
	and.b #$20
	beq .not_holding_select
	// Read the second element of the table when holding select.
	inx
.not_holding_select:

	// Get the table index byte.
	lda.l state_bank & $FF0000, x

	// Copy the state variables in.
	// Multiply by 48 = 3 * 16.  Do the math with the * 3 first because we
	// only have 1 byte of temporary storage.
	sta.b $02  // the replaced code zeros this anyway; see below.
	asl  // clears carry because number is small enough (max is $0C)
	adc.b $02
	// The multiply by 3 won't overflow into the high byte (A was less than
	// $55), but this multiply by 16 can.
	rep #$30
	and.w #$00FF
	asl
	asl
	asl
	asl  // clears carry because number is small enough (max is $0FF0)
	// memcpy the state variables we want.
	adc.w #state_table_base
	tax

.state_vars_copy:
	sep #$20
	ldy.w #{state_vars}

	// For some reason, I couldn't get mvn to work!
	lda.b #$30
	sta.b $02
.copy_loop:
	lda.l state_table_base & $FF0000, x
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

// Title screen text edits:
// Add "Practice Edition".
// Change "Game Start" to "Practice".
// Remove "Password".
{savepc}
	{reorg $869349}
patch_main_menu_text:
	macro optionset label, attrib1, attrib2
		db .edition_{label}_end - .edition_{label}_begin, $38
		dw $138E >> 1
	.edition_{label}_begin:
		db "- Practice Edition -"
	.edition_{label}_end:

		db .option1_{label}_end - .option1_{label}_begin, {attrib1}
		dw $1514 >> 1
	.option1_{label}_begin:
		db "PRACTICE"
	.option1_{label}_end:

		db .option2_{label}_end - .option2_{label}_begin, {attrib2}
		dw $1614 >> 1
	.option2_{label}_begin:
		db "OPTION MODE"
	.option2_{label}_end:
	endmacro

.optionset1:
	{optionset s1, $24, $20}
	db 0
.optionset2:
	{optionset s2, $20, $24}
	db 0

	{reorg $86912B}
	dw .optionset1
	dw .optionset1
	dw .optionset2
{loadpc}

// Change intro text =^-^=
{savepc}
	{reorg $84CE10}
	db "ROCKMAN X PRACTICE EDITION"
	db $80, $87, $0A
	db "Ver. "
	db $30 + {version_major}, '.', $30 + {version_minor}, $30 + {version_revision}
	db "   "
	{reorg $84CE4B}
	db "2014-2017     "
	{reorg $84CE5C}
	db "Myria and Total"
{loadpc}

// Make the useless hidden "PASS WORD" option unavailable.
{savepc}
	// The original code handles both Up and Down button presses on the title
	// screen separately, obviously.  But we only have two options, indexes 0
	// and 2, so we can just XOR by 2.  Note that Select is treated as Down.
	{reorg $80925C}
	bit.b #$2C
	beq $80928B
	lda.b {title_screen_option}
	eor.b #$02
	bra $809276
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
	lda.w {weapon_power} + 1, x
	lda.b #$40
	bra .nextline3
.nextline3:
	rts
{loadpc}


// Make the four corners of stage select all be Sigma.
// stage_select_render_hook later in this file puts the numbers 1-4 on top
// of the Sigma icons.
{savepc}
	// Redirect tilemaps for Stage/Map/Spec at those for Sigma icon.
	{reorg $869B00 + 4}
	dw $E990
	{reorg $869B07 + 4}
	dw $E990
	{reorg $869B0E + 4}
	dw $E990
	{reorg $869B15 + 4}
	dw $E990
	{reorg $869B1C + 4}
	dw $E990
	{reorg $869B23 + 4}
	dw $E990

	// Show Storm Eagle's stage picture as his "alive" state.  We need this
	// because the state of RAM at this point is him dead.
	{reorg $869B7E + 4}
	dw $E510

	// Always show Sigma in lower right, and switch palette from Rockman X
	// to the Sigma icon palette.
	{reorg $80BDC5}
	nop
	nop

	// Show Sigma even though "show Sigma" flag in RAM is clear.
	{reorg $80C10C}
	nop
	nop

	// When highlighting the corners, show Sigma in the middle.
	// When highlighting the middle, show the city.
	{reorg $869BE3}
	db $12, $0A, $10, $12
	db $0D, $07, $07, $0E
	db $0F, $07, $07, $11
	db $12, $0B, $0C, $12

	// Palette map table for the same.
	{reorg $869C13}
	db $6F, $67, $6C, $6F
	db $68, $C8, $C8, $6A
	db $6B, $C8, $C8, $6E
	db $6F, $6D, $69, $6F

	// The indexes above are double before calling $828011, but this doubling
	// is done as 8-bit.  We need the full 16-bit result in order to get the
	// "city" palette working.
	{reorg $80C131}
	jmp palette_multiply_hack

	// Same hack, but for when returning to the character selection screen
	// from within a stage.
	{reorg $80BDFF}
	// JSR instead of JMP because we don't RTS right afterward.
	jsr palette_multiply_hack
	nop
	nop
	nop
{loadpc}


// Added code/data
{reorg $80FBD0}

// Hook end of stage select BG3 tilemap rendering so we can change the stage select screen.
{savepc}
	{reorg $80B2F8}
	// jmp instead of jml because our code is in the same bank.
	jmp stage_select_render_hook
{loadpc}
stage_select_render_hook:
	// At entry, A = 8-bit, X/Y = 16-bit.
	// Deleted code
	stx.b $F8
	stz.b $F4
	// Is this rendering from bank A2?
	// "A" register destroyed by original code when we return.
	lda.b $F5 + 2
	cmp.b #$A2
	bne .not_stage_select
	// Did this just render the BG3 tilemap of stage select?
	lda.b $F5 + 0
	ora.b $F5 + 1
	bne .not_stage_select
	// A2:C672 = end of compressed BG3 stage select tilemap.
	cpy.w #$C672
	bne .not_stage_select

	// OK, this is what we wanted to hook.
	// NOTE: We don't need to restore A back to 8-bit, because 8080F8 does sep #$30.
	rep #$20
	lda.w #$3431     // ASCII character "1" in yellow palette
	sta.l $7F0190
	inc
	sta.l $7F01B4
	inc
	sta.l $7F0610
	inc
	sta.l $7F0634

	lda.l {sram_config_category}
	and.w #$00FF
	bne .skip_hold_select_message

	phx
	phy
	ldx.w #0
.string_loop:
	lda.l .stage_select_text_begin, x
	tay
	txa
	asl
	tax
	tya
	and.w #$00FF
	ora.w #$3400
	sta.l $7F06C8, x
	txa
	lsr
	tax
	inx
	cpx.w #.stage_select_text_end - .stage_select_text_begin
	bne .string_loop
	ply
	plx
.skip_hold_select_message:

.not_stage_select:
	// jmp instead of jml because our code is in the same bank.
	jmp $8080F8

.stage_select_text_begin:
	db "HOLD SELECT FOR REVISITS"
.stage_select_text_end:


// The indexes above are double before calling $828011, but this doubling
// is done as 8-bit.  We need the full 16-bit result in order to get the
// "city" palette working.
palette_multiply_hack:
	// Switch to 16-bit for this.
	rep #$30
	// The high byte of A is set to random crap at this point.
	and.w #$00FF
	// Double here and put into Y.
	asl
	tay
	// Call the routine, then return ourselves (we were jumped to, not called).
	jsl $828011
	// Need to set A/X/Y back to 8-bit before we return, though.
	sep #$30
	rts


// Added data that must be in bank $86.
{reorg $86FA60}

// These tables convert from stage number to X/Y cursor coordinates for stage select.
stage_select_inverse_x:
	db 1, 1, 2, 0, 3, 0, 1, 3, 2, 0, 3, 0, 3
stage_select_inverse_y:
	db 1, 0, 3, 1, 1, 2, 3, 2, 0, 0, 0, 3, 3

// Configuration screen text hacks.
config_screen_moves:
{savepc}
	// Move existing strings

	// First group
	// JUMP (normal)
	{reorg $869588}
	dw $1282 >> 1
	// JUMP (highlighted)
	{reorg $869591}
	dw $1282 >> 1
	// SHOT (normal)
	{reorg $86959A}
	dw $1242 >> 1
	// SHOT (highlighted)
	{reorg $8695A3}
	dw $1242 >> 1
	// SELECT_R (normal)
	{reorg $8695C6}
	dw $1342 >> 1
	// SELECT_R (highlighted)
	{reorg $8695D3}
	dw $1342 >> 1
	// MENU (normal)
	{reorg $8695E0}
	dw $1382 >> 1
	// MENU (highlighted)
	{reorg $8695E9}
	dw $1382 >> 1
	// EXIT (normal)
	{reorg $8695F2}
	dw $15AC >> 1
	// EXIT (highlighted)
	{reorg $8695FB}
	dw $15AC >> 1
	// BGM (normal)
	{reorg $869604}
	dw $1642 >> 1
	// BGM (highlighted)
	{reorg $86960C}
	dw $1642 >> 1
	// S.E. (normal)
	{reorg $869614}
	dw $1682 >> 1
	// S.E. (highlighted)
	{reorg $86961D}
	dw $1682 >> 1
	// DASH (normal)
	{reorg $869626}
	dw $12C2 >> 1
	// DASH (highlighted)
	{reorg $86962F}
	dw $12C2 >> 1

	// Second group
	// " STEREO " (normal)
	{reorg $86989F}
	dw $14D4 >> 1
	// Also overwrite string to move spaces
	db "STEREO  "
	// " STEREO " (highlighted)
	{reorg $8698AC}
	dw $14D4 >> 1
	// Also overwrite string to move spaces
	db "STEREO  "
	// "MONAURAL" (normal)
	{reorg $8698B9}
	dw $14D4 >> 1
	// Also overwrite string to rename "MONO"
	db "MONO    "
	// "MONAURAL" (highlighted)
	{reorg $8698C6}
	dw $14D4 >> 1
	// Also overwrite string to rename "MONO"
	db "MONO    "

	// Button names
	{reorg $80ECE3}
	lda.w #$1254 >> 1
	{reorg $80ECF3}
	lda.w #$1294 >> 1
	{reorg $80ED03}
	lda.w #$12D4 >> 1
	{reorg $80ED13}
	lda.w #$1314 >> 1
	{reorg $80ED23}
	lda.w #$1354 >> 1
	{reorg $80ED33}
	lda.w #$1394 >> 1
	{reorg $86BCE8}
	// Left-align button names
	db "B     Y     A     X     L     R     SELECTSTART *     "

	// Song number after "BGM".
	{reorg $80EDB9}
	lda.w #$1654 >> 1
	// Effect number after "S.E."
	{reorg $80EDFB}
	lda.w #$1694 >> 1

	// Change "SELECT_L" to "SEL_L".
	{reorg $8695AA}
	db .select_l1_end - .select_l1_begin, $20
	dw $1302 >> 1
.select_l1_begin:
	db "SEL_L"
.select_l1_end:
	db 0
	{reorg $8695B7}
	db .select_l2_end - .select_l2_begin, $2C
	dw $1302 >> 1
.select_l2_begin:
	db "SEL_L"
.select_l2_end:
	db 0

	// Change "SELECT_R" to "SEL_R".
	{reorg $8695C4}
	db .select_r1_end - .select_r1_begin, $20
	dw $1342 >> 1
.select_r1_begin:
	db "SEL_R"
.select_r1_end:
	db 0
	{reorg $8695D1}
	db .select_r2_end - .select_r2_begin, $2C
	dw $1342 >> 1
.select_r2_begin:
	db "SEL_R"
.select_r2_end:
	db 0
{loadpc}

// Macros for creating new option strings.
macro option_string label, string, vramaddr, attribute, terminator
	{label}:
		db {label}_end - {label}_begin, {attribute}
		dw {vramaddr} >> 1
	{label}_begin:
		db {string}
	{label}_end:
	if {terminator}
		db 0
	endif
endmacro

macro option_string_pair label, string, vramaddr
	{option_string {label}_normal, {string}, {vramaddr}, $20, 1}
	{option_string {label}_highlighted, {string}, {vramaddr}, $2C, 1}
endmacro

// Option category titles.
{savepc}
	{reorg $869143}
	dw string_option_titles
{loadpc}
string_option_titles:
	{option_string .key_config, "KEY CONFIG", $11C6, $38, 0}
	{option_string .sound_mode, "SOUND MODE", $1446, $38, 0}
	{option_string .sound_test, "SOUND TEST", $15C6, $38, 0}
	{option_string .route, "ROUTE", $11EA, $38, 0}
	{option_string .misc, "MISC.", $13AA, $38, 0}
	db 0

// Extra strings we're adding.
	{option_string_pair string_category, "CATEGORY", $1264}
	{option_string string_anypercent, "ANY`", $1276, $20, 1}
	{option_string string_100percent, "100`", $1276, $20, 1}

	{option_string_pair string_mammoth, "MAMMOTH", $12A4}
	{option_string string_mammoth_5th, "5TH ", $12B6, $20, 1}
	{option_string string_mammoth_6th, "6TH ", $12B6, $20, 1}
	{option_string string_mammoth_7th, "7TH ", $12B6, $20, 1}
	{option_string string_mammoth_8th, "8TH ", $12B6, $20, 1}
	{option_string_pair string_empty_route2, "        ", $12E4}
	{option_string string_empty_route2_setting, "    ", $12F6, $20, 1}

	{option_string_pair string_ice, "ICE...  ", $12A4}
	{option_string string_iceless, "LESS", $12B6, $20, 1}
	{option_string string_iceful, "FUL ", $12B6, $20, 1}
	{option_string_pair string_water, "WATER...", $12E4}
	{option_string string_waterless, "LESS", $12F6, $20, 1}
	{option_string string_waterful, "FUL ", $12F6, $20, 1}

	{option_string_pair string_output, "OUTPUT", $14C2}

	{option_string_pair string_music, "MUSIC", $1502}
	{option_string string_music_on,  "ON ", $1514, $20, 1}
	{option_string string_music_off, "OFF", $1514, $20, 1}

	{option_string_pair string_midpoints, "MIDPOINT", $1424}
	{option_string string_midpoints_on,  "ON ", $1436, $20, 1}
	{option_string string_midpoints_off, "OFF", $1436, $20, 1}

	{option_string_pair string_keeprng, "KEEP RNG", $1464}
	{option_string string_keeprng_on, "ON ", $1476, $20, 1}
	{option_string string_keeprng_off, "OFF", $1476, $20, 1}

	{option_string_pair string_godmode, "GODMODE", $14A4}
	{option_string string_godmode_on, "ON ", $14B6, $20, 1}
	{option_string string_godmode_off, "OFF", $14B6, $20, 1}

// I'm too lazy to rework the compressed font, so I use this to overwrite
// the ` character in VRAM.  The field used for the "attribute" of the
// "text" just becomes the high byte of each pair of bytes.
macro tilerow vrambase, rownum, col7, col6, col5, col4, col3, col2, col1, col0
	db 1, (({col7} & 2) << 6) | (({col6} & 2) << 5) | (({col5} & 2) << 4) | (({col4} & 2) << 3) | (({col3} & 2) << 2) | (({col2} & 2) << 1) | ({col1} & 2) | (({col0} & 2) >> 1)
	dw (({vrambase}) + (({rownum}) * 2)) >> 1
	db (({col7} & 1) << 7) | (({col6} & 1) << 6) | (({col5} & 1) << 5) | (({col4} & 1) << 4) | (({col3} & 1) << 3) | (({col2} & 1) << 2) | (({col1} & 1) << 1) | ({col0} & 1)
endmacro

string_percent_sign_bitmap:
	{tilerow $0600, 0,   0,2,3,0,0,0,2,3}
	{tilerow $0600, 1,   2,3,2,3,0,2,3,0}
	{tilerow $0600, 2,   3,1,3,0,1,3,0,0}
	{tilerow $0600, 3,   0,3,0,1,3,0,0,0}
	{tilerow $0600, 4,   0,0,1,3,0,1,3,0}
	{tilerow $0600, 5,   0,2,3,0,2,3,2,3}
	{tilerow $0600, 6,   2,3,0,0,3,2,3,0}
	{tilerow $0600, 7,   3,0,0,0,0,3,0,0}
	db 0


// New additions to string table.  This table has reserved entries not being used.
{savepc}
	// Table starts here in reality.
	{reorg $86910B}
string_table:
	{reorg $869193}
	macro stringtableentry label
		.idcalc_{label}:
			dw (string_{label}) & $FFFF
		eval stringid_{label} (string_table.idcalc_{label} - string_table) / 2
	endmacro

	{stringtableentry percent_sign_bitmap}
	{stringtableentry 100percent}
	{stringtableentry anypercent}
	{stringtableentry ice_normal}
	{stringtableentry ice_highlighted}
	{stringtableentry iceless}
	{stringtableentry iceful}
	{stringtableentry water_normal}
	{stringtableentry water_highlighted}
	{stringtableentry waterful}
	{stringtableentry waterless}
	{stringtableentry mammoth_normal}
	{stringtableentry mammoth_highlighted}
	{stringtableentry mammoth_5th}
	{stringtableentry mammoth_6th}
	{stringtableentry mammoth_7th}
	{stringtableentry mammoth_8th}
	{stringtableentry empty_route2_normal}
	{stringtableentry empty_route2_highlighted}
	{stringtableentry empty_route2_setting}
	{stringtableentry output_normal}
	{stringtableentry output_highlighted}
	{stringtableentry category_normal}
	{stringtableentry category_highlighted}
	{stringtableentry midpoints_normal}
	{stringtableentry midpoints_highlighted}
	{stringtableentry midpoints_on}                 // on, off -> option inverted
	{stringtableentry midpoints_off}
	{stringtableentry keeprng_normal}
	{stringtableentry keeprng_highlighted}
	{stringtableentry keeprng_off}
	{stringtableentry keeprng_on}
	{stringtableentry music_normal}
	{stringtableentry music_highlighted}
	{stringtableentry music_on}                     // on, off -> option inverted
	{stringtableentry music_off}
	{stringtableentry godmode_normal}
	{stringtableentry godmode_highlighted}
	{stringtableentry godmode_off}
	{stringtableentry godmode_on}
{loadpc}


// Hack initial config menu routine to add more strings.
{savepc}
	{reorg $80EA5C}
	jml config_menu_start_hook
{loadpc}
config_menu_start_hook:
	// We enter with A/X/Y 8-bit and bank set to $86 (our code bank)
	// Deleted code.  We need to do this first, or 8100 fails.
	lda.b #7
	tsb.w $7E00A2

	ldx.b #0
.string_loop:
	lda.w config_menu_extra_string_table, x
	phx
	beq .string_flush
	cmp.b #$FF
	beq .special
	jsl trampoline_8089CA
	bra .string_next
.special:
	// Call a function
	inx
	clc   // having carry clear is convenient for these functions
	jsr (config_menu_extra_string_table, x)
	jsl trampoline_8089CA
	plx
	inx
	inx
	bra .special_resume
.string_flush:
	jsl trampoline_808100
.string_next:
	plx
.special_resume:  // save 1 byte by using the extra inx here
	inx
	cpx.b #config_menu_extra_string_table.end - config_menu_extra_string_table
	bne .string_loop

	jml $80EA61


// Table of static strings to render at config screen load time.
config_menu_extra_string_table:
	// Extra call to 8100 to execute and flush the draw buffer before our first
	// string, otherwise we end up drawing too much.
	db $00
	// The percent sign needs to be done alone.
	db {stringid_percent_sign_bitmap}
	// Selectable option labels.
	db {stringid_midpoints_normal}
	db {stringid_keeprng_normal}
	db {stringid_godmode_normal}
	db {stringid_music_normal}
	db $00  // flush
	db {stringid_category_normal}
	db $FF
	dw config_get_stringid_route1_label
	db $FF
	dw config_get_stringid_route2_label
	db $00  // flush
	// Extra option values.
	db $FF
	dw config_get_stringid_category
	db $FF
	dw config_get_stringid_route1
	db $FF
	dw config_get_stringid_route2
	db $FF
	dw config_get_stringid_midpointsoff
	db $FF
	dw config_get_stringid_keeprng
	db $FF
	dw config_get_stringid_musicoff
	db $00  // flush
	db $27  // EXIT
	db $FF
	dw config_get_stringid_godmode
	// We return to a flush call.
.end:


// Trampoline for calling $808100  (flush string draw buffer?)
trampoline_808100:
	pea ({rom_rtl_instruction} - 1) & 0xFFFF
	jml $808100
// Trampoline for calling $8089CA  (draw string)
trampoline_8089CA:
	pea ({rom_rtl_instruction} - 1) & 0xFFFF
	jml $8089CA
// Trampoline for calling $808862
//trampoline_808862:
//	pea ({rom_rtl_instruction} - 1) & 0xFFFF
//	jml $808862


// Functions to get the string to show for the current setting.
// We enter each function with carry clear for convenience.

// Gets string ID to show for the top route option's label.
config_get_stringid_route1_label:
	lda.l {sram_config_category}
	and.b #$01
	beq .100p
	lda.b #{stringid_mammoth_normal}
	rts
.100p:
	lda.b #{stringid_ice_normal}
	rts

// Gets string ID to show for the bottom route option's label.
config_get_stringid_route2_label:
	lda.l {sram_config_category}
	and.b #$01
	beq .100p
	lda.b #{stringid_empty_route2_normal}
	rts
.100p:
	lda.b #{stringid_water_normal}
	rts

config_get_stringid_category:
	lda.l {sram_config_category}
	and.b #$01
	adc.b #{stringid_100percent}
	rts

config_get_stringid_route1:
	lda.l {sram_config_category}
	bne .route_anyp
	lda.l {sram_config_route}
	lsr
	and.b #1
	clc
	adc.b #{stringid_iceless}
	rts
.route_anyp:
	lda.l {sram_config_route}
	cmp.b #5
	bcc .ok_anyp
	lda.b #0
.ok_anyp:
	adc.b #{stringid_mammoth_5th}
	rts

config_get_stringid_route2:
	lda.l {sram_config_category}
	bne .route_anyp
	lda.l {sram_config_route}
	and.b #1
	clc
	adc.b #{stringid_waterful}
	rts
.route_anyp:
	lda.b #{stringid_empty_route2_setting}
	rts

config_get_stringid_midpointsoff:
	lda.l {sram_config_midpointsoff}
	and.b #$01
	adc.b #{stringid_midpoints_on}
	rts

config_get_stringid_keeprng:
	lda.l {sram_config_keeprng}
	and.b #$01
	adc.b #{stringid_keeprng_off}
	rts

config_get_stringid_musicoff:
	lda.l {sram_config_musicoff}
	and.b #$01
	adc.b #{stringid_music_on}
	rts

config_get_stringid_godmode:
	lda.l {sram_config_godmode}
	and.b #$01
	adc.b #{stringid_godmode_off}
	rts


// Mapping from config option ID to unhighlighted string ID.
// Used for drawing the blue text when unhighlighting the previous option.
{savepc}
	// Use our alternate table.
	{reorg $80EA52}
	jsr config_string_table_lookup_thunk
	{reorg $80EAFC}
	jsr config_string_table_lookup_thunk
	{reorg $80EB19}
	jsr config_string_table_lookup_thunk
	// Don't special-case stereo/mono when highlighting.
	{reorg $80EB1F}
	bra $80EB2F
{loadpc}
config_unhighlighted_stringids:
	db $1F   // SHOT
	db $1D   // JUMP
	db $2D   // DASH
	db $21   // SEL_L
	db $23   // SEL_R
	db $25   // MENU
	db {stringid_output_normal}
	db {stringid_music_normal}
	db $29   // BGM
	db $2B   // S.E.
	db {stringid_category_normal}
	db {stringid_ice_normal}
.route2:
	db {stringid_water_normal}
	db {stringid_midpoints_normal}
	db {stringid_keeprng_normal}
	db {stringid_godmode_normal}
	db $27   // EXIT
.end:
// Routine to look up the "unhighlighted" string ID.
config_string_table_lookup:
	// Load from the alternate table.
	lda.w config_unhighlighted_stringids, x
	// Check for special cases.
	cmp.b #{stringid_ice_normal}
	beq .special_route1
	cmp.b #{stringid_water_normal}
	beq .special_route2
	// Not special.
	rtl
.special_route1:
	// Decide whether to show "ICE..." here or "MAMMOTH".
	lda.l {sram_config_category}
	beq .ice
	lda.b #{stringid_mammoth_normal}
	rtl
.ice:
	lda.b #{stringid_ice_normal}
	rtl
.special_route2:
	// Decide whether to show "WATER..." here or blank.
	lda.l {sram_config_category}
	beq .water
	lda.b #{stringid_empty_route2_normal}
	rtl
.water:
	lda.b #{stringid_water_normal}
	rtl


// Config menu code hacks.
{savepc}
	// Hook incrementing and decrementing so that we can skip the second
	// route option when it's disabled.
	{reorg $80EAB8}
	jml config_hook_increment
	{reorg $80EAC7}
	jml config_hook_decrement

	// Increase number of options.
	{reorg $80EADB}
	lda.b #((config_option_jump_table.end - config_option_jump_table) / 3) - 1
	{reorg $80EAE3}
	cmp.b #(config_option_jump_table.end - config_option_jump_table) / 3

	// Don't handle stereo/mono specially in the above table.
	{reorg $80EB01}
	bra $80EB11
	// Thunk to call our code for alternate string loads, used by
	// config_unhighlighted_stringids.  Needs to be in bank 80.
config_string_table_lookup_thunk:
	jsl config_string_table_lookup
	rts

	// Use unhighlighted string IDs for STEREO/MONO.
	{reorg $80EBFC}
	lda.b #$40
	{reorg $80EC16}
	lda.b #$42

	// Use config_option_jump_table instead of the built-in one.
	// Note that we can overwrite the config table.
	{reorg $80EB3D}
	// clc not necessary because of asl of small value
	adc.l {config_selected_option}
	tax
	lda.l config_option_jump_table + 2, x
	pha
	rep #$20
	lda.l config_option_jump_table + 0, x
	pha
	sep #$20
	rtl

{loadpc}
config_option_jump_table:
	// These are minus one due to using RTL to jump to them.
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_stereo} - 1
	dl config_code_musicoff - 1
	dl {rom_config_bgm} - 1
	dl {rom_config_se} - 1
	dl config_code_category - 1
	dl config_code_route1 - 1
	dl config_code_route2 - 1
	dl config_code_midpoint - 1
	dl config_code_keeprng - 1
	dl config_code_godmode - 1
	dl {rom_config_exit} - 1
.end:


// Skip over second route option when it's disabled.
config_hook_increment:
	lda.l {config_selected_option}
	inc
	cmp.b #config_unhighlighted_stringids.route2 - config_unhighlighted_stringids
	beq .maybe_skip
.write_return:
	sta.l {config_selected_option}
	jml $80EAD5
.maybe_skip:
	// Decide whether to skip
	lda.l {sram_config_category}
	and.b #1
	clc
	adc.b #config_unhighlighted_stringids.route2 - config_unhighlighted_stringids
	bra .write_return

config_hook_decrement:
	lda.l {config_selected_option}
	dec
	cmp.b #config_unhighlighted_stringids.route2 - config_unhighlighted_stringids
	bne config_hook_increment.write_return
	// Decide whether to skip
	lda.l {sram_config_category}
	eor.b #1
	lsr
	adc.b #config_unhighlighted_stringids.route2 - config_unhighlighted_stringids - 1
	bra config_hook_increment.write_return


// Config code for "category" route option.
config_code_category:
	// Was left or right pressed?
	lda.b {controller_1_new} + 1
	and.b #$03
	beq .no_change
	// Zero route within category.
	lda.b #0
	sta.l {sram_config_route}
	// Change categories.
	lda.l {sram_config_category}
	eor.b #1
	and.b #1
	sta.l {sram_config_category}
	// Draw new strings appropriate to category.
	// (Multiply by 5 here.)
	asl
	asl
	adc.l {sram_config_category}
	tax
	ldy.b #0
	// Draw 5 strings.
.draw_loop:
	lda.l .string_list, x
	phx
	phy
	jsl trampoline_8089CA
	ply
	plx
	inx
	iny
	cpy.b #5
	bne .draw_loop
	// Done.
.no_change:
	jmp config_extra_toggle.no_change
.string_list:
	// String IDs for switching to 100%.
	db {stringid_100percent}
	db {stringid_ice_normal}
	db {stringid_iceless}
	db {stringid_water_normal}
	db {stringid_waterful}
	// String IDs for switching to Any%.
	db {stringid_anypercent}
	db {stringid_mammoth_normal}
	db {stringid_mammoth_5th}
	db {stringid_empty_route2_normal}
	db {stringid_empty_route2_setting}

// Config code for first route option (100%: "ICE", Any%: "MAMMOTH").
config_code_route1:
	// Any% or 100%?
	lda.l {sram_config_category}
	bne .anypercent
	// 100% case.
	// Was left or right pressed?
	lda.b {controller_1_new} + 1
	and.b #$03
	beq .no_change
	// 100% case: toggle iceless.
	lda.l {sram_config_route}
	eor.b #$02
	and.b #$03
	sta.l {sram_config_route}
	// Get string to draw and draw it.
.draw_string_route1:
	jsr config_get_stringid_route1
.draw_string:
	jmp config_extra_toggle.draw_string
.no_change:
	jmp config_extra_toggle.no_change
.anypercent:
	// Any% case.
	// Was left or right pressed?
	lda.b {controller_1_new} + 1
	and.b #$03
	beq .no_change   // neither pressed
	cmp.b #$03
	beq .no_change   // both left and right pressed; do nothing
	// Check for right.
	lsr
	lda.l {sram_config_route}
	bcc .left
	// Right pressed.
	inc
	bra .update
.left:
	dec
.update:
	and.b #$03
	sta.l {sram_config_route}
	// Decide string to show.
	bra .draw_string_route1

// Config code for second route option (100% only: waterful/less)
config_code_route2:
	// Was left or right pressed?
	lda.b {controller_1_new} + 1
	and.b #$03
	beq config_code_route1.no_change
	// Toggle waterful.
	lda.l {sram_config_route}
	eor.b #$01
	sta.l {sram_config_route}
	// Decide string to show.
	jsr config_get_stringid_route2
	bra config_code_route1.draw_string

// Config code for simple toggles.
config_code_musicoff:
	ldx.b #{sram_config_musicoff} - {sram_config_extra}
	ldy.b #{stringid_music_on}
	bra config_extra_toggle

config_code_midpoint:
	ldx.b #{sram_config_midpointsoff} - {sram_config_extra}
	ldy.b #{stringid_midpoints_on}
	bra config_extra_toggle

config_code_keeprng:
	ldx.b #{sram_config_keeprng} - {sram_config_extra}
	ldy.b #{stringid_keeprng_off}
	bra config_extra_toggle

config_code_godmode:
	ldx.b #{sram_config_godmode} - {sram_config_extra}
	ldy.b #{stringid_godmode_off}
	bra config_extra_toggle

// Shared routines for simple toggles.
// X = index into sram_config_extra
// Y = string ID of default (zero) option.
config_extra_toggle:
//	jsl trampoline_808862
	// Was left or right pressed?
	lda.b {controller_1_new} + 1
	and.b #$03
	beq .no_change
	// Toggle the flag.
	lda.l {sram_config_extra}, x
	and.b #$01
	eor.b #$01
	sta.l {sram_config_extra}, x
	// Draw the new string.
	beq .zero
	iny
.zero:
	tya
.draw_string:
	jsl trampoline_8089CA
.no_change:
	jsl trampoline_808100
	jml {rom_config_loop}


//
// Saved state hacks
//
{savepc}
//	{reorg $8081A9}
//	jml nmi_hook
	{reorg $8081A3}
nmi_patch:
	// We use controller 2's state, which is ignored by the game unless debug
	// modes are enabled (which we don't do).  Controller 2 state is the state
	// of the "real" controller.  When the game disables the controller, we
	// simply don't copy controller 2 to controller 1.

	// Move previous frame's controller data to the previous field.
	lda.b {controller_2_current}
	sta.b {controller_2_previous}

	// Read controller 1 port.  This is optimized from the original slightly.
	lda.w $4218
	bit.w #$000F
	beq .controller_valid
	lda.w #0
.controller_valid:

	// Update controller 2 variables, which is where we store the actual
	// controller state.
	sta.b {controller_2_current}
	eor.b {controller_2_previous}
	and.b {controller_2_current}
	sta.b {controller_2_new}

	// If controller is enabled, copy 2's state to 1's state.
	lda.w {controller_1_disable}
	and.w #$00FF
	bne .controller_disabled
	lda.b {controller_2_current}
	sta.b {controller_1_current}
	lda.b {controller_2_previous}
	sta.b {controller_1_previous}
	lda.b {controller_2_new}
	sta.b {controller_1_new}
.controller_disabled:

	// Check for Select being held.  Jump to nmi_hook if so.
	lda.b {controller_2_current}
	bit.w #$2000
	beq .resume_nmi
	jml nmi_hook
.resume_nmi:

	// As of writing this, we have 4 bytes free here.
	bra {rom_nmi_after_controller}
{loadpc}

{reorg $84EE00}
// Called at program startup.
init_hook:
	// Deleted code.
	sta.l $7EFFFF
	// What we need to do at startup.
	sta.l {sram_previous_command}
	sta.l {sram_previous_command}+1
	// Return to original code.
	jml $808016

// Called during NMI if select is being held.
nmi_hook:
	// Check for L or R newly being pressed.
	lda.b {controller_2_new}
	and.w #$0030

	// We now can execute slow code, because we know that the player is giving
	// us a command to do.

	// This is a command to us, so we want to hide the button press from the game.
	tax
	lda.w #$FFCF
	and.b {controller_2_current}
	sta.b {controller_2_current}
	lda.w #$FFCF
	and.b {controller_2_new}
	sta.b {controller_2_new}

	// If controller data is enabled, copy these new fields, too.
	lda.w {controller_1_disable}
	and.w #$00FF
	bne .controller_disabled
	lda.b {controller_2_current}
	sta.b {controller_1_current}
	lda.b {controller_2_new}
	sta.b {controller_1_new}
.controller_disabled:
	txa

	// We need to suppress repeating ourselves when L or R is held down.
	cmp.l {sram_previous_command}
	beq .return_normal_no_rep
	sta.l {sram_previous_command}

	// Distinguish between the cases.
	cmp.w #$0010
	beq .select_r
	cmp.w #$0020
	bne .return_normal_no_rep
	jmp .select_l

// Resume NMI handler, skipping the register pushes.
.return_normal:
	rep #$38
.return_normal_no_rep:
	jml {rom_nmi_after_controller}

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


	// Mark the save as invalid in case we lose power or crash while saving.
	rep #$30
	lda.w #0
	sta.l {sram_validity}
	sta.l {sram_validity} + 2

	// Store DMA registers' values to SRAM.
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
	// Copy OAM 000-23F to SRAM 772200-77243F.
	dw $0000 | $2102, $0000  // OAM address
	dw $0000 | $4310, $3880  // direction = B->A, byte reg, B addr = $2138
	dw $0000 | $4312, $2200  // A addr = $xx2200
	dw $0000 | $4314, $4077  // A addr = $77xxxx, size = $xx40
	dw $0000 | $4316, $0002  // size = $02xx ($0240), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Done
	dw $0000, .save_return

.save_return:
	// Restore null bank.
	pea $0000
	plb
	plb

	// Save stack pointer.
	rep #$30
	tsa
	sta.l {sram_saved_sp}

	// Mark the save as valid.
	lda.w #{magic_sram_tag_lo}
	sta.l {sram_validity}
	lda.w #{magic_sram_tag_hi}
	sta.l {sram_validity} + 2

.register_restore_return:
	// Restore register state for return.
	sep #$20
	lda.b {nmi_control_shadow}
	sta.w $4200
	lda.b {hdma_control_shadow}
	sta.w $420C
	lda.b {screen_control_shadow}
	sta.w $2100

	// Copy actual SPC state to shadow SPC state, or the game gets confused.
	lda.w $2142
	sta.l {spc_state_shadow}

	// Return to the game's NMI handler.
	rep #$38
	jml {rom_nmi_after_controller}

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

	// Save the RNG value to a location that gets loaded after the RNG value.
	// This way, we preserve the RNG value into the loaded state.
	// NOTE: Bank set to 00 above.
	rep #$20
	lda.w {rng_value}
	sta.l {load_temporary_rng}

	// Execute VM to do DMAs
	ldx.w #.load_write_table
.jmp_run_vm:
	jmp .run_vm

.load_after_7E_done:
	// We enter with 16-bit A/X/Y.
	// Restore the RNG value with what we saved before.
	lda.l {sram_config_keeprng}
	and.w #$00FF
	bne .jmp_run_vm
	lda.l {load_temporary_rng}
	sta.l {rng_value}
	bra .jmp_run_vm

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
	// Reload variables from 7E we didn't want to reload from SRAM.
	dw $0000, .load_after_7E_done
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
	// Copy SRAM 772200-77243F to OAM 000-23F.
	dw $0000 | $2102, $0000  // OAM address
	dw $0000 | $4310, $0400  // direction = A->B, byte reg, B addr = $2104
	dw $0000 | $4312, $2200  // A addr = $xx2200
	dw $0000 | $4314, $4077  // A addr = $77xxxx, size = $xx40
	dw $0000 | $4316, $0002  // size = $02xx ($0240), unused bank reg = $00.
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

	// Load DMA registers' state from SRAM.
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
	// X will be set to the next "instruction" in case resuming the VM
	// is desired.
	inx
	inx
	inx
	inx
	jmp ($FFFE,x)


// Returns whether configuration is saved in the zero flag.
// Must be called with 16-bit A!
is_config_saved:
	// Check magic values.
	lda.l {sram_config_valid}
	cmp.w #{magic_config_tag_lo}
	bne .not_saved
	lda.l {sram_config_valid} + 2
	cmp.w #{magic_config_tag_hi}
	bne .not_saved

	// Check for bad extra configuration.
	// Loads both route and category since A is 16-bit.
	lda.l {sram_config_category}
	and.w #~($0301)
	bne .not_saved
	// These are simple Boolean flags.
	lda.l {sram_config_midpointsoff}  // also sram_config_keeprng
	and.w #~($0101)
	bne .not_saved
	lda.l {sram_config_musicoff}  // also sram_config_godmode
	and.w #~($0101)
.not_saved:
	rts


// Hook the initialization of the configuration data, to provide saving
// the configuration in SRAM.
{savepc}
	{reorg $8085DE}
	// config_init_hook changes the bank.
	phb
	jsl config_init_hook
	plb
	bra $8085EB
{loadpc}
config_init_hook:
	// The controller configuration was not in RAM, so initialize it.
	// We want to use the data from SRAM in this case - if any.
	rep #$30
	jsr is_config_saved
	bne .not_saved

	// Config was saved, so load from SRAM.
	lda.w #({sram_config_game} >> 16)
	ldy.w #{sram_config_game}
	bra .initialize

.not_saved:
	// Config was not saved, so set to default.
	// Set our extra config to default.
	sep #$30
	lda.b #0
	ldx.b #0
.extra_default_loop:
	sta.l {sram_config_extra}, x
	inx
	cpx.b #{sram_config_extra_size}
	bne .extra_default_loop
	rep #$30

	// Copy from ROM's default config to game config.
	lda.w #({rom_default_config} >> 16)
	ldy.w #{rom_default_config}

.initialize:
	// Keep X/Y at 16-bit for now.
	sep #$20
	// Set bank as specified.
	pha
	plb
	// Copy configuration from either ROM or SRAM.
	ldx.w #0
.initialize_loop:
	lda $0000, y
	sta.l {config_data}, x
	iny
	inx
	cpx.w #{game_config_size}
	bcc .initialize_loop

	// Save configuration if needed.
	sep #$30
	bra maybe_save_config


// Hook the config menu to save automatically.
{savepc}
	{reorg $80EAAA}
	jml config_menu_hook
{loadpc}
config_menu_hook:
	// Save config if anything changed.
	jsl maybe_save_config
	// Deleted code.
	lda.l $7EFF80
	jml $80EAAE


// Save configuration if different or unset.
// Called with JSL.
maybe_save_config:
	php

	// If config not saved at all, save now.
	rep #$20
	jsr is_config_saved
	sep #$30
	bne .do_save

	// Otherwise, check whether different.
	// It's bad to continuously write to SRAM because an SD2SNES will then
	// constantly write to the SD card.
	ldx.b #0
.check_loop:
	// Ignore changes to the BGM and SE values.  The game resets them anyway.
	cpx.b #{config_bgm} - {config_data}
	beq .check_skip
	cpx.b #{config_se} - {config_data}
	beq .check_skip
	lda.l {config_data}, x
	cmp.l {sram_config_game}, x
	bne .do_save
.check_skip:
	inx
	cpx.b #{game_config_size}
	bcc .check_loop

.return:
	plp
	rtl

	// We should save.
.do_save:
	// Clear the magic value during the save.
	rep #$20
	lda.w #0
	sta.l {sram_config_valid} + 0
	sta.l {sram_config_valid} + 2
	// Copy config to SRAM.
	sep #$30
	ldx.b #0
.save_loop:
	lda.l {config_data}, x
	sta.l {sram_config_game}, x
	inx
	cpx.b #{game_config_size}
	bcc .save_loop

	// Set the magic value.
	rep #$20
	lda.w #{magic_config_tag_lo}
	sta.l {sram_config_valid} + 0
	lda.w #{magic_config_tag_hi}
	sta.l {sram_config_valid} + 2

	// Done.
	bra .return


// Prohibit the select button from being used as a gameplay button.
{savepc}
	// Ignore direct button presses of select.
	{reorg $80EB69}
	and.b #$01  // instead of $03.  $02 is select.

	// Hook pressing left in key config.
	{reorg $80EB8A}
	jml config_left_hook
	// Hook pressing right in key config.
	{reorg $80EB8E}
	jml config_right_hook
{loadpc}
config_left_hook:
	// A is 8-bit.  OK to destroy A.  It's loaded right after.
	lda.b $00
.repeat:
	// Do the shift left that was intended.
	asl
	// If select, skip it.
	cmp.b #$02
	beq .repeat
	bra config_right_hook.return

// Same thing, but for pressing right, which is a right shift.
config_right_hook:
	lda.b $00
.repeat:
	lsr
	cmp.b #$02
	beq .repeat

// Shared by config_left_hook and config_right_hook
.return:
	// Save new value of $00.
	sta.b $00
	// Return to where the game wants us.
	jml $80EBA0


// God mode - infinite energy.
{savepc}
	{reorg $849D50}
	jmp x_energy_hook
{loadpc}
x_energy_hook:
	// Enter with A=8-bit.  Y can be destroyed.
	// Save current energy in Y.
	tay
	// Check whether we have god mode enabled.
	lda.l {sram_config_godmode}
	bne .skip_subtract
	// Deleted code - subtract X energy.
	tya
	sec
	sbc.w $7E0000
	tay
.skip_subtract:
	// NOTE: Also sets zero and sign flags, which we need.
	tya
	// Return the caller.
	jmp $849D54


// God mode - infinite weapons.
{savepc}
	// Normal weapons.
	{reorg $8194EA}
	jsl weapon_energy_hook
	nop
	nop
	// Charged weapons.
	{reorg $81950C}
	jsl weapon_energy_hook
	nop
	nop
{loadpc}
weapon_energy_hook:
	// Enter with A=16-bit.
	pha
	// Check for god mode flag.
	lda.l {sram_config_godmode}
	and.w #$00FF
	bne .skip_store
	pla
	// Deleted code.
	ora.w #$C000
	sta.w {weapon_power}, x
	bra .skip_pla
.skip_store:
	pla
.skip_pla:
	rtl


// God mode - hack Vile AI to shoot trapping shot regardless of X's health
// while in god mode.
{savepc}
	// Intro stage Vile.
	{reorg $83D718}
	jml vile_intro_ai_hack
	// Sigma stage Vile.
	{reorg $83EE86}
	jml vile_sigma1_ai_hack
{loadpc}
vile_intro_ai_hack:
	cmp.b #4
	bcc .shoot_trap
	lda.l {sram_config_godmode}
	bne .shoot_trap
	jml $83D71E
.shoot_trap:
	jml $83D71C

vile_sigma1_ai_hack:
	cmp.b #7
	bcc .shoot_trap
	lda.l {sram_config_godmode}
	bne .shoot_trap
	jml $83EE8C
.shoot_trap:
	jml $83EE8A


// Midpoint disable.
{savepc}
	{reorg $80E6A2}
	jml midpoint_load_hook
{loadpc}
midpoint_load_hook:
	// If midpoints are to be disabled, zero the midpoint flag.
	sep #$20
	lda.l {sram_config_midpointsoff}
	beq .midpoints_on
	stz.w {midpoint_flag}
.midpoints_on:
	// Deleted code
	rep #$20
	lda.w {midpoint_flag}
	jml $80E6A7


// Music disable.
{savepc}
	{reorg $808799}
	jml play_music_hook
{loadpc}
play_music_hook:
	// We want A=8 for the moment.  Also, deleted code.
	sep #$30
	// Save the song ID to stack.
	pha
	// Check for the "music off" config setting.
	lda.l {sram_config_musicoff}
	beq .music_on
	// Stack layout at this point:
	// S -> byte before stack
	//      saved song number
	//      low byte of 808799's near return address
	//      high byte of 808799's near return address
	//      low byte of 80878B's saved D register      \ 
	//      high byte of 80878B's saved D register      \ 
	//      80878B's saved P register                    > assuming caller was rom_play_music
	//      low byte of 80878B's far return address     /
	//      high byte of 80878B's far return address   /
	//      low byte of 80878B's far return address   /
	// Check whether the caller was rom_play_music (middle of $80878B).
	rep #$20
	lda 2, s
	cmp.w #($808796 - 1) & $FFFF
	bne .music_off
	// Check whether rom_play_music's caller is the config menu's BGM option.
	lda 7, s
	cmp.w #($80EC6B - 1) & $FFFF
	bne .music_off
	sep #$20
	lda 9, s
	cmp.b #$80EC6B >> 16
	beq .music_on
.music_off:
	// Music is off, and we're not in the config screen.
	sep #$30
	pla
	jml {rom_rts_instruction}
.music_on:
	// Deleted code, but we need for pla.
	sep #$30
	// Restore song ID.
	pla
	// Deleted code.
	tay
	lda $806B, y
	// Return to play_music code.
	jml $80879F


// The state table for each level is in statetable.asm.
incsrc "statetable.asm"
