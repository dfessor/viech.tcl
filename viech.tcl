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

proc sendErrorMsg {} {
	set errorMsg {
		putserv "privmsg $chan :$nick da kennt sich ja keiner aus mit ($text)"
		putserv "privmsg $chan :$nick du brauchst !viech hilfe"
	}
	foreach msg $errorMsg {
		msg
	}
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
			set out [dbRead $uhost ]
			db close
			putserv "privmsg $chan :$nick erfolgreich registriert!"
			return 1
		}
		default {
			sendErrorMsg
		}
	}
	# Try to understand FIRST argument (=reps), assuming user wants to write DB
	set firstArgument [lindex $theWords 0]
	set fAL [string index $firstArgument 0]
	set negativeNumber 0
	
	## find out if exercises are positive or negative
	switch -glob $fAL {
		"+" - 0 - 1 - 2 - 3 - 4 - 5 - 6 - 7- 8 - 9 { 
			# All good
		}
		"-" {
			set negativeNumber 1
		}
		default {
			sendErrorMsg
		}
	}
	## Find out how many reps were made
	for {set index 1} {$index < [string length $firstArgument] } {incr index} {
		switch -glob [string index $firstArgument $index] {
			0 - 1 - 2 - 3 - 4 - 5 - 6 - 7- 8 - 9 {
				# All good
			set reps $firstArgument
			}
			default { 
				sendErrorMsg
			}
		}
	}

	# Try to understand SECOND argument (=exercise)
	set secondArgument [lindex $theWords 1]
	switch -glob $secondArgument {
		"kz" -
		"klimmzüge" {
			lset theWords 1 "Klimmzüge"
			lset exercise "klimmzuege"
		}
		"ls" -
		"liegestütz" {
			lset theWords 1 "Liegestütz"
			lset exercise "liegestuetz"
		}
		"kb" -
		"kniebeugen" {
			lset theWords 1 "Kniebeugen"
			lset exercise "kniebeugen"
		}
		"su" -
		"situps" {
			lset theWords 1 "Situps"
			lset exercise "situps"
		}
		default {
			lset theWords 1 "unbekannte Übungen"
			lset exercise 0
		}
	}

	# Writing to DB
	global dbname
	sqlite3 db $dbname
	set out [dbWrite $uhost $exercise $reps]

	## Make output
	append msg "privmsg $chan : $nick hat $reps $theWords gemacht!"
	# TODO What is the output, when a user exists vs when he doesn't exist!
	if {$out == 0} {
		append msg " (registriere dich mit !viech register)"
		putserv $msg
	} else {
		set out [ dbRead $uhost ]
		db close
	}
	return 1
}
		
if 0 {
	# OLD STATS: Doesn't have day/week/month/year implemented yet
	"stats" {
		# TODO
		global dbname
		sqlite3 db $dbname
		set out [dbRead $uhost $uebung]
		db close
		putserv "privmsg $chan :$nick: $out"
		return 1
	}
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
