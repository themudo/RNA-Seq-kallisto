while IFS= read -r line; do
    ./RNA-Seq-kallisto/rna_seq_kallisto.bash ./reads/$line
done < sample_list.txt

multiqc ./reads