global csv_data /Users/samueljames/Work/uni/rightmove/rightmove2.csv
global pb_ids /Users/samueljames/Work/uni/rightmove/pb_ids.csv
global original_data /Users/samueljames/Work/uni/rightmove/rightmove_data.dta
global new_data /Users/samueljames/Work/uni/rightmove

// Import data from CSVs and create base DTA file.

// import delimited $pb_ids, clear
// rename id agent_id
// save $new_data/pb_ids.dta, replace
// import delimited $csv_data, clear
// save $original_data, replace

// Manipulate base DTA for use with regressions.do

// use $original_data, clear
//
//
// // Converting strings to dummy 
// foreach var of varlist residential buy virtual_tour online_viewing unpublished archived removed auction retirement affordable_scheme developer tax_exempt tax_included reduced {
// 	replace `var' = "1" if `var' == "t"
// 	replace `var' = "0" if `var' == "f"
// 	destring `var', replace
// 	format `var' %8.0g
// 	compress `var'
// }
//
// save $original_data, replace
use $original_data, clear

drop reduced_percentage

// Rename text scores for use later
local text_scores closeness bus motorway train tube shops cafe pub restaurant cinema amenities popular_location school coastal other_water_location pets woodland cul_de_sac original_features annex studio cottage bungalow townhouse house terraced mid_terrace end_terrace mews apartment flat barn duplex maisonette penthouse balcony juliette_balcony bedroom living_room sitting_room dining_room kitchen utility_room bathroom shower lounge parlour pantry billiard_room loft cellar cloakroom reception office study snug library conservatory playroom nursery_room garage workshop terrace roof wardrobe en_suite white_goods period_features views leasehold freehold detached semi_detached link_detached council_tax epc driveway off_street_parking summer_house fixtures_and_fittings chain_free glazing wood stone high_ceiling hall gym thatched carpeted tiled wood_flooring laminated_flooring porch gated beam bay_windows bow_window sash_window decking mezzanine breakfast_island garden sqft acreage patio nhbc town city village hamlet courtyard french_doors bifold_doors south_facing north_facing west_facing east_facing north_west_facing north_east_facing south_west_facing south_east_facing gch fireplace radiator swimming_pool hot_tub fitted has_tenant maintenance_charge service_charge underfloor_heating solar ev_charging ground_floor vaulted_ceiling restored remodelled refurbished modernised converted refitted extended restoration refurbishment modernisation extendable new_build well_appointed ready_to_move_in conversion private big potential planning_permission_granted planning_permission_pontential bright family home property_reference_number modern open_plan victorian georgian edwardian elizabethan viewing_recommended communal luxury investment first_time_buyer interior_design low_maintenance quiet landscaped separate cosy characterful first_time_to_market wrap_around rural urban secure listed beautiful storage btl front developer_implied rear award_winning architect brick
foreach var of varlist `text_scores' {
	rename `var' x_`var'
}

replace time_to_stc = . if time_to_stc == 0

gen delisted = cond(time_to_stc == . & (archived == 1 | removed == 1 | unpublished == 1), 1, 0)

// Reducing sample down to regression variable sizes
// Also removing some junk data that shoul never have got this far!
// Property characteristics
// Property characteristics
egen p_t = group(property_type)
egen p_s_t = group(property_sub_type)

gen disallowed_property_type = cond((property_type == "Garage / Parking" | property_type == "House / Flat Share" | property_type == "Mobile / Park homes" | property_type == "Not Specified" | property_type == "Private Halls" | property_type == "Land"), 1, 0)

keep if residential == 1 & buy == 0 & retirement == 0 & affordable_scheme == 0 & auction == 0 & early_price > 1 & num_images < 1000 & delisted == 0 & disallowed_property_type == 0

levelsof property_type, local(p_types)
levelsof property_sub_type, local(p_s_types)

foreach var of local p_types {
	local p_var = strlower("`var'")
	local p_var = subinstr("`p_var'", " ", "_",.)
	local p_var = subinstr("`p_var'", "/", "",.)
	local p_var = subinstr("`p_var'", "__", "_",.)
	gen pr_`p_var' = cond(property_type == "`var'", 1, 0) 
	label variable pr_`p_var' "`var'"
}

