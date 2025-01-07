global obj_vars bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway

global obj_vars_p_level bedrooms bathrooms average_distance num_cable_car num_light_railway num_london_overground num_national_train num_tram num_private_railway p_t p_s_t deprivation overall_effectiveness effective_leadership quality_education personal_development behaviour early_years_provision sixth_form_provision

global kernel_dvs stc30 stc60 dom ln_ep ln_lp r_p

global stored_dvs fe_stc30 fe_stc60 fe_dom fe_ln_ep fe_ln_lp fe_r_p

global text_scores closeness bus motorway train tube shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location pets woodland cul_de_sac original_features annex studio cottage bungalow townhouse house terraced mid_terrace end_terrace mews apartment flat barn duplex maisonette penthouse balcony juliette_balcony bedroom living_room sitting_room dining_room kitchen utility_room bathroom shower lounge parlour pantry billiard_room loft cellar cloakroom reception office study snug library conservatory playroom nursery_room garage workshop terrace roof wardrobe en_suite white_goods period_features views leasehold freehold detached semi_detached link_detached council_tax epc driveway off_street_parking summer_house fixtures_and_fittings chain_free glazing wood stone high_ceiling hall gym thatched carpeted tiled wood_flooring laminated_flooring porch gated beam bay_windows bow_window sash_window decking mezzanine breakfast_island garden sqft acreage patio nhbc town city village hamlet courtyard french_doors bifold_doors south_facing north_facing west_facing east_facing north_west_facing north_east_facing south_west_facing south_east_facing gch fireplace radiator swimming_pool hot_tub fitted has_tenant maintenance_charge service_charge underfloor_heating solar ev_charging ground_floor vaulted_ceiling restored remodelled refurbished modernised converted refitted extended restoration refurbishment modernisation extendable new_build well_appointed ready_to_move_in conversion private big potential planning_permission_granted planning_permission_pontential bright family home property_reference_number modern open_plan victorian georgian edwardian elizabethan viewing_recommended communal luxury investment first_time_buyer interior_design low_maintenance quiet landscaped separate cosy characterful first_time_to_market wrap_around rural urban secure listed beautiful storage btl front developer_implied rear award_winning architect brick

global agent_controlled_vars days_featured days_premium avg_r avg_r2 d_l d_l2 num_images n_i2 hkf

global agent_characteristics agent_outcode agent_postcode

global positive_attrs closeness shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location woodland garage freehold driveway off_street_parking chain_free glazing high_ceiling south_facing south_west_facing south_east_facing gch underfloor_heating

global quality_measure avg_r d_l hkf 


use /Users/samueljames/Work/uni/rightmove/rightmove_data.dta, clear

rename ground_rent_percentage_increase ground_rent_inc

label variable bedrooms "Bedrooms"
label variable bathrooms "Bathrooms"
label variable average_distance "Avg distance from station"
label variable num_cable_car "Cable car"
label variable num_light_railway "Light rail"
label variable num_london_overground "London overground"
label variable num_national_train "National rail"
label variable num_tram "Tram"
label variable num_private_railway "Private rail"
label variable ln_ep "Ln initial price"
label variable ln_lp "Ln current price"
label variable avg_r "Avg photo resolution"
label variable avg_r2 "Avg photo resolution sq"
label variable d_l "Description length"
label variable d_l2 "Description length sq"
label variable num_images "Num images"
label variable n_i2 "Num images sq"
label variable hkf "Has key features"
label variable p_l_s "Property level text similarity"
label variable a_l_s "Agent level text similarity"
label variable closeness "Close to amenities"
label variable shops "Shops"
label variable cafe "Cafes"
label variable pub "Pubs"
label variable restaurant "Restaurants"
label variable amenities "Generic amenities"
label variable popular_location "Popular location"
label variable school "School"
label variable coastal "Coastal"
label variable other_water_location "Waterside"
local variable woodland "Woodland"
local variable garage "Garage"
local variable freehold "Freehold"
local variable driveway "Driveway"
local variable off_street_parking "Off street parking"
local variable chain_free "Chain free"
local variable glazing "Glazing"
local variable high_ceiling "High ceilings"
local variable south_facing "South facing"
local variable south_east_facing "South East facing"
local variable south_west_facing "South West facing"
local variable gch "Gas central heating"
local variable underfloor_heating "Underfloor heating"
local variable p_attr "Has positive attributes"
local variable days_featured "Featured listing days"
local variable days_premium "Premium listing days"
local variable agent_postcode "Agent postcode"
local variable agent_outcode "Agent outcode"


