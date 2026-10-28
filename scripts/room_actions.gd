class_name RoomActions
## Vad man kan gÃ¶ra i varje rum, kopplat till en sak i rummet. Varje handling Ã¤r en
## dictionary med:
##   id          â€“ unikt namn (anvÃ¤nds fÃ¶r "en gÃ¥ng per dag")
##   object      â€“ mÃ¶beltypen i FloorPlanArt.FURNITURE som handlingen hÃ¶r till; den
##                 markeras i planen nÃ¤r man hÃ¥ller musen Ã¶ver valet ("" = ingen)
##   label       â€“ knapptexten
##   text        â€“ vad som hÃ¤nder (visas i textrutan)
##   time        â€“ true: en aktivitet som flyttar dygnet till nÃ¤sta tidszon
##   effects     â€“ Ã¤ndringar i mÃ¤tarna, t.ex. {"home": 10}
##   relief      â€“ sÃ¤nker mammans egen mÃ¤tare (se GameState._relieve_mom)
##   social      â€“ XP i mammans egenskaper, t.ex. {"fitness": 5} (se SocialStats)
##   requires    â€“ krav pÃ¥ egenskaper eller Attractiveness, t.ex. {"charm": 3} eller
##                 {"attractiveness": 4}; valet syns men Ã¤r lÃ¥st tills de uppfylls
##   link        â€“ relation som fÃ¥r poÃ¤ng (social link), och link_points hur mÃ¥nga
##   needs       â€“ personen mÃ¥ste vara i rummet; needs_home â€“ nÃ¥gonstans hemma
##   periods     â€“ bara under dessa tidszoner
##   panel       â€“ Ã¶ppnar en panel i stÃ¤llet ("wardrobe", "vanity", "salon" eller "map");
##                 salongens panel tar betalt och tid sjÃ¤lv nÃ¤r besÃ¶ket bokas
##   sets_flag   â€“ en hÃ¤ndelse i storyn som handlingen sÃ¤tter (lÃ¥ser upp platser m.m.)
##   hidden_flag â€“ valet dÃ¶ljs nÃ¤r den hÃ¤r hÃ¤ndelsen redan har hÃ¤nt
##   completes   â€“ en quest som handlingen avslutar
##   weekdays    â€“ bara dessa veckodagar (index 0 = mÃ¥ndag)
##   reveal_flag â€“ valet syns fÃ¶rst nÃ¤r den hÃ¤r hÃ¤ndelsen har hÃ¤nt (t.ex. en hittad
##                 sidoinkomst, se Economy.SIDE_INCOME)
## Pengar (se Economy):
##   cost        â€“ vad det kostar; gÃ¥r inte att vÃ¤lja om pengarna inte rÃ¤cker
##   waived_by   â€“ gratis med ett abonnemang som har den hÃ¤r "waives" (t.ex. gym_visit)
##   earn        â€“ vad det ger; earn_scale hÃ¶jer det per nivÃ¥, t.ex. {"knowledge": 10}
##   income      â€“ vilken sidoinkomst pengarna rÃ¤knas till (Economy.SIDE_INCOME)
##   groceries   â€“ rÃ¤knas som veckohandlingen (annars blir det hÃ¤mtmat, se Economy.TAKEOUT)
##   gives_item  â€“ ger en sak (Economy.ITEMS); needs_item krÃ¤ver och fÃ¶rbrukar en
##   buys/sells/subscribe/unsubscribe â€“ sÃ¤tts av Economy.actions_for_room()
##   ledger_label â€“ namnet i kontoutdraget, om det ska skilja sig frÃ¥n label
## TrÃ¤dgÃ¥rden (se Backyard):
##   fx            â€“ en kort animation i 3D-vyn innan handlingen genomfÃ¶rs ("swim", "sun",
##                   "water" eller "fetch", se HouseView3D.play_activity)
##   waters_plants â€“ vattnar rabatterna, sÃ¥ att de inte vissnar
##   calls_dog     â€“ Rex kommer ut i trÃ¤dgÃ¥rden och stannar dÃ¤r resten av tidszonen
## Gardiner (sÃ¤tts av Curtains.actions_for_room()):
##   curtains    â€“ lÃ¤get som gardinerna dras till ("open" eller "closed")
## FÃ¶rfrÃ¥gningar (sÃ¤tts av Requests.actions_for_room()):
##   fulfills/declines â€“ personen vars Ã¶ppna fÃ¶rfrÃ¥gan gÃ¶rs eller avbÃ¶js
##   delegates         â€“ personen som gÃ¶r sysslan i stÃ¤llet (betalar av en skuld)
## Snabba handlingar som ger nÃ¥got gÃ¥r bara en gÃ¥ng per dag (GameState). Texterna Ã¤r
## platshÃ¥llare tills riktig story skrivs. All text spelaren ser Ã¤r pÃ¥ engelska.