foreach var of local p_s_types {
	local p_var = strlower("`var'")
	local p_var = subinstr("`p_var'", " ", "_",.)
	local p_var = subinstr("`p_var'", "/", "",.)
	local p_var = subinstr("`p_var'", "__", "_",.)
	local p_var = subinstr("`p_var'", "-", "_",.)
	local p_var = subinstr("`p_var'", "house_of_multiple_occupation", "hmo",.)
	gen prs_`p_var' = cond(property_sub_type == "`var'", 1, 0) 
	label variable prs_`p_var' "`var'"
}



// Generate FE variables
split property_listing_date, p("-") destring
rename property_listing_date1 property_listing_year
rename property_listing_date2 property_listing_month
rename property_listing_date3 property_listing_day
egen property_listing_month_year = group(property_listing_year property_listing_month)
egen all_the_fes_pcode = group(property_listing_year property_listing_month property_postcode)
egen all_the_fes_ocode = group(property_listing_year property_listing_month property_outcode)


// Winsorizing
winsor2 property_listing_year, replace cuts(1 99)
winsor2 early_price, replace cuts(1 99)
winsor2 late_price, replace cuts(1 99)
winsor2 bathrooms, replace cuts(1 99)
winsor2 bedrooms, replace cuts(1 99)

gen reduced_percentage = ((early_price - late_price)/early_price)*100

// Generate Dependent variables

gen stc30 = 1 if time_to_stc <= 30 & time_to_stc > 0
replace stc30 = 0 if stc30 == .

gen stc60 = 1 if time_to_stc <= 60 & time_to_stc > 0
replace stc60 = 0 if stc60 == .

gen stc90 = 1 if time_to_stc <= 90 & time_to_stc > 0
replace stc90 = 0 if stc90 == .


// Generate independent variables

// Area characteristics

// Listing characteristics
gen arpw = average_resolution / description_length
gen nipw = num_images / description_length

rename x_planning_permission_pontential x_ppp

local new_text_scores x_*
local dummy_text_scores qx_*
foreach var of varlist `new_text_scores' {
	gen q`var' = cond(`var' > 0.4, 1, 0, .)
	replace q`var' = . if `var' == .
	local i = `i' + 1
}

gen coastal_view = qx_coastal * qx_views
gen water_view = qx_other_water_location * qx_views
gen woodland_view = qx_woodland * qx_views


bysort agent_id property_listing_month property_listing_year: egen num_kf = total(qx_closeness)

// Competition characteristics
// Current spec: 
// 		- agent month year [location]
egen agent_listings = count(property_id), by(agent_id property_listing_year property_listing_month)

egen agent_postcode_listings = count(property_id), by(agent_id property_listing_month property_listing_year property_postcode)

egen agents_per_property_postcode = count(agent_id), by(property_listing_month property_listing_year property_postcode) // Using this for now as agent postcodes are sparse

egen agents_per_property_outcode = count(agent_id), by(property_listing_month property_listing_year property_outcode) // Using this for now as agent postcodes are sparse

egen postcode_listings = count(property_id), by(property_listing_month property_listing_year property_postcode)
gen noal = postcode_listings - agent_postcode_listings

// Generating distance variables
gen man_dist = abs(agent_approximate_latitude - property_latitude) + abs(agent_approximate_longitude - property_longitude)

gen crow_dist = ((agent_approximate_latitude - property_latitude)^2 + (agent_approximate_longitude - property_longitude)^2)^0.5

// Diamonds in the rough
bysort property_outcode property_listing_month property_listing_year: egen avg_price_outcode = mean(early_price)
bysort property_postcode property_listing_month property_listing_year: egen avg_price_postcode = mean(early_price)
gen diamond = cond(avg_price_outcode < avg_price_postcode, 1, 0)
gen diamond_value = avg_price_postcode - avg_price_outcode

// Text clarity
egen avg_text_score = rmean(x_*)
egen total_text_score = rowtotal(x_*)

// Agent variables
gen multi_office = cond(agent_postcode == ., 1, 0)
egen a_l_p_y_m  = count(property_id), by(agent_id property_postcode property_listing_month property_listing_year)
egen a_l_p_y  = count(property_id), by(agent_id property_postcode property_listing_year)
egen a_l_o_y_m  = count(property_id), by(agent_id property_outcode property_listing_month property_listing_year)
egen a_l_o_y  = count(property_id), by(agent_id property_outcode property_listing_year)

egen l_p_y_m  = count(property_id), by(property_postcode property_listing_month property_listing_year)
egen l_p_y  = count(property_id), by(property_postcode property_listing_year)
egen l_o_y_m  = count(property_id), by(property_outcode property_listing_month property_listing_year)
egen l_o_y  = count(property_id), by(property_outcode property_listing_year)

gen d_p_y_m  = a_l_p_y_m / l_p_y_m
gen d_p_y  = a_l_p_y / l_p_y
gen d_o_y_m  = a_l_o_y_m / l_o_y_m
gen d_o_y  = a_l_o_y / l_o_y

gen stc_price = late_price if time_to_stc != .

// Converting to natural log

gen early_price2 = early_price
local to_ln early_price late_price bedrooms bathrooms average_distance average_resolution description_length num_images nipw arpw agent_listings agents_per_property_postcode crow_dist man_dist stc_price
local to_ln_add num_cable_car num_light_railway num_london_overground num_london_underground num_national_train num_private_railway num_tram days_featured days_premium num_kf property_level_similarity noal 
local to_ln_add_min reduced_percentage

foreach var of varlist `to_ln' {
	replace `var' = ln(`var')
}

