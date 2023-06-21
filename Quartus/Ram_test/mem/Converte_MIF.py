import matplotlib.pyplot as plt
import numpy as np




file_name = input("Nome do arquivo sem extenção:\n")
with open(f"{file_name}.mif", "w") as file:
    file.write("WIDTH=16;\n")
    file.write("DEPTH=1024;\n")
    file.write("\n")
    file.write("ADDRESS_RADIX=UNS;\n")
    file.write("DATA_RADIX=BIN;\n")
    file.write("\n")
    file.write("CONTENT BEGIN")
    file.write("\n")
    for idx in range(1024):
        file.write(f"\t{idx} : {np.binary_repr(idx, width=16)};\n")
    file.write("END;\n")
