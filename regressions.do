global base_data /Users/samueljames/Work/uni/rightmove/rightmove_data_rg.dta
global post_estimate /Users/samueljames/Work/uni/rightmove/rightmove_data_rg2.dta
global pre_ln /Users/samueljames/Work/uni/rightmove/rightmove_data_pre_ln.dta

local property_characteristics bedrooms bathrooms average_distance pr_* /* prs_* qx_amenities qx_woodland qx_coastal qx_cul_de_sac qx_balcony qx_views qx_detached qx_semi_detached qx_terraced qx_high_ceiling qx_carpeted qx_garage qx_garden qx_gated qx_beam qx_bay_windows qx_fireplace qx_south_facing qx_gch qx_investment qx_first_time_buyer qx_extended qx_refurbished qx_conversion qx_modernised qx_new_build qx_open_plan qx_quiet qx_btl woodland_view coastal_view water_view qx_garden qx_balcony qx_bay_windows qx_carpeted qx_wood_flooring qx_south_facing num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway x_* size ctb */

local t1_dvs stc30 stc60 stc90 l_p e_p r_p stc_price

local fes fe_stc30 fe_stc60 fe_stc90 fe_l_p fe_e_p fe_stc_price fe_r_p

local listing_characteristics featured premium n_i n_i2 d_l d_l2

local listing_characteristics_no_2 featured premium n_i d_l nipw t_t_s


local competition agent_listings agents_per_property_postcode noal agent_listings2

use $base_data, clear

// Table 1 regressions

eststo clear
foreach var of varlist `t1_dvs' {
	reghdfe `var' `property_characteristics', absorb(agent_id all_the_fes_pcode, savefe) 
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
capture label variable fe_stc_price "STC price (FE)"
label variable fe_r_p "Reduced percentage (FE)"

esttab t1_* using "./tables/1_FE.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

save $pre_ln, replace

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

collapse (mean) man_dist crow_dist `fes' l_p stc90 `property_characteristics' `listing_characteristics' t_t_s arpw nipw a_o agent_listings agents_per_property_postcode noal, by(agent_id)


// Relabel
foreach v of var * {
	label var `v' "`l`v''"
}


// Table 2 regressions

eststo clear
local c = 0
foreach dv of varlist `fes' {
	if `c' <= 2 {
		reghdfe `dv' fe_l_p `listing_characteristics', absorb()
	}
	else {
		reghdfe `dv' fe_stc90 `listing_characteristics', absorb()
	}
	local c = `c' + 1
	eststo t2_`dv'_`i'
}
esttab t2_* using "./tables/2_LF_FE.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2) beta(2)

local c = 0
foreach dep_var of varlist `listing_characteristics_no_2' {
	eststo clear
	foreach fe_var of varlist `fes' {
		if `c' <= 2 {
			reghdfe `dep_var' `fe_var', absorb() 
		} 
		else {
			reghdfe `dep_var' fe_stc30 `fe_var', absorb() 
		}
		eststo t3_`dep_var'_`fe_var'
		local c = `c' + 1
	}
	local c = 0
	esttab t3_* using "./tables/3_FE_`dep_var'.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)
}

eststo clear
gen agent_listings2 = agent_listings * agent_listings

// Table 3 Competition vars
local counter = 0
foreach ind_var of varlist `competition' {
	eststo clear
	foreach dep_var of varlist `fes' {
		reghdfe `dep_var' `ind_var', absorb()
		eststo t4_`dep_var'_`counter'
		local counter = `counter' + 1
	}
	esttab t4_* using "./tables/4_FE_`ind_var'.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)
}

eststo clear
local counter = 0
foreach dep_var of varlist `fes' {
	reghdfe `dep_var' `competition', absorb()
	eststo t4_`dep_var'_`counter'
	local counter = `counter' + 1
}
esttab t4_* using "./tables/4_FE_all_comp.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)









