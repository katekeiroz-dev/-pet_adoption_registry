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

# Helper to read required field with re-prompting and cancel option
# Usage: read_required variable "Prompt text"
read_required() {
    local __var="$1"
    local prompt_text="$2"
    local input
    while true; do
        printf "%s " "$prompt_text"
        read -r input
        # allow user to cancel add operation
        if [[ "$input" == "q" || "$input" == "Q" ]]; then
            eval "$__var='__CANCEL__'"
            return 0
        fi
        # trim whitespace
        input="$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [ -z "$input" ]; then
            echo "Error: This field cannot be empty. Please enter a value or type 'q' to cancel."
            continue
        fi
        eval "$__var=\"\$input\""
        return 0
    done
}

# Helper to read optional field (returns empty allowed). If user types q, returns __CANCEL__
read_optional() {
    local __var="$1"
    local prompt_text="$2"
    local input
    printf "%s " "$prompt_text"
    read -r input
    if [[ "$input" == "q" || "$input" == "Q" ]]; then
        eval "$__var='__CANCEL__'"
        return 0
    fi
    input="$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    eval "$__var=\"\$input\""
    return 0
}

# Add a new pet (handling error validations)
add_pet() {
    echo
    echo "Add a New Pet (type 'q' at any prompt to cancel)"

    # pet_name (required)
    read_required pet_name "Enter pet name:"
    if [ "$pet_name" = "__CANCEL__" ]; then
        echo "Add cancelled."
        return
    fi

    # species (required)
    read_required species "Enter species (e.g. Dog, Cat, Rabbit):"
    if [ "$species" = "__CANCEL__" ]; then
        echo "Add cancelled."
        return
    fi

    # breed (optional)
    read_optional breed "Enter breed (optional):"
    if [ "$breed" = "__CANCEL__" ]; then
        echo "Add cancelled."
        return
    fi

    # age (required, numeric)
    while true; do
        read_required age "Enter age (in years):"
        if [ "$age" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi
        if ! [[ "$age" =~ ^[0-9]+$ ]]; then
            echo "Error: Age must be a whole number (digits only). Please try again or type 'q' to cancel."
            continue
        fi
        break
    done

    # health_status (required)
    read_required health_status "Enter health status (e.g. Healthy, Vaccinated):"
    if [ "$health_status" = "__CANCEL__" ]; then
        echo "Add cancelled."
        return
    fi

    # adoption_status (required, limited choices)
    while true; do
        read_required adoption_status "Enter adoption status (Available / Adopted / Pending):"
        if [ "$adoption_status" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi
        case "$adoption_status" in
            Available|available|Adopted|adopted|Pending|pending)
                # Normalize to capitalized first letter
                adoption_status="$(tr '[:upper:]' '[:lower:]' <<<"$adoption_status")"
                adoption_status="$(tr '[:lower:]' '[:upper:]' <<<"${adoption_status:0:1}")${adoption_status:1}"
                break
                ;;
            *)
                echo "Error: Adoption status must be Available, Adopted, or Pending. Please try again or type 'q' to cancel."
                ;;
        esac
    done

    # If adopted, collect adopter info 
    adopter_name=""
    phone=""
    email=""
    if [ "$adoption_status" = "Adopted" ]; then
        read_required adopter_name "Enter adopter name:"
        if [ "$adopter_name" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi

        # phone (required for adopted)
        while true; do
            read_required phone "Enter adopter's phone (digits only):"
            if [ "$phone" = "__CANCEL__" ]; then
                echo "Add cancelled."
                return
            fi
            if ! [[ "$phone" =~ ^[0-9]{7,15}$ ]]; then
                echo "Error: Phone must be 7–15 digits. Try again or type 'q' to cancel."
                continue
            fi
            break
        done

        # email (required for adopted)
        while true; do
            read_required email "Enter adopter's email:"
            if [ "$email" = "__CANCEL__" ]; then
                echo "Add cancelled."
                return
            fi
            if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                echo "Error: Invalid email format. Try again or type 'q' to cancel."
                continue
            fi
            break
        done
    else
        # for Available/Pending allow optional adopter info
        read_optional adopter_name "Enter adopter name (optional):"
        if [ "$adopter_name" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi

        read_optional phone "Enter phone (optional, digits only):"
        if [ "$phone" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi
        if [ -n "$phone" ] && ! [[ "$phone" =~ ^[0-9]{7,15}$ ]]; then
            echo "Error: Phone must be 7–15 digits if provided. Add cancelled."
            return
        fi

        read_optional email "Enter email (optional):"
        if [ "$email" = "__CANCEL__" ]; then
            echo "Add cancelled."
            return
        fi
        if [ -n "$email" ] && ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo "Error: Invalid email format if provided. Add cancelled."
            return
        fi
    fi

    id=$(generate_id)
    echo "$id,$pet_name,$species,$breed,$age,$health_status,$adoption_status,$adopter_name,$phone,$email" >> "$DATA_FILE"
    echo "Pet added successfully (ID: $id)."
}

# View all pets
view_all() {
    echo
    echo "All Pets:"
    column -t -s, "$DATA_FILE" || awk -F, 'BEGIN{OFS=" | "} {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' "$DATA_FILE"
}

# Search pets
search_pets() {
    echo
    echo "Search pets by:"
    echo " 1) Pet name"
    echo " 2) Species"
    echo " 3) Adoption status"
    echo " 4) Free text (all fields)"
    echo -n "Choose option (or q to cancel): "
    read -r opt
    if [[ "$opt" == "q" || "$opt" == "Q" ]]; then
        echo "Search cancelled."
        return
    fi

    case "$opt" in
        1) field=2 ;;
        2) field=3 ;;
        3) field=7 ;;
        4) field=0 ;;
        *) echo "Invalid choice."; return ;;
    esac

    echo -n "Enter search keyword: "
    read -r keyword
    if [ -z "$keyword" ]; then
        echo "No keyword entered. Search cancelled."
        return
    fi

    echo
    echo "Results:"
    if [ "$field" -eq 0 ]; then
        awk -F, -v kw="$keyword" 'BEGIN{IGNORECASE=1} NR>1 {for(i=1;i<=NF;i++) if(index($i,kw)) {print; break}}' "$DATA_FILE" | column -t -s, || echo "No matches."
    else
        awk -F, -v kw="$keyword" -v f="$field" 'BEGIN{IGNORECASE=1} NR>1 && index($f,kw){print}' "$DATA_FILE" | column -t -s, || echo "No matches."
    fi
}

