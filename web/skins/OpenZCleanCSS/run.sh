#!/bin/bash

# Pfad zur Quell-CSS-Datei
quell_datei="./Clean.css"

# Liste der Ziel-CSS-Dateien
ziel_dateien=(
  "./Openbravo_ERP_250.css"
  "./Openz.css"
)

# Eindeutige Marker für den eingefügten Inhalt
start_marker="/* START EINGEFÜGTER INHALT */"
end_marker="/* ENDE EINGEFÜGTER INHALT */"

# Überprüfen, ob die Quell-Datei existiert
if [[ ! -f "$quell_datei" ]]; then
  echo "Die Quelldatei '$quell_datei' wurde nicht gefunden."
  exit 1
fi

# Inhalt der Quell-Datei lesen
quell_inhalt=$(<"$quell_datei")

# Inhalt an jede Ziel-Datei anhängen
for ziel_datei in "${ziel_dateien[@]}"; do
  if [[ -f "$ziel_datei" ]]; then
    # Temporäre Datei erstellen
    tmp_datei=$(mktemp)

    # Inhalt der Zieldatei lesen und Marker-basierten Bereich entfernen
    awk -v start="$start_marker" -v end="$end_marker" '
      BEGIN {in_block=0}
      $0 ~ start {in_block=1; next}
      $0 ~ end {in_block=0; next}
      !in_block {print}
    ' "$ziel_datei" > "$tmp_datei"

    # Neuen Inhalt mit Markern hinzufügen
    {
      cat "$tmp_datei"
      echo "$start_marker"
      echo "$quell_inhalt"
      echo "$end_marker"
    } > "$ziel_datei"

    # Temporäre Datei entfernen
    rm "$tmp_datei"

    echo "Inhalt erfolgreich in '$ziel_datei' aktualisiert."
  else
    echo "Die Zieldatei '$ziel_datei' wurde nicht gefunden."
  fi
done
