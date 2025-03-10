global post_estimate /Users/samueljames/Work/uni/rightmove/rightmove_data_rg2.dta
local fes fe_stc30 fe_stc60 fe_stc90 fe_l_p fe_e_p fe_r_p
local stc_fes fe_stc30 fe_stc60 fe_stc90
local stcs stc30 stc60 stc90
local price_fes fe_l_p fe_e_p
local text_clarity a_t_s t_t_s
local dominance d_o_y d_o_y_m d_p_y d_p_y_m
local listing_characteristics days_featured days_premium n_i n_i2 avg_r avg_r2 d_l d_l2 a_t_s p_l_s
local listing_characteristics_no_2 days_featured days_premium n_i avg_r d_l arpw nipw a_t_s p_l_s

use $post_estimate, replace

// Store labels to re-apply after collapsing.
// foreach v of var * {
// 	capture local l`v' : variable label `v'
// }
//
// collapse (mean) man_dist crow_dist size `fes' `property_characteristics' `listing_characteristics' stc30 a_t_s t_t_s e_p multi_office diamond reduced nipw x_* a_o agent_listings agents_per_property_postcode noal , by(agent_id property_listing_month property_listing_year)
//
// // Relabel
// foreach v of var * {
// 	label var `v' "`l`v''"
// }


// Table 2 regressions

eststo clear
foreach stc of varlist `stc_fes' {
	reghdfe e_p `stc', absorb(all_the_fes_pcode)
	eststo t2_`stc'
}

foreach stc of varlist `stcs' {
	foreach price of varlist `price_fes' {
		reghdfe `stc' `price', absorb(all_the_fes_pcode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_v_speed.tex", tex label replace noomitted p r2

eststo clear
foreach stc of varlist `stc_fes' {
	foreach price of varlist `price_fes' {
		reghdfe `price' `stc', absorb(all_the_fes_pcode)
		eststo t2_`stc'_`price'
	}
}

foreach stc of varlist `stc_fes' {
	foreach price of varlist `price_fes' {
		reghdfe `stc' `price', absorb(all_the_fes_pcode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_v_speed_fes.tex", tex label replace noomitted p r2

eststo clear
foreach iv of varlist `fes' {
	reghdfe diamond `iv', absorb()
	eststo t3_`iv'
}
esttab t3_* using "./tables/diamond.tex", tex label replace noomitted p r2

eststo clear 
foreach stc of varlist `stc_fes' {
	reghdfe reduced `stc', absorb()
	eststo t4_`stc'
}

esttab t4_* using "./tables/speed_v_reduced.tex", tex label replace noomitted p r2

eststo clear 
foreach text_var of varlist `text_clarity' {
	foreach fe of varlist `fes' {
		reghdfe `text_var' `fe', absorb()
		eststo t5_`text_var'_`fe'
	}
}

esttab t5_* using "./tables/text_clarity.tex", tex label replace noomitted p r2

eststo clear 
gen inv = cond(x_investment > 0.4, 1, 0)
gen condi_e_p = inv * fe_e_p
gen condi_stc = inv * fe_stc30
reghdfe e_p fe_e_p inv condi_e_p, absorb()
eststo inv_ep
reghdfe stc30 fe_e_p inv condi_e_p, absorb()
eststo inv_stc30
reghdfe e_p fe_stc30 inv condi_stc, absorb()
eststo inv_ep_2
reghdfe stc30 fe_stc30 inv condi_stc, absorb()
eststo inv_stc30_2
esttab inv_* using "./tables/investment.tex", tex label replace noomitted p r2


eststo clear 
gen condi2_e_p = multi_office * fe_e_p
gen condi2_stc = multi_office * fe_stc30
reghdfe e_p fe_e_p multi_office condi2_e_p, absorb()
eststo inv_ep
reghdfe stc30 fe_e_p multi_office condi2_e_p, absorb()
eststo inv_stc30
reghdfe e_p fe_stc30 multi_office condi2_stc, absorb()
eststo inv_ep_2
reghdfe stc30 fe_stc30 multi_office condi2_stc, absorb()
eststo inv_stc30_2
esttab inv_* using "./tables/large_agent.tex", tex label replace noomitted p r2

eststo clear
foreach iv of varlist `fes' {
	foreach dom of varlist `dominance' {
		reghdfe `dom' `iv', absorb()
		eststo t_`dom'_`iv'
	}
}
esttab t_* using "./tables/dominance.tex", tex label replace noomitted p r2

eststo clear
reghdfe e_p `listing_characteristics', absorb()
eststo t_1
reghdfe e_p `listing_characteristics', absorb(all_the_fes_pcode)
eststo t_2
reghdfe stc_price `listing_characteristics', absorb()
eststo t_3
reghdfe stc_price `listing_characteristics', absorb(all_the_fes_pcode)
eststo t_4
reghdfe time_to_stc `listing_characteristics', absorb()
eststo t_5
reghdfe time_to_stc `listing_characteristics', absorb(all_the_fes_pcode)
eststo t_6

esttab t_* using "./tables/agent_on_outcomes.tex", tex label replace noomitted p r2

// eststo clear 
// foreach iv of varlist `fes' {
// 	reghdfe delisted `iv', absorb()
// 	eststo t_`iv'
// }
// esttab t_* using "./tables/delisted.tex", tex label replace noomitted p r2
