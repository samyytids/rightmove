global post_estimate /Users/samueljames/Work/uni/rightmove/rightmove_data_rg2.dta
local fes fe_stc30 fe_stc60 fe_stc90 fe_l_p fe_e_p fe_stc_price fe_r_p
local stc_fes fe_stc30 fe_stc60 fe_stc90
local stcs stc30 stc60 stc90
local price_fes fe_l_p fe_e_p fe_stc_price
local text_clarity a_t_s t_t_s
local dominance d_o_y d_o_y_m d_p_y d_p_y_m
local listing_characteristics days_featured days_premium n_i n_i2 avg_r avg_r2 d_l d_l2 a_t_s p_l_s
local listing_characteristics_no_2 days_featured days_premium n_i avg_r d_l arpw nipw a_t_s p_l_s

do regressions.do

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
	reghdfe e_p `stc', absorb(all_the_fes_ocode)
	eststo t2_`stc'
	reghdfe l_p `stc', absorb(all_the_fes_ocode)
	eststo t2_`stc'_2
}
esttab t2_* using "./tables/speed_fe_v_price.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)
eststo clear

foreach stc of varlist `stcs' {
	foreach price of varlist `price_fes' {
		reghdfe `stc' `price', absorb(all_the_fes_ocode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_fe_v_speed.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)
eststo clear


eststo clear
foreach stc of varlist `stc_fes' {
	foreach price of varlist `price_fes' {
		reghdfe `price' `stc', absorb(all_the_fes_ocode)
		eststo t2_`stc'_`price'
	}
}
esttab t2_* using "./tables/speed_fe_v_price_fe.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach price of varlist `price_fes' {
	foreach stc of varlist `stc_fes' {
		reghdfe `stc' `price', absorb(all_the_fes_ocode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_fe_v_speed_fe.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach iv of varlist `fes' {
	reghdfe diamond `iv', absorb(all_the_fes_ocode)
	eststo t3_`iv'
}
esttab t3_* using "./tables/diamond.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear 
foreach stc of varlist `stc_fes' {
	reghdfe reduced `stc', absorb(all_the_fes_ocode)
	eststo t4_`stc'
}

esttab t4_* using "./tables/speed_v_reduced.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear 
foreach text_var of varlist `text_clarity' {
	foreach fe of varlist `fes' {
		reghdfe `text_var' `fe', absorb(all_the_fes_ocode)
		eststo t5_`text_var'_`fe'
	}
}

esttab t5_* using "./tables/text_clarity.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear 
gen inv = cond(x_investment > 0.4, 1, 0)
gen condi_e_p = inv * fe_e_p
gen condi_stc = inv * fe_stc30
reghdfe e_p fe_e_p inv condi_e_p, absorb(all_the_fes_ocode)
eststo inv_ep
reghdfe stc30 fe_e_p inv condi_e_p, absorb(all_the_fes_ocode)
eststo inv_stc30
reghdfe e_p fe_stc30 inv condi_stc, absorb(all_the_fes_ocode)
eststo inv_ep_2
reghdfe stc30 fe_stc30 inv condi_stc, absorb(all_the_fes_ocode)
eststo inv_stc30_2
esttab inv_* using "./tables/investment.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)