const ACTIONS := {
	"kitchen": [
		{"id": "kitchen_dishes", "object": "sink", "label": "Do the dishes", "text": "You do the dishes.", "time": true, "effects": {"home": 15}},
		{"id": "kitchen_cook", "object": "stove", "label": "Cook dinner", "text": "You cook dinner for the family.", "time": true, "effects": {"home": 20}, "relief": 5},
		{"id": "kitchen_fridge", "object": "fridge", "label": "Check the fridge", "text": "You go through the fridge and write a shopping list.", "effects": {"home": 5}},
	],
	"hall": [
		{"id": "hall_leave", "object": "", "label": "Leave the house", "text": "", "panel": "map"},
		{"id": "hall_shoes", "object": "shoe_rack", "label": "Tidy up the shoes", "text": "You line up the boys' sneakers. Again.", "effects": {"home": 3}},
		{"id": "hall_walk_dog", "object": "", "label": "Walk the dog", "text": "You take the dog around the block. The fresh air clears your head.", "time": true, "effects": {"home": 5}, "relief": 3, "social": {"fitness": 3}},
	],
	"living_room": [
		{"id": "living_tv", "object": "tv", "label": "Watch a show with your husband", "text": "You curl up next to him and watch an episode together.", "time": true, "relief": 10, "link": "husband", "link_points": 2, "needs": "husband"},
		{"id": "living_sofa", "object": "sofa", "label": "Rest on the sofa", "text": "You put your feet up for a while.", "time": true},
		{"id": "living_flirt", "object": "sofa", "label": "Flirt with your husband", "text": "You sit on the armrest and tease him until he forgets the TV is on.", "relief": 8, "social": {"charm": 1}, "link": "husband", "link_points": 2, "needs": "husband", "requires": {"charm": 2}},
		{"id": "living_books","object": "shelf", "label": "Browse the bookshelf", "text": "You pick out a novel you have been meaning to read.", "social": {"knowledge": 2}},
	],
	"guest_wc": [
		{"id": "wc_freshen", "object": "basin", "label": "Freshen up", "text": "You splash some water on your face."},
	],
	"home_office": [
		{"id": "office_grade", "object": "desk", "label": "Grade tests", "text": "You grade a stack of tests.", "time": true, "effects": {"work": 15}},
		{"id": "office_plan", "object": "desk", "label": "Plan lessons", "text": "You plan this week's lessons.", "time": true, "effects": {"work": 10}, "social": {"knowledge": 3}},
		{"id": "office_read", "object": "shelf", "label": "Read up on teaching", "text": "You skim a chapter on classroom management.", "effects": {"work": 3}, "social": {"knowledge": 2}},
	],
	"upstairs_hall": [
		{"id": "upstairs_photos", "object": "photo_wall", "label": "Look at the family photos", "text": "Beach trips, school photos, the boys in matching sweaters. You smile."},
		{"id": "upstairs_laundry", "object": "basket", "label": "Gather the dirty laundry", "text": "You collect the laundry from the hamper.", "effects": {"home": 3}},
	],
	"bathroom": [
		{"id": "bath_bath", "object": "bathtub", "label": "Take a long bath", "text": "You light a candle and soak until the water cools.", "time": true, "relief": 5, "social": {"charm": 3}},
		{"id": "bath_freshen", "object": "basin", "label": "Freshen up", "text": "You wash your face and brush your hair."},
	{"id": "bath_peep_son1", "object": "bathtub", "label": "Soak with the door open", "text": "The door stays open a crack. Miles's footsteps pass twice.", "lust": 3.0, "link": "son_1", "link_points": 0, "periods": ["evening"], "reveal_flag": "peep_miles", "hidden_flag": "peep_miles_2"},
	{"id": "bath_peep_son1_2", "object": "bathtub", "label": "Soak with the door open", "text": "The footsteps stop this time. He doesn't come in.", "lust": 5.0, "link": "son_1", "link_points": 0, "periods": ["evening"], "reveal_flag": "peep_miles_2", "hidden_flag": "peep_miles_3"},
	{"id": "bath_peep_son1_3", "object": "bathtub", "label": "Soak with the door open", "text": "He knocks this time. She tells him to come in.", "lust": 8.0, "link": "son_1", "link_points": 0, "periods": ["evening"], "reveal_flag": "peep_miles_3"},
	],
	"bedroom": [
		{"id": "bedroom_wardrobe", "object": "wardrobe", "label": "Change clothes", "text": "", "panel": "wardrobe"},
		{"id": "bedroom_vanity", "object": "vanity", "label": "Makeup, accessories & hair up", "text": "", "panel": "vanity"},
		{"id": "bedroom_laptop_game", "object": "desk", "label": "Play an online game with Son 1", "text": "You log in and he invites you to his squad. You are terrible. He laughs and carries you through the match.", "time": true, "link": "son_1", "link_points": 3, "needs_home": "son_1"},
		{"id": "bedroom_laptop_mail", "object": "desk", "label": "Answer school emails", "text": "You clear out your inbox on the laptop.", "time": true, "effects": {"work": 10}},
		{"id": "bedroom_nap", "object": "bed", "label": "Take a nap", "text": "You lie down for a nap.", "time": true},
	],
	"son_room_1": [
		{"id": "son1_console", "object": "media_stand", "label": "Play co-op on the console", "text": "You squeeze onto the beanbag next to him and play until he finally beats the boss.", "time": true, "link": "son_1", "link_points": 3, "needs": "son_1"},
		{"id": "son1_pc", "object": "gaming_desk", "label": "Ask about his game", "text": "He explains his build in great detail. You understand about half of it.", "link": "son_1", "link_points": 1, "needs": "son_1", "social": {"knowledge": 1}},
		{"id": "son1_lore", "object": "gaming_desk", "label": "Debate the game's lore with him", "text": "You have actually read up on the lore. He stares at you, then talks for an hour straight.", "time": true, "social": {"knowledge": 1}, "link": "son_1", "link_points": 4, "needs": "son_1", "requires": {"knowledge": 3}},
		{"id": "son1_figures","object": "collectible_shelf", "label": "Look at his figure collection", "text": "He tells you the story behind every figure on the shelf.", "link": "son_1", "link_points": 1, "needs": "son_1"},
		{"id": "son1_bed", "object": "bed", "label": "Make his bed", "text": "You make his bed and find three empty energy drink cans.", "effects": {"home": 3}},
	],
	"son_room_2": [
		{"id": "son2_bench", "object": "weight_bench", "label": "Spot him on the bench press", "text": "You spot him while he pushes for a new personal best. He gets it.", "time": true, "link": "son_2", "link_points": 3, "needs": "son_2", "social": {"fitness": 2}},
		{"id": "son2_homework", "object": "desk", "label": "Help with his homework", "text": "You help him through his history essay between his complaints.", "time": true, "effects": {"work": 3}, "link": "son_2", "link_points": 2, "needs": "son_2", "social": {"knowledge": 3}},
		{"id": "son2_run", "object": "football_gear", "label": "Challenge him to a run", "text": "You keep up with him the whole way and pull ahead on the last hill. He demands a rematch.", "time": true, "social": {"fitness": 3}, "link": "son_2", "link_points": 4, "needs": "son_2", "requires": {"fitness": 3}},
		{"id": "son2_trophies","object": "trophy_shelf", "label": "Ask about his trophies", "text": "He walks you through the championship game, play by play.", "link": "son_2", "link_points": 1, "needs": "son_2"},
		{"id": "son2_jersey", "object": "football_gear", "label": "Wash his practice jersey", "text": "You fish the jersey out of his bag. It smells exactly as you feared.", "effects": {"home": 3}, "link": "son_2", "link_points": 1},
	],
	"outside": [
		{"id": "yard_leave", "object": "car", "label": "Head out", "text": "", "panel": "map"},
		{"id": "yard_neighbor", "object": "", "label": "Wave to the new neighbor", "text": "A moving van is parked next door. You walk over and introduce yourself to the new neighbor, who invites you over sometime.", "sets_flag": "met_neighbor", "hidden_flag": "met_neighbor"},
		{"id": "yard_football", "object": "", "label": "Throw the football with Son 2", "text": "He runs routes across the lawn and you throw him passes until the sun gets low.", "time": true, "link": "son_2", "link_points": 3, "needs": "son_2", "social": {"fitness": 3}},
		{"id": "yard_plants", "object": "plant", "label": "Water the plants", "text": "You water the flower beds by the path.", "effects": {"home": 3}},
	],
	# TrÃ¤dgÃ¥rden: poolen, solstolarna, rabatterna och Rex, plus smÃ¥ sysslor (se Backyard).
	"backyard": [
		{"id": "garden_swim", "object": "pool", "label": "Swim laps in the pool", "text": "You swim lap after lap until your shoulders burn and your head is finally quiet.", "time": true, "relief": 3, "social": {"fitness": 4}, "fx": "swim"},
		{"id": "garden_dip", "object": "pool", "label": "Cool off with a quick dip", "text": "You slip into the water, float on your back for a minute and climb out dripping.", "relief": 2, "fx": "swim"},
		{"id": "garden_relax", "object": "sun_lounger", "label": "Sunbathe on the lounger", "text": "You oil up, stretch out on the lounger and let the sun do its work. You wake up with a warm glow.", "time": true, "periods": ["afternoon"], "relief": 5, "social": {"charm": 2}, "fx": "sun"},
		{"id": "garden_water", "object": "flower_bed", "label": "Water the plants", "text": "You drag the hose along the flower beds and give everything a good soak.", "effects": {"home": 3}, "waters_plants": true, "fx": "water"},
		{"id": "garden_fetch", "object": "dog_house", "label": "Play fetch with Rex", "text": "You whistle and Rex comes flying out the door. Twenty throws later he is still not tired. You are.", "effects": {"home": 2}, "relief": 2, "social": {"fitness": 1}, "needs_home": "dog", "calls_dog": true, "fx": "fetch"},
		{"id": "garden_weed", "object": "veg_bed", "label": "Weed the vegetable bed", "text": "You pull weeds and pick a handful of tomatoes for dinner.", "effects": {"home": 3}},
		{"id": "garden_laundry", "object": "clothesline", "label": "Hang the laundry outside", "text": "You peg the wet laundry on the line. It will smell like summer.", "effects": {"home": 3}},
	],
	"attic": [
		{"id": "attic_trunk", "object": "trunk", "label": "Look through old keepsakes", "text": "You find a stack of old love letters from your husband.", "relief": 3},
		{"id": "attic_boxes", "object": "boxes", "label": "Sort the old boxes", "text": "You sort through boxes of baby clothes and old toys.", "time": true, "effects": {"home": 10}},
	],
	"laundry": [
		{"id": "laundry_wash", "object": "washer", "label": "Do the laundry", "text": "You start a load of laundry.", "time": true, "effects": {"home": 10}},
		{"id": "laundry_fold", "object": "rack", "label": "Fold the dry clothes", "text": "You fold the clothes from the drying rack.", "effects": {"home": 3}},
	],
	"basement_hall": [
		{"id": "basement_supplies", "object": "shelf", "label": "Grab supplies", "text": "You grab a light bulb and some batteries from the shelf."},
	],
	"hobby_room": [
		{"id": "hobby_workout", "object": "gym_mat", "label": "Do a workout", "text": "You get through a full workout and feel great afterwards.", "time": true, "relief": 5, "social": {"fitness": 4}},
		{"id": "hobby_paint", "object": "easel", "label": "Paint for a while", "text": "You lose track of time painting a little landscape.", "time": true, "social": {"charm": 2, "knowledge": 2}, "gives_item": "painting"},
	],
	"storage": [
		{"id": "storage_dig", "object": "boxes", "label": "Dig through storage", "text": "You find the holiday decorations and a tent nobody has used in years.", "sets_flag": "found_marketplace"},
	],
	# --- Platserna i grannskapet (Locations). Texterna Ã¤r platshÃ¥llare. ---
	"classroom": [
		{"id": "class_prepare", "object": "whiteboard", "label": "Prepare tomorrow's lesson", "text": "You write tomorrow's lesson on the board.", "time": true, "effects": {"work": 10}, "social": {"knowledge": 3}},
		{"id": "class_grade", "object": "desk", "label": "Grade papers at your desk", "text": "You grade a stack of papers in the quiet classroom.", "time": true, "effects": {"work": 15}},
		{"id": "class_tidy", "object": "shelf", "label": "Tidy the classroom", "text": "You straighten the shelves and collect forgotten pencils.", "effects": {"work": 3}},
		{"id": "class_tutor", "object": "desk", "label": "Tutor a student after class", "text": "You go through fractions one more time until it finally clicks. The parent pays you in cash.", "time": true, "effects": {"work": 3}, "earn": 35, "earn_scale": {"knowledge": 10}, "income": "tutoring", "requires": {"knowledge": 2}, "reveal_flag": "found_tutoring"},
	],
	"teachers_lounge": [
		{"id": "lounge_chat", "object": "table", "label": "Chat with colleagues", "text": "You catch up on school gossip over coffee.", "time": true, "effects": {"work": 5}, "social": {"charm": 4}},
		{"id": "lounge_meeting", "object": "table", "label": "Lead the staff meeting", "text": "You run the meeting with a plan nobody can argue with. The principal takes notes.", "time": true, "effects": {"work": 20}, "social": {"charm": 2}, "requires": {"knowledge": 4, "charm": 2}},
		{"id": "lounge_coffee","object": "counter", "label": "Grab a coffee", "text": "The staff room coffee is terrible, but it's coffee."},
		{"id": "lounge_board", "object": "", "label": "Read the notice board", "text": "Between the fire drill schedule and a lost cardigan: three notes from parents looking for a tutor. Paid.", "sets_flag": "found_tutoring", "hidden_flag": "found_tutoring"},
	],
	"neighbor_living": [
		{"id": "neighbor_coffee", "object": "coffee_table", "label": "Have coffee with the neighbor", "text": "You sit down for coffee and hear all about the move. It's nice to have someone to talk to. (Placeholder scene.)", "time": true, "relief": 3, "social": {"charm": 4}, "link": "neighbor", "link_points": 2, "needs": "neighbor"},
		{"id": "neighbor_wine", "object": "coffee_table", "label": "Stay for a glass of wine", "text": "Coffee turns into wine, and the conversation turns personal. (Placeholder scene.)", "time": true, "relief": 5, "social": {"charm": 2}, "periods": ["evening"], "requires": {"attractiveness": 4, "charm": 3}, "link": "neighbor", "link_points": 3, "needs": "neighbor"},
		{"id": "neighbor_help","object": "boxes", "label": "Help unpack boxes", "text": "You help unpack a few boxes and learn a bit more about your new neighbor, who travels a lot for work and hates leaving the house empty.", "time": true, "effects": {"home": 3}, "link": "neighbor", "link_points": 2, "needs": "neighbor", "sets_flag": "found_house_sitting"},
		{"id": "neighbor_sit", "object": "", "label": "Look after the house", "text": "You water the plants, bring in the mail and feed the cat. An envelope with your name on it waits on the counter.", "time": true, "earn": 40, "income": "house_sitting", "link": "neighbor", "link_points": 1, "reveal_flag": "found_house_sitting"},
	],
	"gym": [
		{"id": "gym_run", "object": "treadmill", "label": "Run on the treadmill", "text": "You put on a podcast and run until your legs burn.", "time": true, "relief": 5, "social": {"fitness": 5}, "cost": 12, "waived_by": "gym_visit"},
		{"id": "gym_weights", "object": "weight_bench", "label": "Lift weights", "text": "You work through a full strength session.", "time": true, "relief": 5, "social": {"fitness": 5}, "cost": 12, "waived_by": "gym_visit"},
		{"id": "gym_coach", "object": "gym_mat", "label": "Coach the beginners' class", "text": "The regular trainer is sick and asks you to step in. The class actually applauds at the end, and the manager slips you an envelope.", "time": true, "relief": 5, "social": {"charm": 3, "fitness": 2}, "requires": {"fitness": 4}, "earn": 50, "income": "coaching", "sets_flag": "found_coaching"},
		{"id": "gym_stretch","object": "gym_mat", "label": "Stretch", "text": "You stretch out the stiffness from a day of standing in class.", "social": {"fitness": 1}},
	],
	"yoga_studio": [
		{"id": "yoga_class", "object": "gym_mat", "label": "Join a yoga class", "text": "An hour of slow breathing. You leave feeling lighter than you have in weeks.", "time": true, "relief": 8, "social": {"fitness": 4, "charm": 1}, "cost": 18},
	],
	# KÃ¶pcentret: gÃ¥ngarna och butikerna.
	"center_court": [
		{"id": "court_directory", "object": "directory", "label": "Read the mall directory", "text": "West: the grocery store, the restaurant and the cafÃ©. East: the clothing boutique, the hair salon and the bookstore. You are here, by the fountain."},
		{"id": "court_fountain", "object": "fountain", "label": "Toss a coin in the fountain", "text": "You close your eyes and make a wish. You're not telling anyone what it was.", "relief": 2, "cost": 1},
		{"id": "court_people", "object": "bench", "label": "Sit and people-watch", "text": "Teenagers on a first date, a toddler negotiating for a pretzel, a couple holding hands at sixty. You smile.", "social": {"charm": 1}},
	],
	"grocery": [
		{"id": "grocery_shop", "object": "store_shelf", "label": "Do the weekly shopping", "text": "You fill the cart with everything on the list â€“ and remember the coffee.", "time": true, "effects": {"home": 15}, "completes": "coffee", "cost": 150, "groceries": true},
		{"id": "grocery_snack", "object": "checkout", "label": "Buy snacks for the boys", "text": "You grab chips and energy drinks. The boys will be thrilled.", "effects": {"home": 3}, "cost": 15},
	],
	"boutique": [
		{"id": "boutique_browse", "object": "clothes_rack", "label": "Browse the new collection", "text": "You try on a few things and find a dress you can't stop thinking about.", "time": true, "relief": 5, "social": {"charm": 3}},
		{"id": "boutique_model", "object": "mirror_wall", "label": "Model the new collection", "text": "The owner asks if you would model the new collection for the shop window. People stop on the sidewalk to look. (Placeholder scene.)", "time": true, "relief": 10, "social": {"charm": 3}, "requires": {"attractiveness": 4}, "earn": 120, "income": "modeling", "sets_flag": "found_modeling"},
		{"id": "boutique_mirror","object": "mirror_wall", "label": "Check yourself in the mirror", "text": "Not bad for a mom of two teenagers.", "social": {"charm": 1}},
	],
	# FrisÃ¶rsalongen Ã¤r stÃ¤llet fÃ¶r frisyr och hÃ¥rfÃ¤rg (panelen "salon", se Economy.SALON).
	"salon": [
		{"id": "salon_book", "object": "salon_station", "label": "Book a hair appointment", "text": "", "panel": "salon", "time": true},
		{"id": "salon_magazines", "object": "coffee_table", "label": "Flip through the style magazines", "text": "You dog-ear a few looks you would never dare to try. Or would you?", "social": {"charm": 1}},
	],
	"cafe": [
		{"id": "cafe_latte", "object": "espresso_bar", "label": "Order a latte", "text": "You take your latte to a corner seat and let the hum of the mall wash over you.", "relief": 2, "cost": 5},
		{"id": "cafe_grade", "object": "table", "label": "Grade papers over a latte", "text": "Nobody here needs anything from you. You get through the whole stack in record time.", "time": true, "effects": {"work": 18}, "cost": 5},
	],
	"bookstore": [
		{"id": "books_browse", "object": "shelf", "label": "Browse the new releases", "text": "You read the first pages of three novels and the last page of one. Don't tell anyone.", "social": {"knowledge": 2}},
		{"id": "books_read", "object": "armchair", "label": "Read in the armchair corner", "text": "One chapter turns into four. The staff pretends not to notice.", "time": true, "relief": 3, "social": {"knowledge": 4}},
	],
	"restaurant": [
		{"id": "restaurant_date", "object": "table", "label": "Dinner date with your husband", "text": "You share a bottle of wine and talk like you used to.", "time": true, "relief": 15, "link": "husband", "link_points": 3, "needs_home": "husband", "periods": ["evening"], "social": {"charm": 3}, "cost": 90},
		{"id": "restaurant_lunch", "object": "table", "label": "Grab a bite alone", "text": "You enjoy a quiet meal with nobody asking you for anything.", "time": true, "cost": 20},
	],
	"park": [
		{"id": "park_walk", "object": "path", "label": "Go for a walk", "text": "You walk the loop around the park and watch the ducks.", "time": true, "relief": 3, "social": {"fitness": 3}},
		{"id": "park_read", "object": "bench", "label": "Read on a bench", "text": "You read a few chapters in the sun.", "time": true, "social": {"knowledge": 4}},
		{"id": "park_ducks", "object": "pond", "label": "Feed the ducks", "text": "The ducks are very enthusiastic about your leftover bread."},
		{"id": "park_market_browse", "object": "path", "label": "Look at the market stalls", "text": "Local artists sell paintings by the pond. Some of them areâ€¦ not better than yours. A woman tells you anyone can rent a table on weekends.", "weekdays": [5, 6], "sets_flag": "found_art_market", "hidden_flag": "found_art_market"},
		{"id": "park_sell_painting", "object": "bench", "label": "Sell a painting at the art market", "text": "You set up a little easel by the path. Someone stops, looks for a long time, and buys it.", "time": true, "weekdays": [5, 6], "needs_item": "painting", "earn": 30, "earn_scale": {"charm": 15, "knowledge": 5}, "income": "art_market", "social": {"charm": 1}, "reveal_flag": "found_art_market"},
	],
}


