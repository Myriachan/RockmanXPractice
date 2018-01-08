// The state table data for the game.  It turns out that the state of which
// items are collected and which bosses are defeated are all in one 48-byte
// region of memory.  We can use these blocks as hardcoded saved states,
// because they're all that we need to overwrite to get the game into the
// right state for the route.
//
// This table has redundant entries removed.  Redundant entries occur before
// multiple routes diverge and after multiple routes converge.  For example,
// regardless of your 100% route choice, after the 8 Mavericks, you will be at
// the point where you need to revisit Penguin for the heart tank and revisit
// Armadillo for the Hadouken prior to the Sigma stages.
//
// A merge also happens in the middle of 100%: after four stages, both the
// Iceless and Iceful routes have the same four bosses defeated and the same
// items collected.


// *** START OF BANK AF HACKS ***
// Where the state table area starts.
{reorg $AFEA00}


// For getting the bank of this data.
state_bank:


// Pointers to the level lookup tables of each route.
state_table_lookup:
	// 100%
	dw state_indexes_100p_iceless_waterful
	dw state_indexes_100p_iceless_waterless
	dw state_indexes_100p_iceless_cham3rd
	dw state_indexes_100p_iceful_waterful
	dw state_indexes_100p_iceful_waterless
	// Any%
	dw state_indexes_anyp_mammoth_5th
	dw state_indexes_anyp_mammoth_6th
	dw state_indexes_anyp_mammoth_7th
	dw state_indexes_anyp_mammoth_8th
	// stage_choice_hack considers each table to be 5 long, but if there is
	// no way to access it, we don't need to fill in the last entry.


// Places an entry in the index table that has no revisit.
macro state_index_single label
	db ({label} - state_table_base) / 48
	db ({label} - state_table_base) / 48
endmacro

// Places an entry in the index table that has a revisit.
macro state_index_revisit label1, label2
	db ({label1} - state_table_base) / 48
	db ({label2} - state_table_base) / 48
endmacro


// The table indexes go in this order, which is level numbering order:
// - Intro stage
// - Launch Octopus
// - Sting Chameleon
// - Armored Armadillo
// - Flame Mammoth
// - Storm Eagle
// - Spark Mandrill
// - Boomer Kuwanger
// - Chill Penguin
// - Sigma 1
// - Sigma 2
// - Sigma 3
// - Sigma 4


// Indexes into the table for 100% Iceless Waterful route.
state_indexes_100p_iceless_waterful:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_100p_waterful_octopus}
	{state_index_single state_100p_waterful_chameleon}
	{state_index_revisit state_100p_waterful_armadillo, state_100p_shared_armadillo_revisit}
	{state_index_single state_100p_iceless_mammoth}
	{state_index_single state_100p_iceless_eagle}
	{state_index_single state_100p_waterful_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_revisit state_shared_penguin, state_100p_shared_penguin_revisit}
	{state_index_revisit state_100p_shared_sigma1_zero_intro, state_100p_shared_sigma1_no_intro}
	{state_index_single state_100p_shared_sigma2}
	{state_index_single state_100p_shared_sigma3}
	{state_index_single state_100p_shared_sigma4}

// Indexes into the table for 100% Iceless Waterless route.
state_indexes_100p_iceless_waterless:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_100p_waterless_octopus}
	{state_index_single state_100p_waterless_chameleon}
	{state_index_revisit state_100p_waterless_armadillo, state_100p_shared_armadillo_revisit}
	{state_index_single state_100p_iceless_mammoth}
	{state_index_single state_100p_iceless_eagle}
	{state_index_single state_100p_waterless_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_revisit state_shared_penguin, state_100p_shared_penguin_revisit}
	{state_index_revisit state_100p_shared_sigma1_zero_intro, state_100p_shared_sigma1_no_intro}
	{state_index_single state_100p_shared_sigma2}
	{state_index_single state_100p_shared_sigma3}
	{state_index_single state_100p_shared_sigma4}

// Indexes into the table for 100% Iceless Chameleon 3rd route.
state_indexes_100p_iceless_cham3rd:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_100p_waterless_octopus}
	{state_index_single state_100p_cham3rd_chameleon}
	{state_index_revisit state_100p_waterless_armadillo, state_100p_shared_armadillo_revisit}
	{state_index_single state_100p_cham3rd_mammoth}
	{state_index_single state_100p_cham3rd_eagle}
	{state_index_single state_100p_waterless_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_revisit state_shared_penguin, state_100p_shared_penguin_revisit}
	{state_index_revisit state_100p_shared_sigma1_zero_intro, state_100p_shared_sigma1_no_intro}
	{state_index_single state_100p_shared_sigma2}
	{state_index_single state_100p_shared_sigma3}
	{state_index_single state_100p_shared_sigma4}

