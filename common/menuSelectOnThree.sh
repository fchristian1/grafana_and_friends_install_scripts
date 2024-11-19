#!/bin/bash

parameters=("$@")
index=${parameters[0]}
tags=("${parameters[@]:1}")
if [ "${#tags[@]}" -eq 0 ]; then
    echo >&2 "Keine Tags übergeben."
    exit 1
fi
if [ "$index" -lt 0 ] || [ "$index" -ge "${#tags[@]}" ]; then
    echo >&2 "Ungültiger Startindex."
    exit 1
fi
while true; do
    clear >&2
    echo >&2 "Wähle eine Version von \"loki\" mit den Pfeiltasten und drücke Enter:"

    # Vorherige Version anzeigen
    if [ "$index" -gt 0 ]; then
        echo >&2 "   ${tags[index - 1]}"
    else
        echo >&2 ""
    fi
    # Aktuelle Auswahl anzeigen, mit " --> Latest" beim letzten Tag
    if [ "$index" -eq $((${#tags[@]} - 1)) ]; then
        echo >&2 " > ${tags[index]} --> Latest"
    else
        echo >&2 " > ${tags[index]}"
    fi

    # Nächste Version anzeigen, wenn vorhanden
    if [ "$index" -lt $((${#tags[@]} - 1)) ]; then
        echo >&2 "   ${tags[index + 1]}"
    else
        echo >&2 ""
    fi

    # Benutzer-Eingabe lesen
    read -rsn1 key

    case "$key" in
    $'\x1b')                  # Escape-Sequenz für Pfeiltasten beginnt mit ^[
        read -rsn2 -t 0.1 key # Die nächsten 2 Zeichen lesen
        case "$key" in
        "[A") # Pfeil nach oben
            ((index--))
            if [ "$index" -lt 0 ]; then
                index=$((${#tags[@]} - 1))
            fi
            ;;
        "[B") # Pfeil nach unten
            ((index++))
            if [ "$index" -ge "${#tags[@]}" ]; then
                index=0
            fi
            ;;
        esac
        ;;
    "") # Enter-Taste
        break
        ;;
    esac
done
clear >&2
echo ${tags[index]}