## Rummets val: de fasta handlingarna plus kÃ¶p och fÃ¶rsÃ¤ljningar frÃ¥n Economy, utan
## dem som Ã¤r dolda just nu (redan gjort, kÃ¶pt, sÃ¥lt eller inte hittat Ã¤nnu).
static func for_room(room_id: String) -> Array:
	var actions: Array = Requests.actions_for_room(room_id) + ACTIONS.get(room_id, []) + Economy.actions_for_room(room_id) + Curtains.actions_for_room(room_id)
	return actions.filter(func(action: Dictionary) -> bool:
		if action.get("hidden_flag", "") != "" and GameState.has_flag(action["hidden_flag"]):
			return false
		if action.get("reveal_flag", "") != "" and not GameState.has_flag(action["reveal_flag"]):
			return false
		if action.get("buys", "") in GameState.owned or action.get("sells", "") in GameState.sold:
			return false
		if action.has("subscribe") and action["subscribe"] in GameState.subscriptions:
			return false
		if action.has("unsubscribe") and not action["unsubscribe"] in GameState.subscriptions:
			return false
		return true)


## Korta taggar fÃ¶r ett val: tid, mÃ¤tare, egenskaper och relation, t.ex.
## "takes time Â· +Home Â· +Fitness Â· â™¥ Son 1".
static func tags(action: Dictionary) -> String:
	var parts: Array[String] = []
	if action.get("panel", "") == "map":
		parts.append("opens the map")
	if action.get("panel", "") == "salon":
		parts.append("from " + Economy.format(Economy.salon_min_price()))
	if action.get("fulfills", "") != "":
		var owes: int = Requests.find_type(GameState.requests.get(action["fulfills"], {}).get("type", "")).get("owes", 0)
		parts.append("â˜… Request" + (" Â· owes you %d" % owes if owes > 0 else ""))
	if action.get("delegates", "") != "":
		parts.append("no time for you")
	if action.get("completes", "") != "" and GameState.quests.get(action["completes"], "") == "active":
		parts.append("âœ“ " + PhoneData.QUESTS[action["completes"]]["title"])
	parts.append_array(Backyard.tags(action))
	if action.get("time", false):
		parts.append("takes time")
	var cost := GameState.action_cost(action)
	if cost > 0:
		parts.append(Economy.format(-cost))
	elif action.has("cost"):
		parts.append("free with membership")
	if action.has("earn"):
		parts.append("+" + Economy.format(GameState.action_earnings(action)))
	for key in action.get("effects", {}):
		if action["effects"][key] > 0:
			parts.append("+" + GameState.STAT_NAMES[key])
	for key in action.get("social", {}):
		parts.append("+" + SocialStats.STATS[key]["name"])
	if action.get("lust", 0.0) > 0.0:
		parts.append("♥ +%.0f" % action["lust"])
	if action.get("link", "") != "":
		parts.append("â™¥ " + GameState.CHARACTERS[action["link"]]["name"])
	return "  Â·  ".join(parts)







