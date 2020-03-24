# CONFIGURATION SECTION.
set our_chan { "##tryingstuffStayout" }

source scripts/viech/viechDB.tcl
package require sqlite3
set dbname "scripts/viech/viech.db"

## userfile flags -|- everyone
set tryflags -|- 

bind pub - !viech viech

# nick - the person's nickname
# uhost - the person's user@host
# hand - the person's bothandle (if he is a valid user)
# chan - the channel this event happened on
# text - the text the person said (not counting the trigger word)

proc viech {nick uhost hand chan text } {
	global our_chan
	if { [lsearch $our_chan $chan ] == -1 } {
		putserv "privmsg $chan :Sorry, wir bauen gerade das Dojo um. Bitte schreibs dir auf und loggs, wenn wir wieder da sind."
		return 0
	}
	set theWords [regexp -all -inline {\S+} $text]
	set anzahl [lindex $theWords 0]
	set uebung [lindex $theWords 1]
	# Help
	if {$anzahl == "help" ||
		$anzahl == "hilfe" ||
		$anzahl == "" } then {
		putserv "privmsg $chan :$nick !viech-syntax: !viech Anzahl Übung (Abstände nicht vergessen)"
		putserv "privmsg $chan :$nick Übungen: kz-Klimmzüge, ls-Liegestütz, kb-Kniebeugen"
		putserv "privmsg $chan :$nick !viech stats zeigt dir deine Statistik."
		return 0 
	}
	if {$anzahl == "register"} {
		global dbname
		sqlite3 db $dbname
		set out [dbRegister $uhost]
		db close
		putserv "privmsg $chan :$nick erfolgreich registriert!"
		return 1
	}
	if {$anzahl == "stats"} {
		# TODO: Let me look at other stats
		global dbname
		sqlite3 db $dbname
		set out [dbRead $uhost]
		db close
		putserv "privmsg $chan :$nick: $out"
		return 1
	}
	# Übung
	switch -glob [string tolower $uebung ] {
		"kz" -
		"klimmzüge" {
			lset theWords 1 "Klimmzüge"
			lset uebung "klimmzuege"
		}
		"ls" -
		"liegestütz" {
			lset theWords 1 "Liegestütz"
			lset uebung "liegestuetz"
		}
		"kb" -
		"kniebeugen" {
			lset theWords 1 "Kniebeugen"
			lset uebung "kniebeugen"
		}
		default {
			lset theWords 1 "unbekannte Übungen"
			lset uebung 0
		}
	}
	# Anzahl
	switch [string index $anzahl 0] {
		1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 - 0 -
		"+" {
			if {$uebung == 0} {
				#TODO Used same msg twice -> beautify!
				putserv "privmsg $chan :$nick hat $theWords gemacht! (registriere dich mit !viech register)"
				return 1
				
			}
		} 
		"-" {
			putserv "privmsg $chan :Aha! Da wollte $nick wohl ein bisserl schummeln! ($text)"
		}
		default {
				putserv "privmsg $chan :$nick da kennt sich ja keiner aus mit ($text)"
				putserv "privmsg $chan :$nick du brauchst !viech hilfe"
				return 1
		}
	}
	global dbname
	sqlite3 db $dbname
	set out [dbWrite $uhost $uebung $anzahl]
	if {$out == 0} {
		putserv "privmsg $chan :$nick hat $theWords gemacht! (registriere dich mit !viech register)"
		return 1
	} else {
		set out [dbRead $uhost]
		db close
	}
	putserv "privmsg $chan :$nick hat $theWords gemacht!"
	return 1
}

# TODO Ordnung der Überprüfungen von anzahl und befehl Sortieren
# TODO Multilang (Antworten aussondern)
# TODO add sports
# TODO find a way to whitelist all channels
