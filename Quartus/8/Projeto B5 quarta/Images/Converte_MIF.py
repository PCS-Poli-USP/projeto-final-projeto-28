import matplotlib.pyplot as plt
import numpy as np




file_name = input("Nome do arquivo sem extenção:\n")
with open(f"{file_name}.mif", "w") as file:
    file.write("WIDTH=12;\n")
    file.write("DEPTH=307200;\n")
    file.write("\n")
    file.write("ADDRESS_RADIX=UNS;\n")
    file.write("DATA_RADIX=BIN;\n")
    file.write("\n")
    file.write("CONTENT BEGIN")
    file.write("\n")
    
    idx = 0

    for line in np.sqrt(plt.imread(f'{file_name}.bmp')).astype(np.int8):
        for pixel in line:
            R, G, B = [val for val in pixel]
            UB = R
            LB = ((G << 4) + B).astype(np.int8)
            byte1 = bin(UB).split('b')[1].zfill(4)
            byte2 = bin(LB).split('b')[1].zfill(8)
            file.write("\t")
            file.write(f"{idx} : ")
            idx += 1
            file.write(byte1)
            file.write(byte2)
            file.write(";\n")
    file.write("END;\n")
