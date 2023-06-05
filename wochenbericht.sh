#!/bin/bash

# Copyright © 2022 Markus Hanetzok <markus@hanetzok.net>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file for more details.

### VARIABLES
# Determine the locations the script needs to know
script_dir="$(dirname $(realpath $0))"
tex_dir="$script_dir/tex"
out_dir="$script_dir/out"
user_data="$script_dir/user.csv"

### FUNCTIONS

tex_cmd() {
  pdflatex -output-directory "$out_dir" -jobname "$1" "$2"
  rm "$out_dir"/*.aux "$out_dir"/*.log
}

dialog_helper() {
  dialog --"$1" "$2" 0 0 --output-fd 1
}

error() {
    clear
    printf "ERROR: $1\n"
    exit 1
}

read_data() { # Get the values from user.csv
  while IFS=, read -r key value; do
    case "$key" in
      "NAME") name="$value" ;;
      "TRAIN_YEAR") train_year="$value" ;;
      "CAL_YEAR") cal_year="$value" ;;
      "CAL_WEEK") cal_week="$value" ;;
      "DEPARTMENT") department="$value" ;;
      *) ;;
    esac
  done < "$user_data"
}

get_data() { # Get data via user input
  name="$(dialog_helper "inputbox" "Name des Auszubildenden:")"
  train_year="$(dialog_helper "inputbox" "Ausbildungsjahr:")"
  cal_year="$(dialog_helper "inputbox" "Kalenderjahr des Berichts:")"
  cal_week="$(dialog_helper "inputbox" "Kalenderwoche des Berichts:")"
  department="$(dialog_helper "inputbox" "Abteilung:")"
}

# Function that determines the first and last day of the chosen week
get_date_range() {
  local first_Mon
  local date_fmt="+%d.%m.%Y"
  local mon sun

  if (($(date -d $cal_year-01-01 +%W))); then
    first_Mon=$cal_year-01-01
  else
    first_Mon=$cal_year-01-$((01 + (7 - $(date -d $cal_year-01-01 +%u) + 1) ))
  fi

  mon=$(date -d "$first_Mon +$(($cal_week - 1)) week" "$date_fmt")
  sun=$(date -d "$first_Mon +$(($cal_week - 1)) week + 6 day" "$date_fmt")
  date_range="$mon - $sun"
}

vipe_cmd() { # Helper function to call vipe
  content="$(echo "$1 (DIESE ZEILE LÖSCHEN!)" | vipe)"
  cat "$current_tex"/wochenbericht.tex | sed -i "s/$2/$content/g"
}

### SCRIPT

dialog_helper "msgbox" "Willkommen im Wochenberichtsskript!" || error "dialog needs to be installed to run this script!"

# When tex dir is not found, script will exit, because it won't find template
[ -d "$tex_dir" ] || error "Cannot find given tex directory: $tex_dir"

[ -d "$out_dir" ] || mkdir -p "$out_dir"

while true; do
  [ -f "$user_data" ] && read_data || get_data
  get_date_range "$cal_week" "$cal_year"

  # Let user validate inputs, let him redo the inputs if something is wrong
  while true; do
    dialog_helper "yesno" "Name: $name\nAusbildungsjahr: $train_year\nAusbildungsjahr: $train_year\nKalenderjahr: $cal_year\nAbteilung: $department\nWoche: $date_range\n\nSind die Angaben korrekt?"

    case "$?" in
      '0' ) break ;;
      '1' ) get_data; get_date_range ;;
      * ) error "Invalid case" ;;
    esac

  done

  # Write the current data to user.csv
  echo -e "NAME,$name\n\
    TRAIN_YEAR,$train_year\n\
    CAL_YEAR,$cal_year\n\
    CAL_WEEK,$cal_week"\n\
    DEPARTMENT,$department > "$user_data"

  # Copy template and insert data into copied file
  current_tex="$tex_dir/history/$cal_year/$cal_week"
  mkdir -p "$current_tex" || error "Could not create directory for .tex files $current_tex"

    cp -f "$tex_dir/template/wochenbericht.tex" "$current_tex/wochenbericht.tex"
    sed -i "s/NAME/$name/" "$current_tex/wochenbericht.tex"
    sed -i "s/WOCHE/$date_range/" "$current_tex/wochenbericht.tex"
    sed -i "s/AUSBILDUNGSJAHR/$train_year/" "$current_tex/wochenbericht.tex"
    sed -i "s/ABTEILUNG/$department/" "$current_tex/wochenbericht.tex"

  # Use vipe to let user enter their report text
  vipe_cmd "Betriebliche Tätigkeiten" BETRIEB
  vipe_cmd "Außerbetriebliche Tätigkeiten" EXTERN
  vipe_cmd "Berufsschule" SCHULE

  # Compile via pdflatex, remove *.log and *.aux files
  cd "$current_tex"
  tex_cmd "$cal_year-$cal_week" "wochenbericht.tex"

  # Increment cal_week and check if it was the last week of the year
  if [ "$cal_week" == 52 ]; then
    cal_week="1"
    ((cal_year=cal_year+1))
    sed -i "s/CAL_WEEK.*/CAL_WEEK,$cal_week/" "$user_data"
    sed -i "s/CAL_YEAR.*/CAL_YEAR,$cal_year/" "$user_data"
  else
    ((cal_week=cal_week+1))
    sed -i "s/CAL_WEEK.*/CAL_WEEK,$cal_week/" "$user_data"
  fi

  # Ask user if he wants to create the next report as well
  dialog_helper "yesno" "Noch einen Bericht erstellen?"
  case "$?" in
    '0' ) break ;;
    '1' ) clear; exit 0 ;;
    * ) error "Invalid case" ;;
  esac
done
