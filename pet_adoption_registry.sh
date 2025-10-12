#!/bin/bash

DATA_FILE="pets.csv"

# Ensure the CSV exists
if [ ! -f "$DATA_FILE" ]; then
    echo "id,pet_name,species,breed,age,health_status,adoption_status,adopter_name,phone,email" > "$DATA_FILE"
fi

# Generate next unique ID
generate_id() {
    if [ ! -s "$DATA_FILE" ]; then
        echo 1
    else
        tail -n +2 "$DATA_FILE" | awk -F, 'BEGIN {max=0} {if ($1>max) max=$1} END {print max+1}'
    fi
}

# Add a new pet
add_pet() {
    echo "Enter pet name:"
    read pet_name
    [ -z "$pet_name" ] && echo "Name cannot be empty." && return

    echo "Enter species:"
    read species
    echo "Enter breed:"
    read breed
    echo "Enter age (in years):"
    read age
    if ! [[ "$age" =~ ^[0-9]+$ ]]; then
        echo "Age must be a number." && return
    fi

    echo "Enter health status:"
    read health_status
    echo "Enter adoption status (Available/Adopted/Pending):"
    read adoption_status
    echo "Enter adopter name (optional):"
    read adopter_name
    echo "Enter phone number (digits only, optional):"
    read phone
    if [ -n "$phone" ] && ! [[ "$phone" =~ ^[0-9]+$ ]]; then
        echo "Invalid phone number." && return
    fi
    echo "Enter email (optional):"
    read email

    id=$(generate_id)
    echo "$id,$pet_name,$species,$breed,$age,$health_status,$adoption_status,$adopter_name,$phone,$email" >> "$DATA_FILE"
    echo "Pet added successfully!"
}

# View all pets
view_all() {
    echo "All Pets:"
    column -t -s, "$DATA_FILE"
}

# Search pets
search_pets() {
    echo "Enter keyword to search (name/species/status):"
    read keyword
    echo "Search results:"
    grep -i "$keyword" "$DATA_FILE" | column -t -s, || echo "No results found."
}

# View specific pet
view_pet() {
    echo "Enter Pet ID:"
    read id
    grep "^$id," "$DATA_FILE" | column -t -s, || echo "No pet found with ID $id."
}

# Remove a pet
remove_pet() {
    echo "Enter Pet ID to remove:"
    read id
    if grep -q "^$id," "$DATA_FILE"; then
        grep -v "^$id," "$DATA_FILE" > temp.csv && mv temp.csv "$DATA_FILE"
        echo "Pet ID $id removed."
    else
        echo "Pet not found."
    fi
}

# Ask user if they want to show menu again
prompt_menu_again() {
    while true; do
        echo -n "Display menu again? (Y/N): "
        read answer
        case $answer in
            [Yy]* ) return 0 ;;  # show menu
            [Nn]* ) echo "Goodbye!"; exit 0 ;;
            * ) echo "Please answer Y or N." ;;
        esac
    done
}

# Main loop
while true; do
    clear
    echo "====== Pet Adoption Registry ======"
    echo "1) Add a new pet"
    echo "2) Search pets"
    echo "3) Remove a pet record"
    echo "4) View all pets"
    echo "5) View specific pet by ID"
    echo "6) Exit"
    echo "==================================="
    echo -n "Choose an option: "
    read choice
    echo

    case $choice in
        1) add_pet ;;
        2) search_pets ;;
        3) remove_pet ;;
        4) view_all ;;
        5) view_pet ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice, try again." ;;
    esac

    echo
    prompt_menu_again
done

