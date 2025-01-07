global obj_vars bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

global obj_vars_no_bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway
 
global obj_vars_p_level bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway p_t p_s_t deprivation overall_effectiveness effective_leadership quality_education personal_development behaviour early_years_provision sixth_form_provision
 
global kernel_dvs stc30 stc60 dom ln_ep ln_lp r_p

global stored_dvs fe_stc30 fe_stc60 fe_dom fe_ln_ep fe_ln_lp fe_r_p

global text_scores closeness bus motorway train tube shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location pets woodland cul_de_sac original_features annex studio cottage bungalow townhouse house terraced mid_terrace end_terrace mews apartment flat barn duplex maisonette penthouse balcony juliette_balcony bedroom living_room sitting_room dining_room kitchen utility_room bathroom shower lounge parlour pantry billiard_room loft cellar cloakroom reception office study snug library conservatory playroom nursery_room garage workshop terrace roof wardrobe en_suite white_goods period_features views leasehold freehold detached semi_detached link_detached council_tax epc driveway off_street_parking summer_house fixtures_and_fittings chain_free glazing wood stone high_ceiling hall gym thatched carpeted tiled wood_flooring laminated_flooring porch gated beam bay_windows bow_window sash_window decking mezzanine breakfast_island garden sqft acreage patio nhbc town city village hamlet courtyard french_doors bifold_doors south_facing north_facing west_facing east_facing north_west_facing north_east_facing south_west_facing south_east_facing gch fireplace radiator swimming_pool hot_tub fitted has_tenant maintenance_charge service_charge underfloor_heating solar ev_charging ground_floor vaulted_ceiling restored remodelled refurbished modernised converted refitted extended restoration refurbishment modernisation extendable new_build well_appointed ready_to_move_in conversion private big potential planning_permission_granted planning_permission_pontential bright family home property_reference_number modern open_plan victorian georgian edwardian elizabethan viewing_recommended communal luxury investment first_time_buyer interior_design low_maintenance quiet landscaped separate cosy characterful first_time_to_market wrap_around rural urban secure listed beautiful storage btl front developer_implied rear award_winning architect brick

global agent_controlled_vars days_featured days_premium avg_r avg_r2 d_l d_l2 num_images n_i2 hkf

global agent_characteristics agent_outcode agent_postcode

global positive_attrs closeness shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location woodland garage freehold driveway off_street_parking chain_free glazing high_ceiling south_facing south_west_facing south_east_facing gch underfloor_heating

global quality_measure avg_r d_l hkf 

use /Users/samueljames/Work/uni/rightmove/rightmove_data.dta, clear

eststo clear
// Regressions additive FEs
foreach var of varlist $kernel_dvs {
	reghdfe `var' $obj_vars if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(agent_id property_postcode property_listing_year property_listing_month, savefe) 
	rename __hdfe1__ fe_`var'
	
	eststo t1_`var'
}
esttab t1_* using "./tables/1.tex", tex label replace

// Repopulating all values for agent so we don't get tonnes of missing issues in later stuff. (redropped later if issue would be caused).
foreach var of varlist $kernel_dvs {
	bysort agent_id (fe_`var'): replace fe_`var' = fe_`var'[1] if missing(fe_`var')
}

save /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, replace

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear

// Save kdensity
foreach var of varlist $kernel_dvs {
	quietly kdensity fe_`var'
	graph save "./graphs/`var'.gph", replace
}


// agent level regressions (table 1)
collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, by(agent_id)

save /Users/samueljames/Work/uni/rightmove/rightmove_data_agent_level_v1.dta, replace

use /Users/samueljames/Work/uni/rightmove/rightmove_data_agent_level_v1.dta, clear
rename agent_outcode a_o
rename agent_postcode a_p

eststo clear
// Only objective and basic agent controlled stuff
foreach var of varlist $stored_dvs {	
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist a_o a_p {
			reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`fe')
			eststo t2_`var'_`similarity'_`fe'
		}
	}
}

esttab t2_* using "./tables/2_no_text_class_`var'.tex", tex label replace


eststo clear
// With text information 
foreach var of varlist $stored_dvs {
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist a_o a_p {
			reghdfe `var' $obj_vars $agent_controlled_vars `similarity' $positive_attrs, absorb(`fe')
			eststo t2_`var'_`similarity'_`fe'
		}
	}
}
esttab t2_* using "./tables/2_text_class_`var'.tex", tex label replace


// Property level (table 2
 
