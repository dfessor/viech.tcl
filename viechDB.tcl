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
proc dbRead {name} {
        if {$name == "all" } {
                set query "SELECT name, sport, amount FROM viech, names, sports WHERE viech.nameID = names.ID AND viech.sportID = sports.ID;"
        } else {
                set query "SELECT sport, sum\(amount\) FROM viech, names, sports WHERE names.name is \"$name\" AND viech.nameID = names.ID AND viech.sportID = sports.ID GROUP BY sport;"
        }
        set out [db eval $query]
        return $out
}

# set query "SELECT name, sport, sum\(amount\) FROM viech, names, sports WHERE names.name LIKE \"%$name%\" AND viech.nameID = names.ID AND viech.sportID = sports.ID GROUP BY sport;"
