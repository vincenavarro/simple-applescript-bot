--Time settings
set huntingEnabled to true
set fishingEnabled to true
set huntingCooldown to 7 --Delay time set by bot.
set fishingCooldown to 20 --Delay time set by bot.
set latencyOffset to 0.5 --Base adjustment for discord lag
set serverRateLimit to 6
global huntingEnabled, fishingEnabled, huntingCooldown, fishingCooldown
global latencyOffset, serverRateLimit

--Reqests
set hunt to ";p"
set fish to ";f"
set captchaTriggers to {hunt, fish}
global captchaTriggers

--Messages
set msgCaptcha to "captcha"
set msgWait to "please wait"
set msgWildpokemon to "A wild Pokémon appeared!"
set msgStreak to {"Uncommon streak: 6", "Uncommon streak: 7", "Uncommon streak: 8", "Uncommon streak: 9", "Common streak: 13", "Common streak: 14"}
set msgWildcaught to "Congratulations, "
set msgWildescaped to " used a"
set msgFishingpokemon to "A wild Pokemon appeared!"
set msgFishingpull to "Oh! A bite!"
set msgFishingnothing to "Not even a nibble"
global msgCaptcha, msgWait, msgWildpokemon, msgWildcaught, msgStreak
global msgWildescaped, msgFishingpokemon, msgFishingpull, msgFishingnothing

--Rarity
set msgRCommon to "Common streak"
set msgRUncommon to "Uncommon streak"
set msgRRare to "Rare streak"
set msgRSuper to "Super Rare streak"
set msgRLegendary to "Legendary streak"
set msgRShiny to "Shiny streak"
set msgRGolden to "Golden streak" --Hypothetically...
global msgRCommon, msgRUncommon, msgRRare, msgRSuper
global msgRLegendary, msgRShiny, msgRGolden

--Working variables
set lastRequest to ""
set botStatus to ""
set lastHunting to huntingCooldown
set lastFishing to fishingCooldown
global lastRequest, botStatus, lastHunting, lastFishing

tell application "Google Chrome" to activate
delay 3

repeat

	--Attempt to catch wild pokenmon
	if huntingEnabled and getTime() ≥ (lastHunting + huntingCooldown + latencyOffset) then
		log "Time between hunting: " & (getTime() - lastHunting)
		sendRequest(hunt)
		waitFor({msgWildpokemon})
		if botStatus contains msgWildpokemon then throwPokeball()
		set lastHunting to getTime()
	end if

	delay latencyOffset

	--Throw in some fishing if enabled
	if fishingEnabled and getTime() ≥ (lastFishing + fishingCooldown + latencyOffset) then
		log "Time between fishing: " & (getTime() - lastFishing)
		set offsetTimer to getTime()
		sendRequest(fish)
		waitFor({msgFishingpull, msgFishingnothing})
		if botStatus contains msgFishingpull then
			--TODO: Make this less hacky, too slow otherwise
			tell application "System Events" to keystroke "pull"
			tell application "System Events" to key code 76
			waitFor({msgFishingpokemon})
			if botStatus contains msgFishingpokemon then throwPokeball()
		else
			--Delete "pull"
			tell application "System Events"
				repeat 4 times
					key code 51 using {command down}
					delay (random number from 0.05 to 0.25)
				end repeat
			end tell
		end if
		set lastFishing to getTime()
	end if

	delay latencyOffset
end repeat

on getTime()
	return (time of (current date))
end getTime

on throwPokeball()
	--Throw "AI"
	delay 0.5
	if containsFromList(botStatus, {msgRCommon, msgRUncommon}) then
		if isOnStreak(botStatus) then
			sendRequest("gb")
		else
			sendRequest("pb")
		end if
	else if botStatus contains msgRSuper then
		sendRequest("ub")
	else if botStatus contains msgRRare then
		sendRequest("gb")
	else if botStatus contains msgRLegendary then
		beep
		sendRequest("prb")
	else if containsFromList(botStatus, {msgRShiny, msgRGolden, "Golden", "Shiny", "Kyogre", "Suicune"}) then
		--TODO: Needs work to better accomodate fishing rares
		beep
		sendRequest("mb")
	else
		--Fishing or unable to find rarity?
		sendRequest("pb")
	end if
	waitFor({msgWildcaught, msgWildescaped})
end throwPokeball

on updateBotStatus()
	tell application "Google Chrome"
		set botStatus to execute front window's active tab javascript "document.querySelector('#watchbot').innerText"
	end tell
	if botStatus is missing value then
		display dialog "Error getting text. Did you forget to inject?"
		error number -128 --exit
	end if
end updateBotStatus

on sendRequest(req)
	--Simulate typing with delay
	tell application "Google Chrome" to activate
	repeat with theChar in req
		tell application "System Events" to keystroke theChar
		delay (random number from 0.05 to 0.25)
	end repeat
	delay (random number from 0.05 to 0.25)
	tell application "System Events" to key code 76

	--Save requerst incase need to repeat it
	set lastRequest to req
end sendRequest

on checkForCaptcha()
	--Check for captcha and beep serverRateLimit seconds to remind
	set hasCaptcha to false

	--Initial quick check
	if botStatus contains msgCaptcha then
		set hasCaptcha to true
		beep 3
	end if

	--Gate loop
	repeat while hasCaptcha is true
		repeat serverRateLimit times
			updateBotStatus()
			if botStatus does not contain msgCaptcha then
				set hasCaptcha to false
				delay 1
				sendRequest(lastRequest) --Repeat previous attempt
				exit repeat
			end if
			delay 1
		end repeat
		if hasCaptcha is false then exit repeat
		--beep 3
	end repeat
end checkForCaptcha

on isOnStreak(pokemon)
	--Streak box hunter
	--TODO: Clean up this mess...
	if containsFromList(pokemon, msgStreak) then
		return true
	end if
	return false
end isOnStreak

on waitFor(wordsToWaitFor)
	--Wait for a response before proceeding
	repeat serverRateLimit * 4 times
		updateBotStatus()
		if botStatus contains msgWait then --Time to slow down
			set latencyOffset to latencyOffset + 0.25
			-- delay serverRateLimit TODO: Grab requested wait time from message
			-- sendRequest(lastRequest)
		end if
		if containsFromList(lastRequest, captchaTriggers) then checkForCaptcha()
		if containsFromList(botStatus, wordsToWaitFor) then exit repeat
		delay 0.25
	end repeat
end waitFor

on containsFromList(textToCompare, listOfTerms)
	--Checks to see if an array of items is in text
	--Why isn't this a built in function?
	--Example:
	--set coolAnimals to {"dogs", "cats"}
	--set claim to "I love dogs."
	--if containsFromList(claim, coolAnimals} then beep

	set answer to false
	repeat with i from 1 to count listOfTerms
		if textToCompare contains item i of listOfTerms then
			set answer to true
			exit repeat
		end if
	end repeat
	return answer
end containsFromList