local p_fe_1 property_postcode
local p_fe_2 property_postcode property_listing_year
local p_fe_3 property_postcode property_listing_year property_listing_month 

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
foreach dep_var of varlist $quality_measure {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
			eststo t3_`dep_var'_`fe_var'_`i'
		}
	}
	  esttab t3_* using "./tables/3_`dep_var'.tex", tex label replace
}


// Determinants of agent quality (table 3)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

egen agent_listings = count(property_id), by(agent_id)
egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 
eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/4_agent_postcode_`var'.tex", tex label replace
}



eststo clear
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/4_property_postcode_`var'.tex", tex label replace
}



// Good houses get good agents (table 4)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
rename popular_location pop_loc
eststo clear
foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
			eststo t5_`var'_`fe_var'_`i'
		}
		esttab t5_* using "./tables/4_`var'_`fe_var'.tex", tex label replace
	}
}

/*
TODO:

Add more of the neighbourhood characteristics, like the school data I have. 
Crime data?
Reduced amount/percentage as dv


*/











// rent

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear

// agent level regressions (table 1)
collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, by(agent_id)


// Only objective and basic agent controlled stuff
foreach var of varlist $stored_dvs {
	eststo clear
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist agent_outcode agent_postcode {
			reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
			eststo t2_`var'
		}
		
		
	}
	esttab t2_* using "./tables/robust/rent/2_no_text_class_`var'.tex", tex label replace
}



// With text information 
foreach var of varlist $stored_dvs {
	eststo clear
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist agent_outcode agent_postcode {
			reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
			eststo t2_`var'
		}
	}
	esttab t2_* using "./tables/robust/rent/2_text_class_`var'.tex", tex label replace
}



// Property level (table 2)
local p_fe_1 property_postcode
local p_fe_2 property_postcode property_listing_year
local p_fe_3 property_postcode property_listing_year property_listing_month 
local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
 

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
foreach dep_var of varlist $quality_measure {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
			eststo t3_`dep_var'_`fe_var'_`i'
		}
	}
	esttab t3_* using "./tables/robust/rent/3_`dep_var'.tex", tex label replace
}



// Determinants of agent quality (table 3)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

egen agent_listings = count(property_id), by(agent_id)
egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		 
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/robust/rent/4_agent_postcode_`var'.tex", tex label replace
}



eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		 
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/robust/rent/4_property_postcode_`var'.tex", tex label replace
}



// Good houses get good agents (table 4)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
rename popular_location pop_loc
eststo clear
 
foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
			 
			eststo t5_`var'_`fe_var'_`i'
		}
		esttab t5_* using "./tables/robust/rent/4_`var'_`fe_var'.tex", tex label replace
	}
}












// comm

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear

// agent level regressions (table 1)
collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 0 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, by(agent_id)

// Only objective and basic agent controlled stuff
foreach var of varlist $stored_dvs {
	eststo clear
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist agent_outcode agent_postcode {
			reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
			eststo t2_`var'
		}
		
		
	}
	esttab t2_* using "./tables/robust/comm/2_no_text_class_`var'.tex", tex label replace
}



// With text information 
foreach var of varlist $stored_dvs {
	eststo clear
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist agent_outcode agent_postcode {
			reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
			eststo t2_`var'
		}
	}
	esttab t2_* using "./tables/robust/comm/2_text_class_`var'.tex", tex label replace
}



// Property level (table 2)
local p_fe_1 property_postcode
local p_fe_2 property_postcode property_listing_year
local p_fe_3 property_postcode property_listing_year property_listing_month 
local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
 

use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
foreach dep_var of varlist $quality_measure {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 0 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
			eststo t3_`dep_var'_`fe_var'_`i'
			 
		}
	}
	esttab t3_* using "./tables/robust/comm/3_`dep_var'.tex", tex label replace
	
}



// Determinants of agent quality (table 3)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

egen agent_listings = count(property_id), by(agent_id)
egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 0 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		 
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/robust/comm/4_agent_postcode_`var'.tex", tex label replace
}



eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 1/3 {
		reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 0 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		 
		eststo t4_`var'_`i'
		
	}
	esttab t4_* using "./tables/robust/comm/4_property_postcode_`var'.tex", tex label replace
}



// Good houses get good agents (table 4)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
rename popular_location pop_loc
eststo clear
 
foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 0 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
			 
			eststo t5_`var'_`fe_var'_`i'
		}
		esttab t5_* using "./tables/robust/comm/4_`var'_`fe_var'.tex", tex label replace
	}
}













