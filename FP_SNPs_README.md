# Task

## Скачиваем и подготовливаем файлы
```bash
wget "http://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GRAF_files.zip" -O GRAF_files.tar.gz
mkdir -p tmp
tar -xvzf GRAF_files.tar.gz -C tmp/
cp tmp/data/FP_SNPs.txt .
rm -rv tmp/
```
#
```bash
awk 'NR==1 {print "#CHROM\tPOS\tID\tallele1\tallele2"; next}  
     $2 != "23" {print "chr"$2"\t"$4"\trs"$1"\t"$5"\t"$6}' FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```
# Референс
```bash
wget https://api.gdc.cancer.gov/data/254f697d-310d-4d7d-a27b-27fbf767a834 -O GRCh38.d1.vd1.fa.tar.gz
tar -xvzf GRCh38.d1.vd1.fa.tar.gz
mkdir -p ref/GRCh38.d1.vd1_mainChr/sepChrs/
```
```bash
awk '/^>chr[0-9]+|^>chrX|^>chrY|^>chrM/ {if (outfile) close(outfile); outfile="ref/GRCh38.d1.vd1_mainChr/sepChrs/" substr($1,2) ".fa"} {print > outfile}' GRCh38.d1.vd1.fa 
```
```bash
rm GRCh38.d1.vd1.fa*

```

# Docker контейнер
```bash
singularity exec plasmid.sif python3 main.py <path_to_references> <path_to_sequencing> <path_to_table.xlsx> <output_dir> <threads (default=4)>
```