foreach var of varlist `to_ln_add' {
	replace `var'  = `var' + 0.0001
	replace `var' = ln(`var')
}

foreach var of varlist `to_ln_add_min' {
	su `var', meanonly
	if r(min) < 0 {
		replace `var' = `var' - r(min)
	}
	else {
		replace `var' = `var' + r(min)
	}
	replace `var' = `var' + 0.0001
	replace `var' = ln(`var')
}

gen featured = cond(days_featured > 0, 1, 0)
gen premium = cond(days_premium > 0, 1, 0)

gen d_l2 = description_length^2
gen avg_r2 = average_resolution^2
gen n_i2 = num_images^2

// Renaming variables
rename average_resolution avg_r
rename description_length d_l
rename reduced_percentage r_p 
rename num_images n_i
rename agent_level_similarity a_l_s
rename property_level_similarity p_l_s
rename ground_rent_percentage_increase ground_rent_inc
rename agent_outcode a_o
rename agent_postcode a_p
rename early_price e_p
rename late_price l_p
rename council_tax_band ctb
rename avg_text_score a_t_s 
rename total_text_score t_t_s


// Labelling variable
label variable stc_price "Price at STC"
label variable featured "Featured listing"
label variable premium "Premium listing"
label variable d_p_y_m "Postcode level market share (year monthly)"
label variable d_p_y "Postcode level market share (yearly)"
label variable d_o_y_m "Outcode level market share (year monthly)"
label variable d_o_y "Outcode level market share (yearly)"
label variable a_t_s "Average text score"
label variable t_t_s "Total text score"
label variable ctb "Council tax band"
label variable d_l2 "Description length squared"
label variable avg_r2 "Average resolution squared"
label variable n_i2 "Number of images squared"
label variable noal "Num other agent listings in postcode"
label variable e_p "Listing price"
label variable l_p "Current price"
label variable r_p "Reduced percentage"
label variable p_t "Property type"
label variable p_s_t "Property sub type"
label variable bedrooms "Bedrooms"
label variable bathrooms "Bathrooms"
label variable average_distance "Avg distance from station"
label variable num_cable_car "Cable car"
label variable num_light_railway "Light rail"
label variable num_london_overground "London overground"
label variable num_national_train "National rail"
label variable num_tram "Tram"
label variable num_private_railway "Private rail"
label variable avg_r "Avg photo resolution"
label variable d_l "Description length"
label variable n_i "Num images"
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
label variable days_featured "Featured listing days"
label variable days_premium "Premium listing days"
label variable a_p "Agent postcode"
label variable a_o "Agent outcode"
label variable p_t "Property type"
label variable p_s_t "Property sub type"
label variable dom "Days on market"
label variable agents_per_property_postcode "Num agents per property postcode"
label variable agent_listings "Num listings"

save $new_data/rightmove_data_rg.dta, replace
