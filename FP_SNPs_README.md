# Преобразование файла 

## Описание
Данный поект выполнен в качестве тестового задания. Репрезитоий содержит файлы и инструкции для тестирования и воспроизведения. Скрипт python на основе файла с данными по SNP и референсного генома создает новый скорректированный файл

1. Логирование: Создается лог-файл для отслеживания всех шагов и ошибок выполнения

2. Проверка данных: Проверяется наличие и структура файлов

3. Обработка SNP: Для каждого SNP в файле проверяется его аллели на основе референсного генома. Если одна из аллелей совпадает, она записывается в новый выходной файл

## Требования
- Установленные инструменты `wget`, `awk`, `tar`
- Docker

## Инструкция

## Скачиваем и подготовливаем файлы
```bash
wget "http://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GRAF_files.zip" -O GRAF_files.tar.gz
mkdir -p tmp
tar -xvzf GRAF_files.tar.gz -C tmp/
cp tmp/data/FP_SNPs.txt .
rm -rv tmp/
```
## Подготовка файла для анализа
С помощью awk преобразуем исходный файл из формата
«#CHROM<TAB>POS<TAB>ID<TAB>allele1<TAB>allele2» в формат
«#CHROM<TAB>POS<TAB>ID<TAB>REF<TAB>ALT»:
```bash
awk 'NR==1 {print "#CHROM\tPOS\tID\tallele1\tallele2"; next}  
     $2 != "23" {print "chr"$2"\t"$4"\trs"$1"\t"$5"\t"$6}' FP_SNPs.txt > FP_SNPs_10k_GB38_twoAllelsFormat.tsv
```
## Референс
```bash
wget https://api.gdc.cancer.gov/data/254f697d-310d-4d7d-a27b-27fbf767a834 -O GRCh38.d1.vd1.fa.tar.gz
tar -xvzf GRCh38.d1.vd1.fa.tar.gz
mkdir -p ref/GRCh38.d1.vd1_mainChr/sepChrs/
```
## Разделение референса на отдельные файлы по хромосомам (при необходимости)
```bash
awk '/^>chr[0-9]+|^>chrX|^>chrY|^>chrM/ {if (outfile) close(outfile); outfile="ref/GRCh38.d1.vd1_mainChr/sepChrs/" substr($1,2) ".fa"} {print > outfile}' GRCh38.d1.vd1.fa 
```
```bash
rm GRCh38.d1.vd1.fa*
```
# Docker контейнер

# Запуск спипта через Docker контейнер
```bash
docker build -t task -f dockerfile .
docker run --rm -v $(pwd):/data --entrypoint python3 task /data/script.py \
  -r /data/ref/GRCh38.d1.vd1_mainChr/sepChrs \
  -f /data/FP_SNPs_10k_GB38_twoAllelsFormat.tsv \
  -o /data/FP_SNPs_10k_GB38.tsv \
  -l /data/file.log
```
