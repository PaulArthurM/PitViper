



awk -F ',' '{print ">"$1"\n"$2}' $1 > $2