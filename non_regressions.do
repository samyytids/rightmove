global post_estimate /Users/samueljames/Work/uni/rightmove/rightmove_data_rg2.dta

pctile e_p_p = fe_e_p, nquantiles(11)
pctile stc30_p = fe_stc30, nquantiles(11)
pctile stc60_p = fe_stc60, nquantiles(11)
pctile stc90_p = fe_stc90, nquantiles(11)
pctile l_p_p = fe_l_p, nquantiles(11)
pctile stc_price_p = fe_stc_price, nquantiles(11)

gen top_fe_e_p = cond(fe_e_p > e_p_p[10], 1, 0)
gen bottom_fe_e_p = cond(fe_e_p < e_p_p[1], 1, 0)

gen top_fe_l_p = cond(fe_l_p > l_p_p[10], 1, 0)
gen bottom_fe_l_p = cond(fe_l_p < l_p_p[1], 1, 0)

gen top_fe_stc30 = cond(fe_stc30 > stc30_p[10], 1, 0)
gen bottom_fe_stc30 = cond(fe_stc30 < stc30_p[1], 1, 0)

gen top_fe_stc90 = cond(fe_stc90 > stc90_p[10], 1, 0)
gen bottom_fe_stc90 = cond(fe_stc90 < stc90_p[1], 1, 0)

gen top_fe_stc60 = cond(fe_stc60 > stc60_p[10], 1, 0)
gen bottom_fe_stc60 = cond(fe_stc60 < stc60_p[1], 1, 0)

gen top_fe_stc_price = cond(fe_stc_price > stc_price_p[10], 1, 0)
gen bottom_fe_stc_price = cond(fe_stc_price < stc_price_p[1], 1, 0)
