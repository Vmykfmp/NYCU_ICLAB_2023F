# ========================================================
# Project:  Lab01 reference code
# File:     Test_data_gen_ref.py
# Author:   Lai Lin-Hung @ Si2 Lab
# Date:     2021.09.15
# ========================================================

# ++++++++++++++++++++ Import Package +++++++++++++++++++++

# ++++++++++++++++++++ Function +++++++++++++++++++++
def gen_test_data(input_file_path,output_file_path):
    # initial File path
    pIFile = open(input_file_path, 'w')
    pOFile = open(output_file_path, 'w')
    
    # Set Pattern number 
    PATTERN_NUM = 1000
    pIFile.write(PATTERN_NUM)
    for j in range(PATTERN_NUM):
        mode=0
        out_n=0
        # Todo: 
        # You can generate test data here


        # Output file
        pIFile.write(f"{mode}\n")
        for i in range(6):
            pIFile.write(f"{mode}\n")
            pIFile.write(f"{w[i]} {vgs[i]} {vds[i]}\n")
        pOFile.write(f"{out_n}\n")


# ++++++++++++++++++++ main +++++++++++++++++++++
def main():
    gen_test_data("input.txt","output.txt")

if __name__ == '__main__':
    main()