while IFS= read -r line; do
    ./rna_seq_kallisto.bash ./reads/$line
done < sample_list.txt

multiqc .
