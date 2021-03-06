# CONFIGURATION SECTION.

# channel names for privacy reasons: A variable called "our_chan" containing a list of channel names
source scripts/viech/viechChan.tcl

source scripts/viech/viechDB.tcl
package require sqlite3
set dbname "scripts/viech/viech.db"

## userfile flags -|- everyone
set tryflags -|- 


# nick - the person's nickname
# uhost - the person's user@host
# hand - the person's bothandle (if he is a valid user)
# chan - the channel this event happened on
# text - the text the person said (not counting the trigger word)

proc sendErrorMsg { nick chan text } {
	# TODO DOESN'T PRINT
	append firstMsg "privmsg " $chan " :" $nick " da kennt sich ja keiner aus mit \(" $text "\)"
	append secondMsg "privmsg " $chan " :" $nick " du brauchst !viech hilfe"
	putserv $firstMsg
	putserv $secondMsg
	return 1
}

proc viech {nick uhost hand chan text } {
	global our_chan
	# global sendErrorMsg

	# Check if $chan is in $our_chan
	if { [lsearch $our_chan $chan ] == -1 } {
		putserv "privmsg $chan :Sorry, wir bauen gerade das Dojo um. Bitte schreibs dir auf und loggs, wenn wir wieder da sind."
		return 1
	}

	# Load Input as list
	set theInput [regexp -all -inline {\S+} $text]

	# Make input small
	if { $theInput == "" } {
		set theWords ""
	} else {
		for {set index 0} {$index < [llength $theInput]} {incr index} {
			lappend theWords [string tolower [lindex $theInput $index]]
		}
	}

	# Check first argument
	switch -glob [lindex $theWords 0] {
		"help" - "hilfe" - "" {
			putserv "privmsg $chan :$nick !viech-syntax: !viech Anzahl Übung (Abstände nicht vergessen)"
			putserv "privmsg $chan :$nick Übungen: kz-Klimmzüge, ls-Liegestütz, kb-Kniebeugen,su-Situps"
			putserv "privmsg $chan :$nick !viech stats total(default)/day/week/month/year zeigt dir deine Statistik."
			return 1 
		}
		"register" {
			global dbname
			sqlite3 db $dbname
			set out [dbRegister $uhost]
			db close
			putserv "privmsg $chan :$nick erfolgreich registriert!"
			return 1
		}
		"stats" {
			global dbname
			sqlite3 db $dbname
			set out [dbRead $uhost [lindex $theWords 1]]
			db close
			if { $out == 0 } {
				putserv "privmsg $chan :$nick nicht registriert. Registriere mit !viech register"
			} elseif { $out == "" } {
				putserv "privmsg $chan :$nick hat heut noch nichts gemacht. Faulpelz..."
				return 1
			} else {
				putserv "privmsg $chan :$nick $out"
			}
				return 1
		}
		default {
		}
	}
	# Try to understand FIRST argument (=reps), assuming user wants to write DB
	set firstArgument [lindex $theWords 0]
	set fAL [string index $firstArgument 0]
	set negativeNumber 0
	
	## find out if exercises are positive or negative
	switch -glob $fAL {
		"+" - 0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 { 
			# All good
			set Rainbowbunnies ON
		}
		"-" {
			set negativeNumber 1
		}
		default {
			sendErrorMsg $nick $chan $text
			return 0
		}
	}
	## Find out how many reps were made
	if {[string length $firstArgument] > 1 } {
		for {set index 1} {$index < [string length $firstArgument] } {incr index} {
			switch -glob [string index $firstArgument $index] {
				0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
					# All good
					set reps $firstArgument
				}
				default { 
					sendErrorMsg $nick $chan $text
				}
			}
		}
	} else {
		set reps $firstArgument
	}

	# Try to understand SECOND argument (=exercise)
	set secondArgument [lindex $theWords 1]
	switch -glob $secondArgument {
		"kz" -
		"klimmzüge" {
			lset theWords 1 "Klimmzüge"
			set exercise "klimmzuege"
		}
		"ls" -
		"liegestütz" {
			lset theWords 1 "Liegestütz"
			set exercise "liegestuetz"
		}
		"kb" -
		"kniebeugen" {
			lset theWords 1 "Kniebeugen"
			set exercise "kniebeugen"
		}
		"su" -
		"situps" {
			lset theWords 1 "Situps"
			set exercise "situps"
		}
		default {
			lset theWords 1 "unbekannte Übungen"
			set exercise 0
		}
	}

	# Writing to DB
	global dbname
	sqlite3 db $dbname
	set out [dbWrite $uhost $exercise $reps]

	## Make output
	if { $negativeNumber == 1 } {
			putserv "privmsg $chan :Aha! Da wollte $nick wohl ein bisserl schummeln! ($text)"
	}
	append msg "privmsg $chan :$nick hat $reps $exercise gemacht!"
	# TODO What is the output, when a user exists vs when he doesn't exist!
	if {$out == 0} {
		append msg " (registriere dich mit !viech register)"
	} else {
		set out [ dbRead $uhost ]
		db close
	}
	putserv $msg
	return 1
}
		
if 0 {
OUTPUTS:
	putserv "privmsg $chan :$nick hat $theWords gemacht!"
	putserv "privmsg $chan :$nick hat $theWords gemacht! (registriere dich mit !viech register)"
	putserv "privmsg $chan :$nick da kennt sich ja keiner aus mit ($text)"
	putserv "privmsg $chan :$nick du brauchst !viech hilfe"
}

# TODO Ordnung der Überprüfungen von anzahl und befehl Sortieren
# TODO Multilang (Antworten aussondern)
# TODO find a way to whitelist all channels
# TODO best day/week/month/year
# TODO test.tcl
# TODO when user is registered, but didn't log anything yet output for !viech stats is as if not registerd
# TODO stats day doesn't work
