#!/usr/bin/tclsh
proc dbRegister {name} {
        global dbname
        set query "INSERT INTO names (name) VALUES (\"$name\");"
        set out [db eval $query]
        return $out
}
proc dbWrite {name sport amount} {
        global dbname
        set nameID [db eval "SELECT ID FROM names WHERE name is \"$name\";"]
	if {$nameID == ""} {
		putlog "Username $name not found!"
		return 0
	}
        set sportID [db eval "SELECT ID FROM sports id WHERE sport is \"$sport\";"]
        set query "INSERT INTO viech \(nameID, sportID, amount\) VALUES \($nameID, $sportID, $amount\);"
        set out [db eval $query]
        return $out
}
proc dbRead { name {givenTime "" } } {
	if { [ checkName $name ] == 1 } {
		if {$name == "all" } {
			 # TODO DEAD
			set query "SELECT name, sport, amount FROM viech, names, sports WHERE viech.nameID = names.ID AND viech.sportID = sports.ID"
		} else {
			set query "SELECT sport, sum\(amount\) FROM viech, names, sports WHERE names.name is \"$name\" AND viech.nameID = names.ID AND viech.sportID = sports.ID"
		}
		append query [timeWindow $givenTime]
		append query " GROUP BY sport"
		append query ";"
		set out [db eval $query]
		putlog $out
		return $out
	} else {
		return 0
	}
}

proc checkName { name } {
	append query "SELECT * FROM names WHERE name = \"" $name "\";"
	set out [db eval $query]
	if { [string length $out] > 0 } {
		return 1
	} else {
		return 0
	}
}

proc timeWindow {theTime} {
	switch $theTime {
		"day"   { set t %Y-%m-%d }
		"week"  { set t %Y-%W }
		"month" { set t %Y-%m }
		"year"  { set t %Y }
		"total" { set t "" }
		default { set t "" }
	}
	set out " AND strftime\('$t',timestamp\) IS strftime\('$t','now'\)"
	return $out
}

# set query "SELECT name, sport, sum\(amount\) FROM viech, names, sports WHERE names.name LIKE \"%$name%\" AND viech.nameID = names.ID AND viech.sportID = sports.ID GROUP BY sport;"
