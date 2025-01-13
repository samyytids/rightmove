global text_vars x_*
// ssc install mat2txt

use /Users/samueljames/Work/uni/rightmove/rightmove_data.dta, clear

rename x_planning_permission_pontential x_ppp

local i = 1
foreach var of varlist  $text_vars {
	di `i'
	gen q`var' = cond(`var' > 0.6, 1, 0, .)
	replace q`var' = . if `var' == .
	local i = `i' + 1
}
drop if _est_t1_stc60 == 0
capture drop cp_pct
xtile cp_pct = fe_ln_lp, nq(10)

gen good_agent = cond(cp_pct == 1, 1, 0)

local i = 1
foreach var of varlist $text_vars {
	di `var'
	ttest q`var', by(good_agent)
	matrix ttest = (r(p),r(mu_1),r(mu_2))
	matrix rownames ttest = `var'
	if `i' == 1 {
		matrix colnames ttest = "p-value"
	}
	local i = `i' + 1
	mat2txt, matrix(ttest) saving(ttest) append
}
