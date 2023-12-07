#!/bin/bash

#The first step is downloading the raw sequencing files into our server or computer. Most sequencing providers will upload the raw files into an FTP server. The files can usually be downloaded using the Unix command "wget":
#wget https://...
#Paired-end sequencing generates two output fastq files for each sample. These usually end in "_1.fastq.gz" and "_2.fastq.gz" (but "_R1_001.fastq.gz" and "_R2_001.fastq.gz" are also frequent). The files are usually compressed using gunzip - there is no need to unzip them, most software will work with gunzipped files. The fastq files will usually come with corresponding MD% files to check that the integrity of the downloaded files.
## 1. Quality control with FastQC 
#Once we have downloaded the fastq files, it is good practice to check their quality. It can be done using the software [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/). The command to run FastQC in a fastq file is:

#File names should not contain any spaces or characters such as parenthesis () as Linux has special meanings for these in the command line.
#echo 'What is the name of the file with Read 1?'
#read sample1

#echo 'What is the name of the file with Read 2?'
#read sample2

#echo 'What is the name of the file with the transcriptome?'

# Fastqc, fastp and kallisto need to be installed in the computer. In case you install it with conda, the conda environment you install it must be active before running this script. For example, if you installed the programs in an environment called kallisto, you must run the command 'conda activate kallisto' before you run the bash script.
#Run the script as 'rna_seq_kallisto.bash *name_of_sample*' replacing *name_of_sample* with the initial part of your fastq files, without the _R1.fastq.gz
#You can also call the run_kallisto.bash script to run through a series of samples on a folder.

#sample=1_1paired
sample=$1
sample1=${sample}_R1.fastq.gz
sample2=${sample}_R2.fastq.gz
#transcriptome=../skin/GFJW01.1.fsa_nt.gz
transcriptome=./cdna/Dicentrarchus_labrax.dlabrax2021.cdna.all.fa.gz

echo "Starting analysis for "
echo $sample

#Check if fastqc output file already exists. If not, run fastqc.
FASTQC1=${sample}_R1_fastqc.html
FASTQC2=${sample}_R2_fastqc.html

if test -f "$FASTQC1"; then 
	echo 'Fastqc for read 1 already done; skipping'
else 
	fastqc $sample1
fi

if test -f "$FASTQC2" ; then
	echo 'Fastqc for read 2 already done; skipping'
else 
	fastqc $sample2
fi
#fastqc ${sample}_R1.fastq.gz
#fastqc ${sample}_R2.fastq.gz
#fastqc $sample1
#fastqc $sample2

#fastqc *fastq.gz

#Two files will be generated by FastQC: fastqc.zip and fastqc.html. To visualise them, the easiest way is to open the html files with a web browser. You can find output examples in the webpage of [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/). RNA-Seq data usually present warnings for some of the categories, such as "Per base sequence context" or "Sequence duplication levels". As long as the issues are not extrime, this is normal and nothing to worry about.
#This quality control is just to visually inspect the quality of the sequencing data, but it does not alter the fastq files in any way. In fact, this step can even be skipped, although it is worth practice to check the quality of the sequencing output to discards any problems connected to RNA extraction, library preparation or sequencing.

## 2. Filtering using fastp
#While not absolutely necessary, removing low quality reads and bases can improve downstream results. (Note from Gonçalo, fastp also removes adapter sequences, so I think this step should not be optional) 
#[Fastp](https://github.com/OpenGene/fastp) can rapidly filter fastq files, removing low quality reads, contaminating sequence, low complexity reads (repeats), short reads, etc. An example command would be:

#fastp -i sampleA_1.fastq.gz -I sampleA_2.fastq.gz -o sampleA_filtered_1.fastq.gz -O sampleA_filtered_2.fastq.gz -q 15 -l 30 -h sampleA.html

#Check if output already exists, otherwise run fastp
FILTERED1=${sample}_R1_filtered.fastq.gz
FILTERED2=${sample}_R2_filtered.fastq.gz
if [[ -f "$FILTERED1" && -f "$FILTERED2" ]]; then
	echo 'Filtered reads already exist; skipping fastp'
else
	fastp -i ${sample1} -I ${sample2} -o $FILTERED1 -O $FILTERED2 -q 15 -l 30 -h ${sample}.html
	mv fastp.json ${sample}_fastp.json
fi
#Fastp takes two paired fastq files (options -i and -I) and removes bases with Phred quality below 15 (-q 15) and reads that end up with a lenght of less than 30 bases (-l 30). The raw files remain intact, and two new filtered files are generated (options -o and -O). -h specifies names for the html file with plots showing the read quality before and after filtering  (potential alternative to FastQC).

## 3. Quantification using kallisto

#[Kallisto](https://pachterlab.github.io/kallisto/about) is a software for rapidly quantifying abundances of transcripts from RNA-seq data. It is based on a pseudoalignment strategy using the transcriptome of a species as reference. This reference transcriptome needs to be downloaded and indexed before expression can be quantified. Transcriptomes for species with sequenced genomes can be obtained from Ensembl or NCBI (and downloaded using "wget").



#To create the index of the transcriptome, the command is:
INDEX=${transcriptome}.idx

if [[ -f "$INDEX" ]]; then
	echo 'Transcriptome index already exists; skipping'
else
	kallisto index -i $INDEX ${transcriptome}
fi

#To estimate the expression of each transcript in each sample, we use the `quant` function of kallisto:

ABUNDANCE=./${sample}/abundance.h5

if [[ -f "$ABUNDANCE" ]]; then
	echo 'Kallisto already run on this sample; skipping'
else
	kallisto quant -i $INDEX -o $sample -b 100 $FILTERED1 $FILTERED2 2> ${sample}_kallisto.out
fi

#The results for each sample will be in a separate folder with the name of the sample (-o). That folder will contain three files: abundance.h5, abundance.tsv, and run_info.json

echo "Finished processing "
echo $sample