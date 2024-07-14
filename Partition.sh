#Modular UNIX script to create PartitionFinder infile based on Nexus files 
#Written by Omar M. Entiauspe-Neto 

#Place all Nexus alignment files in a folder 

#!/bin/bash

# Output file
output_file="nchar_summary.txt"

# Empty the output file if it exists
> $output_file

# Loop through all .nex files in the current directory
for file in *.nex; do
    # Extract the line containing 'dimensions nchar='
    nchar_line=$(grep -i 'dimensions nchar=' "$file")

    # Check if the line was found
    if [ ! -z "$nchar_line" ]; then
        # Append the filename and the extracted line to the output file
        echo "$file: $nchar_line" >> $output_file
    fi
done


chmod +x extract_nchar.sh

./extract_nchar.sh

######### Creating PartitionFinder File

#!/bin/bash

# Output file
output_file="partition_summary.txt"

# Empty the output file if it exists
> $output_file

# Initialize variables
cumulative_nchar=0
partition_number=1

# Loop through all .nex files in the current directory
for file in *.nex; do
    # Extract the line containing 'dimensions nchar='
    nchar_line=$(grep -i 'dimensions nchar=' "$file")

    # Check if the line was found
    if [ ! -z "$nchar_line" ]; then
        # Extract the number of characters from the line
        nchar=$(echo $nchar_line | sed 's/.*dimensions nchar=\([0-9]*\).*/\1/')
        
        # Calculate the start and end positions for the partition
        start_pos=$((cumulative_nchar + 1))
        end_pos=$((cumulative_nchar + nchar))
        
        # Append the partition information to the output file
        echo "DNA, $file, p$partition_number = $start_pos-$end_pos" >> $output_file
        
        # Update the cumulative number of characters and partition number
        cumulative_nchar=$end_pos
        partition_number=$((partition_number + 1))
    fi
done

chmod +x create_partitions.sh

./create_partitions.sh

##### Remove "NEXUS" from the summary file

s/\.nex\b//g
s/\.nexus\b//g

#### Creating a PartitionFinder Filetype

#!/bin/bash

# Input and output files
input_file="partition_summary.txt"
output_file="PartitionFinder.txt"

# Empty the output file if it exists
> $output_file

# Read each line from the input file
while IFS= read -r line; do
    # Extract the filename and range
    filename=$(echo "$line" | awk -F', ' '{print $2}')
    range=$(echo "$line" | awk -F' = ' '{print $2}')

    # Check if the filename contains "12S" or "16S"
    if [[ "$filename" == *12S* ]] || [[ "$filename" == *16S* ]]; then
        # If it contains "12S" or "16S", output the line as is
        echo "$filename = $range;" >> $output_file
    else
        # If it doesn't contain "12S" or "16S", split into three parts
        IFS='-' read -r start end <<< "$range"
        echo "${filename}_1 = ${start}-${end}\\3;" >> $output_file
        echo "${filename}_2 = $((start + 1))-${end}\\3;" >> $output_file
        echo "${filename}_3 = $((start + 2))-${end}\\3;" >> $output_file
    fi
done < "$input_file"


chmod +x create_partitionfinder.sh


./create_partitionfinder.sh



### Remove ".nex" string

sed -i 's/\.nex//g' PartitionFinder.txt