# View specific pet by ID
view_pet() {
    echo
    echo -n "Enter Pet ID (or q to cancel): "
    read -r id
    if [[ "$id" == "q" || "$id" == "Q" ]]; then
        echo "Cancelled."
        return
    fi
    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: ID must be a number."
        return
    fi
    awk -F, -v id="$id" 'NR==1{next} $1==id{print "ID: "$1; print "Name: "$2; print "Species: "$3; print "Breed: "$4; print "Age: "$5; print "Health: "$6; print "Status: "$7; print "Adopter: "$8; print "Phone: "$9; print "Email: "$10; found=1} END{if(!found) print "No pet found with ID " id}' "$DATA_FILE"
}

# Remove a pet
remove_pet() {
    echo
    echo -n "Enter Pet ID to remove (or q to cancel): "
    read -r id
    if [[ "$id" == "q" || "$id" == "Q" ]]; then
        echo "Delete cancelled."
        return
    fi
    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: ID must be a number."
        return
    fi
    if ! awk -F, -v id="$id" 'NR>1 && $1==id{found=1} END{exit !found}' "$DATA_FILE"; then
        echo "No record with ID $id found."
        return
    fi
    echo -n "Type DELETE to confirm deletion of ID $id: "
    read -r confirm
    if [[ "$confirm" != "DELETE" ]]; then
        echo "Deletion cancelled."
        return
    fi
    awk -F, -v id="$id" 'NR==1 || $1!=id{print}' "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo "Record with ID $id deleted."
}

# Ask user if they want to show menu again
prompt_menu_again() {
    while true; do
        echo -n "Display menu again? (Y/N): "
        read -r answer
        case $answer in
            [Yy]* ) return 0 ;;
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
    read -r choice
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