eststo clear 
gen condi2_e_p = multi_office * fe_e_p
gen condi2_stc = multi_office * fe_stc30
reghdfe e_p fe_e_p multi_office condi2_e_p, absorb(all_the_fes_ocode)
eststo inv_ep
reghdfe stc30 fe_e_p multi_office condi2_e_p, absorb(all_the_fes_ocode)
eststo inv_stc30
reghdfe e_p fe_stc30 multi_office condi2_stc, absorb(all_the_fes_ocode)
eststo inv_ep_2
reghdfe stc30 fe_stc30 multi_office condi2_stc, absorb(all_the_fes_ocode)
eststo inv_stc30_2
esttab inv_* using "./tables/large_agent.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear 
gen condi3_e_p = developer * fe_e_p
gen condi3_stc = developer * fe_stc30
reghdfe e_p fe_e_p developer condi3_e_p, absorb(all_the_fes_ocode)
eststo inv_ep
reghdfe stc30 fe_e_p developer condi3_e_p, absorb(all_the_fes_ocode)
eststo inv_stc30
reghdfe e_p fe_stc30 developer condi3_stc, absorb(all_the_fes_ocode)
eststo inv_ep_2
reghdfe stc30 fe_stc30 developer condi3_stc, absorb(all_the_fes_ocode)
eststo inv_stc30_2
esttab inv_* using "./tables/developer.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach iv of varlist `fes' {
	foreach dom of varlist `dominance' {
		reghdfe `dom' `iv', absorb()
		eststo t_`dom'_`iv'
	}
}
esttab t_* using "./tables/dominance.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
reghdfe stc_pr `listing_characteristics', absorb()
eststo t_1
reghdfe e_p `listing_characteristics', absorb(all_the_fes_ocode)
eststo t_2
reghdfe stc_price `listing_characteristics', absorb()
eststo t_3
reghdfe stc_price `listing_characteristics', absorb(all_the_fes_ocode)
eststo t_4
reghdfe time_to_stc `listing_characteristics', absorb()
eststo t_5
reghdfe time_to_stc `listing_characteristics', absorb(all_the_fes_ocode)
eststo t_6
// reghdfe reduced `listing_characteristics', absorb()
// eststo t_7
// reghdfe reduced `listing_characteristics', absorb(all_the_fes_ocode)
// eststo t_8
// reghdfe r_p `listing_characteristics', absorb()
// eststo t_9
// reghdfe r_p `listing_characteristics', absorb(all_the_fes_ocode)
// eststo t_10

esttab t_* using "./tables/agent_on_outcomes.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

do non_regressions.do

eststo clear
foreach stc of varlist `stc_fes' {
	reghdfe e_p `stc' if top_`stc' == 1, absorb(all_the_fes_ocode) 
	eststo t2_`stc'
	reghdfe l_p `stc' if top_`stc' == 1, absorb(all_the_fes_ocode)
	eststo t2_`stc'_2
}
esttab t2_* using "./tables/speed_fe_v_price_top.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach stc of varlist `stc_fes' {
	reghdfe e_p `stc' if bottom_`stc' == 1, absorb(all_the_fes_ocode)
	eststo t2_`stc'
	reghdfe l_p `stc' if bottom_`stc' == 1, absorb(all_the_fes_ocode)
	eststo t2_`stc'_2
}
esttab t2_* using "./tables/speed_fe_v_price_bottom.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach stc of varlist `stc_fes' {
	foreach price of varlist `price_fes' {
		reghdfe `price' `stc'  if top_`stc' == 1, absorb(all_the_fes_ocode)
		eststo t2_`stc'_`price'
	}
}
esttab t2_* using "./tables/speed_fe_v_price_fe_top.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach price of varlist `price_fes' {
	foreach stc of varlist `stc_fes' {
		reghdfe `stc' `price'  if top_`stc' == 1, absorb(all_the_fes_ocode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_fe_v_speed_fe_top.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach stc of varlist `stc_fes' {
	foreach price of varlist `price_fes' {
		reghdfe `price' `stc'  if bottom_`stc' == 1, absorb(all_the_fes_ocode)
		eststo t2_`stc'_`price'
	}
}
esttab t2_* using "./tables/speed_fe_v_price_fe_bottom.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

eststo clear
foreach price of varlist `price_fes' {
	foreach stc of varlist `stc_fes' {
		reghdfe `stc' `price'  if bottom_`stc' == 1, absorb(all_the_fes_ocode)
		eststo t2_`price'_`stc'
	}
}
esttab t2_* using "./tables/price_fe_v_speed_fe_bottom.tex", tex label replace r2 noomitted star(* 0.10 ** 0.05 *** 0.01) t(2)

// eststo clear 
// foreach iv of varlist `fes' {
// 	reghdfe delisted `iv', absorb()
// 	eststo t_`iv'
// }
// esttab t_* using "./tables/delisted.tex", tex label replace noomitted p r2
