global base_data /Users/samueljames/Work/uni/rightmove/rightmove_data_rg.dta
global post_estimate /Users/samueljames/Work/uni/rightmove/rightmove_data_rg2.dta

local property_characteristics bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

local t1_dvs stc30 stc60 stc90 l_p e_p r_p
 
// local fes gd_stc30 gd_e_p gd_r_p bd_stc30 bd_e_p bd_r_p

local fes fe_stc30 fe_stc60 stc90 fe_l_p fe_e_p fe_r_p

local listing_characteristics days_featured days_premium n_i n_i2 avg_r avg_r2 d_l d_l2 num_kf p_l_s

local listing_characteristics_no_2 days_featured days_premium n_i avg_r d_l arpw nipw num_kf p_l_s


local competition agent_listings agents_per_property_postcode noal

use $base_data, clear

// Table 1 regressions

eststo clear
foreach var of varlist `t1_dvs' {
	reghdfe `var' `property_characteristics' p_t p_s_t, absorb(agent_id all_the_fes_pcode, savefe) 
	rename __hdfe1__ fe_`var'
	eststo t1_`var'
}

// gen gd_stc30 = fe_stc30 + 0.0001 if fe_stc30 > 0
// gen gd_e_p = fe_e_p + 0.0001 if fe_e_p > 0
//
// gen bd_r_p = fe_r_p + 0.0001 if fe_r_p > 0
//
// gen bd_stc30 = -fe_stc30 - 0.0001 if fe_stc30 < 0
// gen bd_e_p = -fe_e_p  - 0.0001 if fe_e_p < 0
//
// gen gd_r_p = -fe_r_p  - 0.0001 if fe_r_p < 0

// label variable gd_stc30 "STC 30 (FE) good"
// label variable gd_e_p "Ln  price (FE) good"
// label variable gd_r_p "Ln price reduction (FE) good"
// label variable bd_stc30 "STC 30 (FE) bad"
// label variable bd_e_p "Ln  price (FE) bad"
// label variable bd_r_p "Ln price reduction (FE) bad"

capture label variable fe_e_p "Initial price (FE)"
capture label variable fe_l_p "Current price (FE)"
capture label variable fe_stc30 "STC 30 (FE)"
capture label variable fe_stc60 "STC 60 (FE)"
capture label variable fe_stc90 "STC 90 (FE)"
label variable fe_r_p "Reduced percentage (FE)"

esttab t1_* using "./tables/1_FE.tex", tex label replace drop(p_t p_s_t) p r2

foreach var of varlist `fes' {
	su `var', meanonly
	if r(min) < 0 {
		replace `var'  = `var' - r(min)
		replace `var' = `var' + 0.0001
	}
	else {
		replace `var'  = `var' + r(min)
		replace `var' = `var' + 0.0001
	}
	
	replace `var' = ln(`var')
}

// foreach var of varlist `fes' {
// 	replace `var' = ln(`var')
// }

save $post_estimate, replace
use $post_estimate, replace

// Store labels to re-apply after collapsing.
foreach v of var * {
	capture local l`v' : variable label `v'
}

collapse (mean) man_dist crow_dist size `fes' `property_characteristics' `listing_characteristics' arpw nipw x_* a_o agent_listings agents_per_property_postcode noal , by(agent_id property_listing_month property_listing_year)


// Relabel
foreach v of var * {
	label var `v' "`l`v''"
}


// Table 2 regressions

eststo clear
foreach dv of varlist `fes' {
	reghdfe `dv' `listing_characteristics', absorb()
	eststo t2_`dv'_`i'
}
esttab t2_* using "./tables/2_LF_FE.tex", tex label replace noomitted p r2


foreach dep_var of varlist `listing_characteristics_no_2' {
	eststo clear
	foreach fe_var of varlist `fes' {
		reghdfe `dep_var' `fe_var', absorb() 
		eststo t3_`dep_var'_`fe_var'
	}
	esttab t3_* using "./tables/3_FE_`dep_var'.tex", tex label replace  p r2
}

eststo clear


// Table 3 Competition vars
local counter = 0
foreach ind_var of varlist `competition' {
	eststo clear
	foreach dep_var of varlist `fes' {
		reghdfe `dep_var' `ind_var', absorb()
		eststo t4_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t4_* using "./tables/4_FE_`ind_var'.tex", tex label replace p r2
}

eststo clear
local counter = 0
foreach dep_var of varlist `fes' {
	reghdfe `dep_var' `competition', absorb()
	eststo t4_`dep_var'_`counter'
	local counter = `counter' + 1
}
esttab t4_* using "./tables/4_FE_all_comp.tex", tex label replace p r2









