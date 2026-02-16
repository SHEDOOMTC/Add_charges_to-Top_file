#!/bin/bash

mol2_file="$1"
top_file="$2"
Esp_chg_file="$3"

if [[ -z "$mol2_file" || -z "$top_file" || -z "$Esp_chg_file" ]]; then
    echo "Usage: $0 mol2_file top_file Esp_chg_file"
    exit 1
fi


echo "  ####### PART 1 ###### "

echo "Extracting Needed Fields from Input Files"

# 1.	Extract the atom info from mol2 file (first two lines)
 awk '/@<TRIPOS>ATOM/{f=1; next} f&&/@<TRIPOS>/{f=0} f&&NF>=9&&/^[ \t]*[0-9]+/{print $1, $2}' "$mol2_file" > mol_file_atoms_id.txt


# 2.	Extract the lines 5 and 7 from the atoms section of the top file
awk '
/^\[ *atoms *\]/ {in_atoms=1; next}
/^\[/ {in_atoms=0}
in_atoms && $1 ~ /^[0-9]+$/ && NF >= 7 {print $5, $7}
' "$top_file" > top_file_atom_charge.txt

# 3.	Extract the section with "ESP charges from the log file of the guassion calculation
 sed -n '/ESP charges:/,/^ *$/p' "$Esp_chg_file" > Esp_charges.txt

# 4.	Then extract only the charges
awk '/ESP charges:/{f=1; next} f&&/Sum of ESP charges/{f=0} f&&NF==3&&/^[ \t]*[0-9]+/ {print}' Esp_charges.txt > Esp_charges_atoms.txt

# 5.	Join mol_file_atoms.txt and Esp_charges_atoms.txt atoms_id_name.txt by atom ID only
awk 'NR==FNR {a[$1]=$0; next} $1 in a {print a[$1], $2, $3}' mol_file_atoms_id.txt Esp_charges_atoms.txt > temporal.txt

# 6.	Join the temporary file (temp.txt) with top_file_atom_charge.txt by atom name
awk 'NR==FNR {charge[$2]=$4; next} {print $1, $2, charge[$1]}' temporal.txt top_file_atom_charge.txt > complete_charge.txt

echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"

echo " ####### PART 2 ####### "

echo "Editing the Charges of the Topology File"

# 1.	Find section boundaries
atoms_start=$(grep -n "\[ *atoms *\]" "$top_file" | cut -d: -f1)

next_header=$(awk '
    /\[ *atoms *\]/ {found=1; next}
    found && /^\[/ {print NR; exit}
' "$top_file")

# 2.	Extract header
head -n $((atoms_start - 1)) "$top_file" > header_file.top

# 3.	Extract atoms section
tail -n +$((atoms_start + 1)) "$top_file" \
    | head -n $((next_header - atoms_start - 1)) \
    > atoms_section_raw.top


# 4.	Determine charge column start and width from ALL atom lines
read cstart cwidth <<EOF
$(awk '
$1~/^[0-9]+$/ && NF>=8 {
    match($0, $7)
    if (!s || RSTART < s) s = RSTART
    if (RLENGTH > w)      w = RLENGTH
}
END {print s, w}
' atoms_section_raw.top)
EOF

# 5.	Apply corrected charges using those exact boundaries
awk -v cs="$cstart" -v cw="$cwidth" '
NR==FNR {charge[$1]=$NF; next}

$1~/^[0-9]+$/ && NF>=8 {
    # Format new charge to fixed width
    new = sprintf("%*.*f", cw, 6, charge[$5])

    # Insert new charge exactly in the original column boundaries
    $0 = substr($0, 1, cs-1) new substr($0, cs+cw)
}

1
' complete_charge.txt atoms_section_raw.top > atoms_section_fixed.top

# 6.	Extract footer
tail -n +$((next_header)) "$top_file" > footer_file.top

# 7.	Extract the exact [ atoms ] header line
sed -n "${atoms_start}p" "$top_file" > atom_section_header.top


# 8.	Combine all the intermediate files
{
    tail -n +1 header_file.top
    tail -n +1 atom_section_header.top
    tail -n +1 atoms_section_fixed.top
    tail -n +1 footer_file.top
} > edited_"$top_file"


echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"
echo "##"


echo " ######### PART 3 ############ "

echo "Compare the Initial and Final Top files"

diff -y "$top_file" edited_"$top_file" | less -SR

