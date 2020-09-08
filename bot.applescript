-- pokemon rarity color codes
set common to "0d4eff"
set uncommon to "2eb3ec"
set rare to "f78b00"
set superrare to "f8f600"
set legendary to "9c00ff"
set shiny to "fb99cf"

set summonAttemptMax to 2
set summonAttemptDelay to 9
set serverRateLimit to 6

tell application "Firefox Developer Edition" to activate

repeat 100 times
	
	set readyToCatch to false
	set summonAttempt to 0
	
	repeat until readyToCatch is true or summonAttempt is summonAttemptMax
		
		--attempt to summon
		tell application "System Events"
			keystroke ";p"
			key code 76
		end tell
		set summonAttempt to summonAttempt + 1
		
		--check for summon or resummon if rate limited
		set serverResponseWaitTimer to 0
		
		repeat until readyToCatch is true or serverResponseWaitTimer ≥ serverRateLimit
			delay 1
			--get the color at 393 x 690, (old: 559) set to a low point so it only triggers on fresh spawns not previous
			set pokemon to do shell script "screencapture -R393,690,1,1 -t bmp $TMPDIR/test.bmp && xxd -p -l 3 -s 54 $TMPDIR/test.bmp | sed 's/\\(..\\)\\(..\\)\\(..\\)/\\3\\2\\1/'"
			if pokemon is in {common, uncommon, rare, superrare, legendary, shiny} then
				set readyToCatch to true
			else
				set serverResponseWaitTimer to serverResponseWaitTimer + 1
			end if
		end repeat
		
	end repeat
	
	--ball "AI" lol
	if pokemon is in {common, uncommon} then
		tell application "System Events" to keystroke "pb"
	else if pokemon is rare then
		tell application "System Events" to keystroke "gb"
	else if pokemon is superrare then
		tell application "System Events" to keystroke "ub"
	else if pokemon is in {legendary, shiny} then
		beep
		tell application "System Events"
			keystroke "mb"
			key code 76
		end tell
		delay 1
		tell application "System Events"
			keystroke "prb"
			key code 76
		end tell
		delay 1
		tell application "System Events" to keystroke "ub"
	else -- error
		beep 5
		error number -128 --exit
	end if
	
	tell application "System Events" to key code 76
	
	set cooldown to random number from summonAttemptDelay to summonAttemptDelay + 2
	delay cooldown
	
end repeat