// Indexes into the table for 100% Iceful Waterful route.
state_indexes_100p_iceful_waterful:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_100p_waterful_octopus}
	{state_index_single state_100p_waterful_chameleon}
	{state_index_revisit state_100p_waterful_armadillo, state_100p_shared_armadillo_revisit}
	{state_index_single state_100p_iceful_mammoth}
	{state_index_single state_100p_iceful_eagle}
	{state_index_single state_100p_waterful_mandrill}
	{state_index_single state_100p_iceful_kuwanger}
	{state_index_revisit state_shared_penguin, state_100p_shared_penguin_revisit}
	{state_index_revisit state_100p_shared_sigma1_zero_intro, state_100p_shared_sigma1_no_intro}
	{state_index_single state_100p_shared_sigma2}
	{state_index_single state_100p_shared_sigma3}
	{state_index_single state_100p_shared_sigma4}

// Indexes into the table for 100% Iceful Waterless route.
state_indexes_100p_iceful_waterless:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_100p_waterless_octopus}
	{state_index_single state_100p_waterless_chameleon}
	{state_index_revisit state_100p_waterless_armadillo, state_100p_shared_armadillo_revisit}
	{state_index_single state_100p_iceful_mammoth}
	{state_index_single state_100p_iceful_eagle}
	{state_index_single state_100p_waterless_mandrill}
	{state_index_single state_100p_iceful_kuwanger}
	{state_index_revisit state_shared_penguin, state_100p_shared_penguin_revisit}
	{state_index_revisit state_100p_shared_sigma1_zero_intro, state_100p_shared_sigma1_no_intro}
	{state_index_single state_100p_shared_sigma2}
	{state_index_single state_100p_shared_sigma3}
	{state_index_single state_100p_shared_sigma4}

// Indexes into the table for Any% Mammoth 8th route.
state_indexes_anyp_mammoth_8th:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_anyp_m8th_octopus}
	{state_index_single state_anyp_shared_chameleon}
	{state_index_single state_anyp_m8th_armadillo}
	{state_index_single state_anyp_m8th_mammoth}
	{state_index_single state_anyp_shared_eagle}
	{state_index_single state_anyp_m8th_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_single state_shared_penguin}
	{state_index_revisit state_anyp_shared_sigma1_zero_intro, state_anyp_shared_sigma1_no_intro}
	{state_index_single state_anyp_shared_sigma2}
	{state_index_single state_anyp_shared_sigma3}
	{state_index_single state_anyp_shared_sigma4}

// Indexes into the table for Any% Mammoth 7th route.
state_indexes_anyp_mammoth_7th:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_anyp_m7th_octopus}
	{state_index_single state_anyp_shared_chameleon}
	{state_index_single state_anyp_m8th_armadillo}
	{state_index_single state_anyp_m7th_mammoth}
	{state_index_single state_anyp_shared_eagle}
	{state_index_single state_anyp_m8th_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_single state_shared_penguin}
	{state_index_revisit state_anyp_shared_sigma1_zero_intro, state_anyp_shared_sigma1_no_intro}
	{state_index_single state_anyp_shared_sigma2}
	{state_index_single state_anyp_shared_sigma3}
	{state_index_single state_anyp_shared_sigma4}

// Indexes into the table for Any% Mammoth 6th route.
state_indexes_anyp_mammoth_6th:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_anyp_m7th_octopus}
	{state_index_single state_anyp_shared_chameleon}
	{state_index_single state_anyp_m6th_armadillo}
	{state_index_single state_anyp_m6th_mammoth}
	{state_index_single state_anyp_shared_eagle}
	{state_index_single state_anyp_m8th_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_single state_shared_penguin}
	{state_index_revisit state_anyp_shared_sigma1_zero_intro, state_anyp_shared_sigma1_no_intro}
	{state_index_single state_anyp_shared_sigma2}
	{state_index_single state_anyp_shared_sigma3}
	{state_index_single state_anyp_shared_sigma4}

// Indexes into the table for Any% Mammoth 5th route.
state_indexes_anyp_mammoth_5th:
	{state_index_single state_shared_intro_stage}
	{state_index_single state_anyp_m7th_octopus}
	{state_index_single state_anyp_shared_chameleon}
	{state_index_single state_anyp_m6th_armadillo}
	{state_index_single state_anyp_m5th_mammoth}
	{state_index_single state_anyp_shared_eagle}
	{state_index_single state_anyp_m5th_mandrill}
	{state_index_single state_shared_kuwanger_2nd}
	{state_index_single state_shared_penguin}
	{state_index_revisit state_anyp_shared_sigma1_zero_intro, state_anyp_shared_sigma1_no_intro}
	{state_index_single state_anyp_shared_sigma2}
	{state_index_single state_anyp_shared_sigma3}
	{state_index_single state_anyp_shared_sigma4}


