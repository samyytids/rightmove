global csv_data /Users/samueljames/Work/uni/rightmove/rightmove2.csv
global pb_ids /Users/samueljames/Work/uni/rightmove/pb_ids.csv
global original_data /Users/samueljames/Work/uni/rightmove/rightmove_data.dta
global new_data /Users/samueljames/Work/uni/
global positive_attrs x_closeness x_shops x_cafe x_pub x_restaurant x_cinema x_amenities x_popular_location x_school x_coastal x_other_water_location x_woodland x_garage x_freehold x_driveway x_off_street_parking x_chain_free x_glazing x_high_ceiling x_south_facing x_south_west_facing x_south_east_facing x_gch x_underfloor_heating
global text_scores closeness bus motorway train tube shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location pets woodland cul_de_sac original_features annex studio cottage bungalow townhouse house terraced mid_terrace end_terrace mews apartment flat barn duplex maisonette penthouse balcony juliette_balcony bedroom living_room sitting_room dining_room kitchen utility_room bathroom shower lounge parlour pantry billiard_room loft cellar cloakroom reception office study snug library conservatory playroom nursery_room garage workshop terrace roof wardrobe en_suite white_goods period_features views leasehold freehold detached semi_detached link_detached council_tax epc driveway off_street_parking summer_house fixtures_and_fittings chain_free glazing wood stone high_ceiling hall gym thatched carpeted tiled wood_flooring laminated_flooring porch gated beam bay_windows bow_window sash_window decking mezzanine breakfast_island garden sqft acreage patio nhbc town city village hamlet courtyard french_doors bifold_doors south_facing north_facing west_facing east_facing north_west_facing north_east_facing south_west_facing south_east_facing gch fireplace radiator swimming_pool hot_tub fitted has_tenant maintenance_charge service_charge underfloor_heating solar ev_charging ground_floor vaulted_ceiling restored remodelled refurbished modernised converted refitted extended restoration refurbishment modernisation extendable new_build well_appointed ready_to_move_in conversion private big potential planning_permission_granted planning_permission_pontential bright family home property_reference_number modern open_plan victorian georgian edwardian elizabethan viewing_recommended communal luxury investment first_time_buyer interior_design low_maintenance quiet landscaped separate cosy characterful first_time_to_market wrap_around rural urban secure listed beautiful storage btl front developer_implied rear award_winning architect brick
global new_text_scores x_*

// Import csvs and save as dta.
import delimited $pb_ids, clear

rename id agent_id

save $new_data/pb_ids.dta, replace

import delimited $csv_data, clear

save $original_data, replace

use $original_data, clear

// Converting tf to dummy 
foreach var of varlist residential buy virtual_tour online_viewing unpublished archived removed auction retirement affordable_scheme developer tax_exempt tax_included reduced {
	replace `var' = "1" if `var' == "t"
	replace `var' = "0" if `var' == "f"
	destring `var', replace
	format `var' %8.0g
	compress `var'
}

foreach var of varlist $text_scores {
	rename `var' x_`var'
}

// Ln of prices.
gen ln_ep = ln(early_price)
label variable ln_ep "Natural log of early price"
gen ln_lp = ln(late_price)
label variable ln_lp "Natural log of late price"

// Creating month variable 
split property_listing_date, p("-") destring
rename property_listing_date1 property_listing_year
rename property_listing_date2 property_listing_month
rename property_listing_date3 property_listing_day
egen property_listing_month_year = group(property_listing_year property_listing_month)
egen all_the_fes_pcode = group(property_listing_year property_listing_month property_postcode)
egen all_the_fes_ocode = group(property_listing_year property_listing_month property_outcode)

// Remove ancient properties 
winsor2 property_listing_year, cuts(1 99)
drop if property_listing_year < property_listing_year_w 
drop property_listing_year_w

// Basic stamp duty variable.
gen stamp_er_b = cond(late_price>250000, 1, 0)
gen stamp_la_b = cond(early_price>250000, 1, 0)

// Probably unnecessary, but thought it might be interesting.
gen stamp_er_l = cond(late_price>250000, 1, 0)
gen stamp_la_l = cond(early_price>250000, 1, 0)
replace stamp_er_l = 2 if early_price>925000 & early_price<=1500000
replace stamp_la_l = 2 if late_price>925000 & late_price<=1500000
replace stamp_er_l = 3 if early_price>1500000
replace stamp_la_l = 3 if late_price>1500000

// Num outcodes per agent.
egen outcode_tag = tag(agent_id property_outcode)
egen num_agent_outcodes = total(outcode_tag), by(agent_id)

// Distance from agent.
gen man_dist = abs(agent_approximate_latitude - property_latitude) + abs(agent_approximate_longitude - property_longitude)
gen crow_dist = ((agent_approximate_latitude - property_latitude)^2 + (agent_approximate_longitude - property_longitude)^2)^0.5

// is_pb marker.
merge m:1 agent_id using $new_data/pb_ids.dta, generate(is_pb)
gen temp_pb = 0
replace temp_pb = 1 if is_pb == 3
drop is_pb 
rename temp_pb is_pb

