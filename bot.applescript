-- speed limits
set summonAttemptMax to 2
set summonAttemptDelay to 9
set serverRateLimit to 6

-- pixel targets
set spawnLocX to 392
set spawnLocY to 690 -- set to a low point so it only triggers on fresh spawns not previous

-- captcha detection
set captchaLocX to 0
set captchaLocYOffset to 50 -- set to the minimum height to flag as a possible captcha
set captchaLocYMax to 1280 --screen height
set captchaColor to "000000"

-- pokemon rarity color codes
set common to "0d4eff"
set uncommon to "2eb3ec"
set rare to "f78b00"
set superrare to "f8f600"
set legendary to "9c00ff"
set shiny to "fb99cf"


tell application "Firefox Developer Edition" to activate

repeat
	--attempt to summon
	set readyToCatch to false
	repeat summonAttemptMax times
		if readyToCatch is true then exit repeat
		sendRequest(";p")
		--recheck for summon or resummon if rate limited
		repeat serverRateLimit times
			delay 1
			set pokemon to getPixel(spawnLocX, spawnLocY)
			if pokemon is in {common, uncommon, rare, superrare, legendary, shiny} then
				set readyToCatch to true
				exit repeat
			end if
		end repeat
	end repeat
	if readyToCatch is false then showError("Unable to detect summoned pokemon?")
	
	--ball "AI" lol
	if pokemon is in {common, uncommon} then
		sendRequest("pb")
	else if pokemon is rare then
		sendRequest("gb")
	else if pokemon is superrare then
		sendRequest("ub")
	else if pokemon is in {legendary, shiny} then
		beep
		sendRequest("mb")
		delay 1
		sendRequest("prb")
		delay 1
		sendRequest("ub")
	else -- error
		beep 5
		showError("Unable to detect pokemon scarcity?")
		error number -128 --exit
	end if
	
	-- global cooldown
	set cooldown to random number from summonAttemptDelay to summonAttemptDelay + 2
	delay cooldown
end repeat

on getPixel(x, y)
	return do shell script "screencapture -R" & x & "," & y & ",1,1 -t bmp $TMPDIR/test.bmp && xxd -p -l 3 -s 54 $TMPDIR/test.bmp | sed 's/\\(..\\)\\(..\\)\\(..\\)/\\3\\2\\1/'"
end getPixel

on sendRequest(req)
	tell application "System Events"
		keystroke req
		key code 76
	end tell
end sendRequest

on showError(message)
	tell application "Script Editor" to activate
	display dialog message
	tell application "Firefox Developer Edition" to activate
end showError
