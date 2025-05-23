#!/bin/bash

CSV_FILE="users.csv"
TEMP_FILE="users_temp.csv"
LOGIN_SUCCESS=false

#variabila login_success o sa fie folosita pentru a apela urmatorul script, adica generare raport etc
#temp_file e folosita pentru a modifica din CSVul original data ultimei logari

read -p "Introduceti emailul: " input_email

# cautam linia din CSV care are emailul introdus de user

matched_line=$(grep ",$input_email," "$CSV_FILE")

if [[ -z "$matched_line" ]]; then
    echo "Email negasit."
    return 1 2>/dev/null || exit 1
fi

# mod portabil de a iesi din script, un fel de break/return

read -s -p "Parola: " input_password
echo

# parola hash
hashed_input=$(echo -n "$input_password" | sha256sum | sed 's/ .*//')

# extragere din linia gasita prin 'matched_line'

username=$(echo "$matched_line" | sed -E 's/^([^,]*),.*/\1/')
stored_hash=$(echo "$matched_line" | sed -E 's/([^,]*),([^,]*),([^,]*),([^,]*).*/\4/')

if [[ "$hashed_input" == "$stored_hash" ]]; then
    echo "Autentificare reusita."
    LOGIN_SUCCESS=true

    # data de azi
    today=$(date +%Y-%m-%d)

    # Escape special characters in email (for sed safety) (asta nu stiu ce e vad mai incolo)
    escaped_email=$(echo "$input_email" | sed 's/[]\/$*.^[]/\\&/g')

    # modificare in users.csv a datei ultimului login
    sed "s/^\([^,]*\),$escaped_email,\([^,]*\),\([^,]*\),[^,]*/\1,$input_email,\2,\3,$today/" "$CSV_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$CSV_FILE"

    user_home="/home/$username"
    if [[ -d "$user_home" ]]; then
        cd "$user_home" || exit
        echo "Redirectionare catre: $user_home"
    else
        echo "Eroare (404): Nu exista directorul $user_home."
        return 1 2>/dev/null || exit 1
    fi

    return 0 2>/dev/null || exit 0
else
    echo "Parola gresita."
    return 1 2>/dev/null || exit 1
fi