// Base from which multiples of 48 are counted.
state_table_base:

//
// Shared section - used among all routes.
//
state_shared_intro_stage:
	//db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 \
	//db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  > True values. Not using so doesn't repeat.
	//db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$00,$00,$00,$00,$00 /
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$04,$00,$00,$00,$00
// Penguin is shared among all routes because no items yet and it's first in all.
state_shared_penguin:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$10,$04,$00,$00,$00,$00
// Kuwanger is shared when second, because Penguin heart can't be collected.
state_shared_kuwanger_2nd:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00


//
// States for 100% Iceless routes - the first four stages, minus shared ones.
//
state_100p_iceless_eagle:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$12,$10,$20,$00,$00,$00
state_100p_iceless_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $02,$00,$01,$82,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$19,$14,$04,$24,$00,$00,$00

//
// States for 100% Iceful routes - the first four stages, minus Penguin.
//
state_100p_iceful_eagle:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_100p_iceful_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$00,$00,$DC,$00,$DC,$19,$12,$04,$04,$00,$00,$00
state_100p_iceful_kuwanger:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$00,$00,$DC,$00,$DC,$9B,$14,$04,$14,$00,$00,$00

//
// States for 100% Waterful routes - the last four stages.
//
state_100p_waterful_mandrill:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$9B,$16,$04,$34,$00,$00,$00
state_100p_waterful_armadillo:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$18,$04,$74,$00,$00,$00
state_100p_waterful_octopus:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00
	db $02,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$00,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$1A,$04,$76,$00,$00,$00
state_100p_waterful_chameleon:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$01,$00
	db $02,$00,$01,$8E,$8E,$8E,$00,$00,$DC,$00,$00,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DB,$1C,$04,$F6,$00,$00,$00

//
// States for 100% Waterless routes - the last four stages.
//
state_100p_waterless_chameleon:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00
	db $02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$9B,$16,$04,$34,$00,$00,$00
state_100p_waterless_mandrill:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00
	db $03,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$9F,$18,$04,$3C,$00,$00,$00
state_100p_waterless_armadillo:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
	db $03,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$DC,$00,$00,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DF,$1A,$04,$7C,$00,$00,$00
state_100p_waterless_octopus:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$00
	db $03,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$1C,$04,$7E,$00,$00,$00

//
// States for 100% Iceless Chameleon 3rd
//
state_100p_cham3rd_chameleon:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$12,$04,$20,$00,$00,$00
state_100p_cham3rd_eagle:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$0C,$14,$04,$28,$00,$00,$00
state_100p_cham3rd_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $03,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$1D,$16,$04,$2C,$00,$00,$00

//
// Shared 100% states - when all routes merge after the 8 Mavericks.
//
state_100p_shared_penguin_revisit:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$40,$00,$01,$00
	db $02,$00,$01,$8E,$8E,$88,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DF,$1E,$10,$FE,$00,$00,$00
state_100p_shared_armadillo_revisit:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$40,$00,$01,$00
	db $03,$00,$01,$8E,$8E,$8E,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$DF,$20,$04,$FF,$00,$00,$00
state_100p_shared_sigma1_zero_intro:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$40,$00,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
state_100p_shared_sigma1_no_intro:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$C0,$00,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
state_100p_shared_sigma2:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
state_100p_shared_sigma3:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00
state_100p_shared_sigma4:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$C0,$03,$85,$00
	db $00,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$FF,$20,$04,$FF,$00,$00,$00


//
// States for Any% Mammoth 8th route.
//
state_anyp_m8th_mandrill:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m8th_armadillo:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m8th_octopus:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$00,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m8th_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00

//
// States for Any% Mammoth 7th route.
//
state_anyp_m7th_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$00,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m7th_octopus:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00

//
// States for Any% Mammoth 6th route.
//
state_anyp_m6th_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m6th_armadillo:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00

//
// States for Any% Mammoth 5th route.
//
state_anyp_m5th_mammoth:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_m5th_mandrill:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$DC,$00
	db $DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00


//
// Shared Any% states - before routes diverge.
//
state_anyp_shared_chameleon:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00
	db $02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_shared_eagle:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00

//
// Shared Any% states - when all routes merge after the 8 Mavericks.
//
state_anyp_shared_sigma1_zero_intro:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$40,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_shared_sigma1_no_intro:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$C0,$00,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$08,$10,$04,$00,$00,$00,$00
state_anyp_shared_sigma2:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$C0,$03,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$0A,$10,$04,$00,$00,$00,$00
state_anyp_shared_sigma3:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$C0,$03,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$0A,$10,$04,$00,$00,$00,$00
state_anyp_shared_sigma4:
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$C0,$03,$00,$00
	db $03,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00
	db $DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$0A,$10,$04,$00,$00,$00,$00

{warnpc $B00000}
// *** END OF BANK AF HACKS ***