// Has positive attr.x
gen p_attr = 0
foreach var of varlist $positive_attrs {
	replace p_attr = 1 if `var' > 0.8
}

// Regression variables.
replace time_to_stc = . if time_to_stc == 0
gen stc30 = 1 if time_to_stc <= 30 & time_to_stc > 0
replace stc30 = 0 if stc30 == .
label variable stc30 "STC within 30 days"
gen stc60 = 1 if time_to_stc <= 60 & time_to_stc > 0
replace stc60 = 0 if stc60 == .
gen stc90 = 1 if time_to_stc <= 90 & time_to_stc > 0
replace stc90 = 0 if stc90 == .
label variable stc60 "STC within 60 days"
gen listing_date = date(property_listing_date, "YMD")
gen dom = date("2024-06-27", "YMD") - listing_date
gen hkf = 1 if x_cloakroom != .
replace hkf = 0 if hkf == .
egen p_t = group(property_type)
egen p_s_t = group(property_sub_type)
gen b_a = cond(num_agent_outcodes > 2, 1, 0)
egen agent_listings = count(property_id), by(agent_id)
egen agents_per_property_postcode = count(agent_id), by(property_postcode) // Using this for now as agent postcodes are sparse
egen agents_per_agent_postcode = count(agent_id), by(agent_postcode)
egen agents_per_agent_outcode = count(agent_id), by(agent_outcode) 

pca $new_text_scores, components(1)
predict pc1
rename pc1 t_c_s
label variable t_c_s "Text class scores (PCA)"

egen postcode_listings = count(property_id), by(property_postcode)
gen n_o_a_l = postcode_listings - agent_listings


// Tidy up
rename average_resolution avg_r
rename description_length d_l
rename reduced_percentage r_p 
rename agent_level_similarity a_l_s
rename property_level_similarity p_l_s
rename ground_rent_percentage_increase ground_rent_inc
rename agent_outcode a_o
rename agent_postcode a_p

// Dummies
// replace property_type = subinstr(property_type, " ", "_",.)
// replace property_type = subinstr(property_type, "/", "_",.)
// replace property_type = subinstr(property_type, "___", "_",.)
// replace property_type = subinstr(property_type, "__", "_",.)
// replace property_type = strlower(property_type)
// levelsof property_type, local(p_type)
// foreach p of local p_type {
// 	gen z_`p' = cond(property_type == "`p'", 1, 0)
// }
//
//
// replace property_sub_type = subinstr(property_sub_type, " ", "_",.)
// replace property_sub_type = subinstr(property_sub_type, "/", "_",.)
// replace property_sub_type = subinstr(property_sub_type, "___", "_",.)
// replace property_sub_type = subinstr(property_sub_type, "__", "_",.)
// replace property_sub_type = subinstr(property_sub_type, "&", "",.)
// replace property_sub_type = subinstr(property_sub_type, "(", "",.)
// replace property_sub_type = subinstr(property_sub_type, ")", "",.)
// replace property_sub_type = subinstr(property_sub_type, "-", "_",.)
// replace property_sub_type = strlower(property_sub_type)
// replace property_sub_type = subinstr(property_sub_type, "shopping_centre", "s_c",.)
// levelsof property_sub_type, local(p_s_type)
// foreach p of local p_s_type {
// 	gen q_`p' = cond(property_sub_type == "`p'", 1, 0)
// }

egen group_p_t = group(property_type)
egen group_p_s_t = group(property_sub_type)

label variable n_o_a_l "Num other agent listings in postcode"
label variable r_p "Reduced percentage"
label variable p_t "Property type"
label variable p_s_t "Property sub type"
label variable b_a "Big agent"
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
label variable d_l "Description length"
label variable num_images "Num images"
label variable hkf "Has key features"
label variable p_l_s "Property level text similarity"
label variable a_l_s "Agent level text similarity"
label variable x_closeness "Close to amenities"
label variable x_shops "Shops"
label variable x_cafe "Cafes"
label variable x_pub "Pubs"
label variable x_restaurant "Restaurants"
label variable x_amenities "Generic amenities"
label variable x_popular_location "Popular location"
label variable x_school "School"
label variable x_coastal "Coastal"
label variable x_other_water_location "Waterside"
label variable x_woodland "Woodland"
label variable x_garage "Garage"
label variable x_freehold "Freehold"
label variable x_driveway "Driveway"
label variable x_off_street_parking "Off street parking"
label variable x_chain_free "Chain free"
label variable x_glazing "Glazing"
label variable x_high_ceiling "High ceilings"
label variable x_south_facing "South facing"
label variable x_south_east_facing "South East facing"
label variable x_south_west_facing "South West facing"
label variable x_gch "Gas central heating"
label variable x_underfloor_heating "Underfloor heating"
label variable p_attr "Has positive attributes"
label variable days_featured "Featured listing days"
label variable days_premium "Premium listing days"
label variable a_p "Agent postcode"
label variable a_o "Agent outcode"
label variable p_t "Property type"
label variable p_s_t "Property sub type"
label variable dom "Days on market"
label variable agents_per_property_postcode "Num agents per property postcode"
label variable agents_per_agent_outcode "Num agents per agent outcode"
label variable agents_per_agent_postcode "Num agents per agent postcode"
label variable agent_listings "Num listings"

save $original_data, replace

