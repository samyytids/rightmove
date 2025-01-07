global obj_vars bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

global obj_vars_no_type bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

global obj_vars_p_level bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway p_t p_s_t deprivation overall_effectiveness effective_leadership quality_education personal_development behaviour early_years_provision sixth_form_provision

global kernel_dvs stc60 dom ln_ep ln_lp

global stored_dvs fe_stc60 fe_dom fe_ln_ep fe_ln_lp

global text_scores x_*

global agent_controlled_vars days_featured days_premium avg_r avg_r2 d_l d_l2 num_images n_i2 hkf
global agent_controlled_vars_no_hkf days_featured days_premium avg_r avg_r2 d_l d_l2 num_images n_i2 

global agent_characteristics a_o a_p

global positive_attrs x_closeness x_shops x_cafe x_pub x_restaurant x_cinema x_amenities x_popular_location x_school x_coastal x_other_water_location x_woodland x_garage x_freehold x_driveway x_off_street_parking x_chain_free x_glazing x_high_ceiling x_south_facing x_south_west_facing x_south_east_facing x_gch x_underfloor_heating

global quality_measure avg_r d_l hkf p_l_s t_c_s

global agent_ivs agent_listings agents_per_agent_outcode agents_per_agent_postcode n_o_a_l

global property_type z_*
global property_sub_type q_*

use /Users/samueljames/Work/uni/rightmove/rightmove_data.dta, clear

foreach var of varlist $obj_vars_no_type {
	replace `var' = ln(`var') if `var' != 0
}

eststo clear
foreach var of varlist $kernel_dvs {
	reghdfe `var' $obj_vars $property_type $property_sub_type if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(agent_id property_postcode property_listing_year property_listing_month, savefe) 
	rename __hdfe1__ fe_`var'
	eststo t1_`var'
}

label variable fe_stc60 "STC within 60 days (fe)"
label variable fe_dom "Days on market (fe)"
label variable fe_ln_ep "Ln initial price (fe)"
label variable fe_ln_lp "Ln current price (fe)"

esttab t1_* using "./tables/1.tex", tex label replace drop($property_type $property_sub_type )

eststo clear
foreach var of varlist $kernel_dvs {
	reghdfe `var' if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(agent_id property_postcode property_listing_year property_listing_month, savefe) 
	rename __hdfe1__ fe_`var'_no_c
	eststo t1_`var'
}
esttab t1_* using "./tables/1_no_c.tex", tex label replace

label variable fe_stc60_no_c "STC within 60 days (fe no controls)"
label variable fe_dom_no_c "Days on market (fe no controls)"
label variable fe_ln_ep_no_c "Ln initial price (fe no controls)"
label variable fe_ln_lp_no_c "Ln current price (fe no controls)"

foreach var of varlist $kernel_dvs {
	bysort agent_id (fe_`var'): replace fe_`var' = fe_`var'[1] if missing(fe_`var')
}

foreach var of varlist $stored_dvs {
	replace `var' = ln(`var')
}

foreach var of varlist $agent_controlled_vars_no_hkf {
	replace `var' = ln(`var')
}

foreach var of varlist $agent_ivs {
	replace `var' = ln(`var')
}


save /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, replace

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, clear

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
collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes agent_listings agents_per_agent_postcode agents_per_agent_outcode t_c_s n_o_a_l if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, by(agent_id property_listing_month property_listing_year)

// Relabel
foreach v of var * {
	label var `v' "`l`v''"
}


local fes_1
local fes_2 agent_postcode

forvalues i = 1/2 {
	foreach dv of varlist $stored_dvs {
		if `i' == 1 {
			reghdfe `dv' $agent_controlled_vars p_l_s, absorb()
		}
		else {
			reghdfe `dv' $agent_controlled_vars p_l_s, absorb(a_p)
		}
		
		eststo t2_`dv'_`i'
	}
}
esttab t2_* using "./tables/2_text_class.tex", tex label replace noomitted

eststo clear

foreach dep_var of varlist $quality_measure {
	eststo clear
	foreach fe_var of varlist $stored_dvs {
		reghdfe `dep_var' `fe_var', absorb(a_p) 
		eststo t3_`dep_var'_`fe_var'
	}
	esttab t3_* using "./tables/3_`dep_var'.tex", tex label replace
}

eststo clear

foreach dep_var of varlist days_premium days_featured {
	eststo clear 
	foreach fe_var of varlist $stored_dvs {
		reghdfe `dep_var' `fe_var', absorb(a_p) 
		eststo t3_`dep_var'_`fe_var'
	}
	esttab t3_* using "./tables/3_1_`dep_var'.tex", tex label replace
}

eststo clear
local counter = 0
foreach ind_var of varlist $agent_ivs {
	eststo clear
	foreach dep_var of varlist $stored_dvs {
		reghdfe `dep_var' `ind_var', absorb()
		eststo t4_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t4_* using "./tables/4_`ind_var'.tex", tex label replace
}

eststo clear
local counter = 0
foreach dep_var of varlist $stored_dvs {
	reghdfe `dep_var' $agent_ivs, absorb()
	eststo t4_`dep_var'_`counter'
	local counter = `counter' + 1
}
esttab t4_* using "./tables/4_all_comp.tex", tex label replace

local counter = 0
foreach dep_var of varlist x_garden x_garage x_off_street_parking x_driveway x_closeness x_freehold x_detached {
	eststo clear
	foreach ind_var of varlist $stored_dvs {
		reghdfe `dep_var' `ind_var', absorb(a_p)
		eststo t5_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t5_* using "./tables/5_`dep_var'.tex", tex label replace
}

eststo clear





























