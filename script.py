import argparse
import csv
import logging
import os
import time
import pandas as pd
import pysam

def setup_logging(log_file: str):

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_file, mode="w", encoding="utf-8"),
            logging.StreamHandler()
        ]
    )

def check_data(ref_dir: str, tsv_file: str):
    
    logging.info("STEP 1: Checking input files")
    
    # Checking if the input file exists
    try:
        df_tsv = pd.read_csv(tsv_file, sep="\t", encoding="utf-8")
    except Exception as e:
        logging.error(f"Error loading {tsv_file}: {e}", exc_info=True)
        raise
    
    # Checking the structure of the input file
    tsv_col = {"#CHROM", "POS", "ID", "allele1", "allele2"}
    
    if not tsv_col.issubset(df_tsv.columns):
        logging.error(f"Error: Incorrect TSV file structure. Found: {list(df_tsv.columns)} Required: {sorted(tsv_col)}")
        raise

    # Checking reference files
    ref_files = {
        chrom: os.path.join(ref_dir, f"{chrom}.fa")
        for chrom in df_tsv["#CHROM"].unique()
    }
    
    missing_files = [
        chrom for chrom, 
        path in ref_files.items() 
        if not os.path.exists(path)
    ]
    
    if missing_files:
        logging.warning(f"Missing reference files: {missing_files}")
    return df_tsv, ref_files

def process_snp_data(df_tsv: pd.DataFrame, ref_files: dict, output_file: str):

    logging.info(f"STEP 3: Processing SNP data and saving to {output_file}")

    # Writing the new TSV file
    with open(output_file, "w", newline="") as out_file:

        new_f = csv.writer(out_file, delimiter="\t")
        new_f.writerow(["#CHROM", "POS", "ID", "REF", "ALT"])
        
        for chrom, ref_file in ref_files.items():

            if not os.path.exists(ref_file):
                continue
            
            # Checking reference allele consistency with the input data
            with pysam.Fastafile(ref_file) as ref:  # Creates an index if missing
                for _, row in df_tsv[df_tsv["#CHROM"] == chrom].iterrows():
                    
                    pos = int(row["POS"]) - 1
                    ref_allele = ref.fetch(chrom, pos, pos + 1).upper()
                    
                    if ref_allele in {row["allele1"], row["allele2"]}:

                        alt_allele = (
                            row["allele1"] 
                            if ref_allele == row["allele2"] 
                            else row["allele2"]
                        )
                        new_f.writerow([
                            chrom, pos + 1, row["ID"], ref_allele, alt_allele
                        ])
                    else:
                        logging.warning(
                            f"Allele mismatch {chrom} {pos + 1}: expected {row['allele1']}/{row['allele2']}, found {ref_allele}"
                        )

def main():
    
    parser = argparse.ArgumentParser(
        description="Process SNP files with reference data."
    )
    
    parser.add_argument("-r", "--reference", required=True, help="Path to reference directory")
    parser.add_argument("-f", "--file", required=True, help="Path to input TSV file")
    parser.add_argument("-o", "--out", required=True, help="Path to output file")
    parser.add_argument("-l", "--log", default="file.log", help="Log file")
    
    args = parser.parse_args()
    
    setup_logging(args.log)
    
    logging.info("=== START: Program execution ===")
    
    start_time = time.time()
    
    try:
        df_tsv, ref_files = check_data(args.reference, args.file)
        process_snp_data(df_tsv, ref_files, args.out)
    except Exception as e:
        logging.error(f"Execution error: {e}", exc_info=True)
    else:
        logging.info(f"File saved: {args.out}")
    
    logging.info(
        f"=== Finished. Execution time: {time.time() - start_time:.2f} sec ==="
    )

if __name__ == "__main__":
    main()