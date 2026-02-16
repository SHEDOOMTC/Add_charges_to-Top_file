# Add_charges_to_Top_file

After ligand parametrization using Molecular mechanics (MM) forcefields, the partial atomic chrges needs to be fine-tuned using quantum mechanics (QM)calculations (Gaussian, DFT etc)

Herein is a code to help you edit the top file with the calculated partial chrges


# Features

	Edits the original topolgy file
	Maintains the gromacs formatting
	Outputs a new topology with updated partial atomic charges

# Requirements

Bash (Linux/macOS or WSL on Windows)
Acpype (To generate the ligand gromacs parameters)
Gaussian Engine (for QM calculations of partial atomic charges)

# Input files

A cordinate file of the ligand in mol2 format (very important)
A topolgy file of the ligand in top format, generated from acpype
A log file generated from the QM calculations

# Installation