// purple

// agent level regressions (table 1)
forvalues pb = 0/1 {
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear
	collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & is_pb == `pb', by(agent_id)

	// Only objective and basic agent controlled stuff
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
				eststo t2_`var'
			}


		}
		esttab t2_* using "./tables/robust/purple/2_no_text_class_`var'_`pb'.tex", tex label replace
	}



	// With text information 
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
				eststo t2_`var'
			}
		}
		esttab t2_* using "./tables/robust/purple/2_text_class_`var'_`pb'.tex", tex label replace
	}



	// Property level (table 2)
	local p_fe_1 property_postcode
	local p_fe_2 property_postcode property_listing_year
	local p_fe_3 property_postcode property_listing_year property_listing_month 
	local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
	 

	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	foreach dep_var of varlist $quality_measure {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & is_pb == `pb', absorb(`p_fe_`i'') 
				eststo t3_`dep_var'_`fe_var'_`i'
				 
			}
		}
		esttab t3_* using "./tables/robust/purple/3_`dep_var'_`pb'.tex", tex label replace

	}



	// Determinants of agent quality (table 3)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

	egen agent_listings = count(property_id), by(agent_id)
	egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
	egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & is_pb == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'

		}
		esttab t4_* using "./tables/robust/purple/4_agent_postcode_`var'_`pb'.tex", tex label replace
	}



	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & is_pb == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'

		}
		esttab t4_* using "./tables/robust/purple/4_property_postcode_`var'_`pb'.tex", tex label replace
	}



	// Good houses get good agents (table 4)
	di 1
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	di 2
	capture rename popular_location pop_loc
	di 3
	eststo clear
	di 4
	foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
		di 5
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			di 6
			forvalues i = 1/3 {
				di 7
				reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & is_pb == `pb', absorb(`p_fe_`i'')
				 di 8
				eststo t5_`var'_`fe_var'_`i'
				di 9
			}
			di 10
			esttab t5_* using "./tables/robust/purple/4_`var'_`fe_var'_`pb'.tex", tex label replace
			di 11
		}
	}
}








// developer

// agent level regressions (table 1)
forvalues pb = 0/1 {
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear
	collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & developer == `pb', by(agent_id)

	// Only objective and basic agent controlled stuff
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
				eststo t2_`var'
			}
		}
		esttab t2_* using "./tables/robust/developer/2_no_text_class_`var'_`pb'.tex", tex label replace
	}



	// With text information 
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				
				reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
				eststo t2_`var'
			}
		}
		esttab t2_* using "./tables/robust/developer/2_text_class_`var'_`pb'.tex", tex label replace
	}



	// Property level (table 2)
	local p_fe_1 property_postcode
	local p_fe_2 property_postcode property_listing_year
	local p_fe_3 property_postcode property_listing_year property_listing_month 
	local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
	 

	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	foreach dep_var of varlist $quality_measure {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & developer == `pb', absorb(`p_fe_`i'') 
				eststo t3_`dep_var'_`fe_var'_`i'
			}
		}
		esttab t3_* using "./tables/robust/developer/3_`dep_var'_`pb'.tex", tex label replace
	}



	// Determinants of agent quality (table 3)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

	egen agent_listings = count(property_id), by(agent_id)
	egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
	egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & developer == `pb', absorb(`p_fe_`i'')
			eststo t4_`var'_`i'
		}
		esttab t4_* using "./tables/robust/developer/4_agent_postcode_`var'_`pb'.tex", tex label replace
	}



	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & developer == `pb', absorb(`p_fe_`i'')
			 eststo t4_`var'_`i'
		}
		esttab t4_* using "./tables/robust/developer/4_property_postcode_`var'_`pb'.tex", tex label replace
	}



	// Good houses get good agents (table 4)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	capture rename popular_location pop_loc
	eststo clear
	 
	foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & developer == `pb', absorb(`p_fe_`i'')
				eststo t5_`var'_`fe_var'_`i'
			}
			esttab t5_* using "./tables/robust/developer/4_`var'_`fe_var'_`pb'.tex", tex label replace
		}
	}
}













// big agent

// agent level regressions (table 1)
forvalues pb = 0/1 {
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear
	collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & b_a == `pb', by(agent_id)

	// Only objective and basic agent controlled stuff
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
				eststo t2_`var'
			}


		}
		esttab t2_* using "./tables/robust/big_agent/2_no_text_class_`var'_`pb'.tex", tex label replace
	}



	// With text information 
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
				eststo t2_`var'
			}
		}
		esttab t2_* using "./tables/robust/big_agent/2_text_class_`var'_`pb'.tex", tex label replace
	}



	// Property level (table 2)
	local p_fe_1 property_postcode
	local p_fe_2 property_postcode property_listing_year
	local p_fe_3 property_postcode property_listing_year property_listing_month 
	local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
	 

	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	foreach dep_var of varlist $quality_measure {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & b_a == `pb', absorb(`p_fe_`i'') 
				eststo t3_`dep_var'_`fe_var'_`i'
				 
			}
		}
		  esttab t3_* using "./tables/robust/big_agent/3_`dep_var'_`pb'.tex", tex label replace

	}



	// Determinants of agent quality (table 3)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

	egen agent_listings = count(property_id), by(agent_id)
	egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
	egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & b_a == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'

		}
		esttab t4_* using "./tables/robust/big_agent/4_agent_postcode_`var'_`pb'.tex", tex label replace
	}



	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & b_a == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'

		}
		esttab t4_* using "./tables/robust/big_agent/4_property_postcode_`var'_`pb'.tex", tex label replace
	}



	// Good houses get good agents (table 4)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	capture rename popular_location pop_loc
	eststo clear
	 
	foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & b_a == `pb', absorb(`p_fe_`i'')
				 
				eststo t5_`var'_`fe_var'_`i'
			}
			esttab t5_* using "./tables/robust/big_agent/4_`var'_`fe_var'_`pb'.tex", tex label replace
		}
	}
}





















// stamp

// agent level regressions (table 1)
forvalues pb = 0/1 {
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear
	collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & stamp_er_b == `pb', by(agent_id)

	// Only objective and basic agent controlled stuff
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars `similarity', absorb(`p_fe_`i'')
				eststo t2_`var'
			}

		}
		esttab t2_* using "./tables/robust/stamp/2_no_text_class_`var'_`pb'.tex", tex label replace
	}



	// With text information 
	foreach var of varlist $stored_dvs {
		eststo clear
		foreach similarity of varlist p_l_s a_l_s {
			foreach fe of varlist agent_outcode agent_postcode {
				reghdfe `var' $obj_vars $agent_controlled_vars $positive_attrs, absorb(`p_fe_`i'')
				eststo t2_`var'
			}
		}
		esttab t2_* using "./tables/robust/stamp/2_text_class_`var'_`pb'.tex", tex label replace
	}



	// Property level (table 2)
	local p_fe_1 property_postcode
	local p_fe_2 property_postcode property_listing_year
	local p_fe_3 property_postcode property_listing_year property_listing_month 
	local p_fe_l `p_fe_1' `p_fe_2' `p_fe_3'
	 

	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	foreach dep_var of varlist $quality_measure {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `dep_var' fe_`fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & stamp_er_b == `pb', absorb(`p_fe_`i'') 
				eststo t3_`dep_var'_`fe_var'_`i'
				 
			}
		}
		  esttab t3_* using "./tables/robust/stamp/3_`dep_var'_`pb'.tex", tex label replace

	}



	// Determinants of agent quality (table 3)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

	egen agent_listings = count(property_id), by(agent_id)
	egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
	egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 

	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_agent_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & stamp_er_b == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'

		}
		esttab t4_* using "./tables/robust/stamp/4_agent_postcode_`var'_`pb'.tex", tex label replace
	}



	eststo clear
	 
	foreach var of varlist $kernel_dvs {
		forvalues i = 1/3 {
			reghdfe fe_`var' agent_listings agents_per_property_postcode if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & stamp_er_b == `pb', absorb(`p_fe_`i'')
			 
			eststo t4_`var'_`i'x

		}
		esttab t4_* using "./tables/robust/stamp/4_property_postcode_`var'_`pb'.tex", tex label replace
	}



	// Good houses get good agents (table 4)
	use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
	capture rename popular_location pop_loc
	eststo clear
	 
	foreach var of varlist ln_ep ln_lp bedrooms garden pop_loc {
		eststo clear
		foreach fe_var of varlist $kernel_dvs {
			forvalues i = 1/3 {
				reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & stamp_er_b == `pb', absorb(`p_fe_`i'')
				 
				eststo t5_`var'_`fe_var'_`i'
			}
			esttab t5_* using "./tables/robust/stamp/4_`var'_`fe_var'_`pb'.tex", tex label replace
		}
	}
}
