global obj_vars bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

global obj_vars_to_log bedrooms bathrooms average_distance

global obj_vars_school bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway deprivation overall_effectiveness effective_leadership quality_education personal_development behaviour early_years_provision sixth_form_provision

global agent_characteristics a_o a_p

global kernel_dvs stc30 ln_ep r_p

global stored_dvs fe_stc30 fe_ln_ep fe_r_p

global text_scores x_*

global text_dummies qx_*

global school_data deprivation overall_effectiveness effective_leadership personal_development quality_education behaviour early_years_provision sixth_form_provision

global agent_controlled_vars_to_ln days_featured days_premium avg_r d_l num_images num_kf

global agent_controlled_vars days_featured days_premium avg_r avg_r2 d_l d_l2 num_images n_i2 num_kf

global quality_measure avg_r avg_r2 d_l d_l2 num_images n_i2 num_kf p_l_s t_c_s

global competition_ivs agent_listings agents_per_agent_postcode n_o_a_l




use /Users/samueljames/Work/uni/rightmove/rightmove_data.dta, clear

foreach var of varlist $obj_vars_to_log {
	replace `var' = ln(`var')
}

eststo clear
foreach var of varlist $kernel_dvs {
	reghdfe `var' $obj_vars p_t p_s_t, absorb(agent_id all_the_fes_pcode, savefe) 
	rename __hdfe1__ fe_`var'
	eststo t1_`var'
}

label variable fe_stc30 "STC within 60 days (fe)"
// label variable fe_dom "Days on market (fe)"
label variable fe_ln_ep "Ln current price (fe)"
label variable fe_r_p "Price reduction (fe)"

esttab t1_* using "./tables/1.tex", tex label replace drop(p_t p_s_t ) p r2

eststo clear
foreach var of varlist $kernel_dvs {
	reghdfe `var' , absorb(agent_id property_outcode property_listing_month_year, savefe) 
	rename __hdfe1__ fe_`var'_no_c
	eststo t1_`var'
}
esttab t1_* using "./tables/1_no_c.tex", tex label replace  p r2

label variable fe_stc30_no_c "STC within 30 days (fe no controls)"
// label variable fe_dom_no_c "Days on market (fe no controls)"
label variable fe_ln_ep_no_c "Ln current price (fe no controls)"
label variable fe_r_p_no_c "Price reduction (fe no controls)"

foreach var of varlist $kernel_dvs {
	bysort agent_id (fe_`var'): replace fe_`var' = fe_`var'[1] if missing(fe_`var')
}

foreach var of varlist $stored_dvs {
	replace `var' = ln(`var')
}

foreach var of varlist $agent_controlled_vars_to_ln {
	replace `var' = ln(`var')
}

foreach var of varlist $competition_ivs {
	replace `var' = ln(`var')
}

gen d_l2 = d_l^2
gen avg_r2 = avg_r^2
gen n_i2 = num_images^2
gen n_i_p_w = num_images/d_l

// xtile cp_pct = fe_ln_ep, nq(10)
//
// gen good_agent = cond(cp_pct == 1, 1, 0)

save /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, replace

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, clear
replace days_featured = 1 if days_featured > 0
replace days_premium = 1 if days_premium > 0

// Save kdensity
// foreach var of varlist $kernel_dvs {
// 	quietly kdensity fe_`var'
// 	graph save "./graphs/`var'.gph", replace
// }


// Agent level regressions

// Store labels
foreach v of var * {
	capture local l`v' : variable label `v'
}

rename avg_res_per_word arpw

collapse (mean) n_i_p_w arpw man_dist crow_dist ctb size $text_dummies $stored_dvs p_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes agent_listings agents_per_agent_postcode agents_per_agent_outcode t_c_s n_o_a_l , by(agent_id property_listing_month property_listing_year)

// Relabel
foreach v of var * {
	label var `v' "`l`v''"
}

local fes_1
local fes_2 agent_postcode

eststo clear
foreach dv of varlist $stored_dvs {
	reghdfe `dv' $agent_controlled_vars p_l_s, absorb(a_o)
	eststo t2_`dv'_`i'
}
esttab t2_* using "./tables/2_text_class.tex", tex label replace noomitted p r2

eststo clear

foreach dep_var of varlist $quality_measure {
	eststo clear
	foreach fe_var of varlist $stored_dvs {
		reghdfe `dep_var' `fe_var', absorb(a_o) 
		eststo t3_`dep_var'_`fe_var'
	}
	esttab t3_* using "./tables/3_`dep_var'.tex", tex label replace  p r2
}

eststo clear

foreach dep_var of varlist days_premium days_featured arpw ctb size n_i_p_w {
	eststo clear 
	foreach fe_var of varlist $stored_dvs {
		reghdfe `dep_var' `fe_var', absorb(a_o) 
		eststo t3_`dep_var'_`fe_var'
	}
	esttab t3_* using "./tables/3_1_`dep_var'.tex", tex label replace p r2
}

eststo clear
local counter = 0
foreach ind_var of varlist $competition_ivs {
	eststo clear
	foreach dep_var of varlist $stored_dvs {
		reghdfe `dep_var' `ind_var', absorb(a_o)
		eststo t4_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t4_* using "./tables/4_`ind_var'.tex", tex label replace p r2
}

eststo clear
local counter = 0
foreach dep_var of varlist $stored_dvs {
	reghdfe `dep_var' $competition_ivs, absorb(a_o)
	eststo t4_`dep_var'_`counter'
	local counter = `counter' + 1
}
esttab t4_* using "./tables/4_all_comp.tex", tex label replace p r2

foreach dep_var of varlist qx_garden qx_garage qx_off_street_parking qx_driveway qx_closeness qx_freehold qx_detached man_dist crow_dist {
	eststo clear
	foreach ind_var of varlist $stored_dvs {
		reghdfe `dep_var' `ind_var', absorb(a_o)
		eststo t5_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t5_* using "./tables/5_`dep_var'.tex", tex label replace p r2
}

eststo clear





