eststo clear
// Regressions additive FEs
foreach var of varlist $kernel_dvs {
	reghdfe `var' $obj_vars if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(agent_id property_postcode property_listing_year property_listing_month, savefe) 
	rename __hdfe1__ fe_`var'
	
	eststo t1_`var'
}
esttab t1_* using "./tables/1.tex", tex label replace

foreach var of varlist $kernel_dvs {
	bysort agent_id (fe_`var'): replace fe_`var' = fe_`var'[1] if missing(fe_`var')
}

save /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, replace



use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, clear

label variable fe_stc30 "STC within 30 days (fe)"
label variable fe_stc60 "STC within 60 days (fe)"
label variable fe_dom "Days on market (fe)"
label variable fe_ln_ep "Ln initial price (fe)"
label variable fe_ln_lp "Ln current price (fe)"
label variable fe_r_p "Price reduction percentage (fe)"
egen agent_listings = count(property_id), by(agent_id)
label variable agent_listings "Num agent listings"
egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
label variable agents_per_property_postcode "Num agents per property postcode"
egen agents_per_agent_postcode = count(agent_id), by(agent_postcode) 
label variable agents_per_agent_postcode "Num agents per agent postcode"

save /Users/samueljames/Work/uni/rightmove/rightmove_data_v2.dta, replace

// Save kdensity
foreach var of varlist $kernel_dvs {
	quietly kdensity fe_`var'
	graph save "./graphs/`var'.gph", replace
}


// Agent level regressions
foreach v of var * {
	local l`v' : variable label `v'
}
collapse (mean) $stored_dvs p_l_s a_l_s $obj_vars $agent_controlled_vars $text_scores $agent_characteristics $stored_fes if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, by(agent_id)
foreach v of var * {
	label var `v' "`l`v''"
}


save /Users/samueljames/Work/uni/rightmove/rightmove_data_agent_level_v1.dta, replace

use /Users/samueljames/Work/uni/rightmove/rightmove_data_agent_level_v1.dta, clear
rename agent_outcode a_o
rename agent_postcode a_p

eststo clear
// Only objective and basic agent controlled stuff
foreach var of varlist $stored_dvs {	
	foreach similarity of varlist p_l_s a_l_s {
		foreach fe of varlist a_p {
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
		foreach fe of varlist a_p {
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
	foreach fe_var of varlist $stored_dvs {
		forvalues i = 3/3 {
			reghdfe `dep_var' `fe_var' $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
			eststo t3_`dep_var'_`fe_var'_`i'
		}
	}
	  esttab t3_* using "./tables/3_`dep_var'.tex", tex label replace
}


// Determinants of agent quality (table 3)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace

eststo clear
 
foreach var of varlist $kernel_dvs {
	forvalues i = 3/3 {
		reghdfe fe_`var' agent_listings agents_per_agent_postcode  $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'') 
		eststo t4_`var'_`i'
		
	}
}
esttab t4_* using "./tables/4_competition_agent_postcode.tex", tex label replace



eststo clear
foreach var of varlist $kernel_dvs {
	forvalues i = 3/3 {
		reghdfe fe_`var' agent_listings agents_per_property_postcode $obj_vars_p_level if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
		eststo t4_`var'_`i'
		
	}
}
esttab t4_* using "./tables/4_competition_property_postcode.tex", tex label replace



// Good houses get good agents (table 4)
use /Users/samueljames/Work/uni/rightmove/rightmove_data_v2, replace
rename popular_location pop_loc
eststo clear
foreach var of varlist bedrooms bathrooms size garden pop_loc {
	eststo clear
	foreach fe_var of varlist $kernel_dvs {
		forvalues i = 3/3 {
			reghdfe `var' fe_`fe_var' $obj_vars_no_bedrooms if residential == 1 & buy == 1 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1, absorb(`p_fe_`i'')
			eststo t5_`var'_`fe_var'_`i'
		}
	}
	esttab t5_* using "./tables/4_`var'.tex", tex label replace
}







