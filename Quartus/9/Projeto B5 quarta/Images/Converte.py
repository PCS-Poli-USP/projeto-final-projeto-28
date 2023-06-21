import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
from os import listdir
from os.path import isfile, join


mypath = "./Polycam"
onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]

files = sorted(onlyfiles)

#file_name = input("Nome do arquivo sem extenção:\n")
with open(f"Apresentacao.dat", "wb") as file:

    for file_name in files:
        img = np.sqrt(plt.imread("./Polycam/"+file_name)).astype(np.uint8)
        img2 = img.reshape((256, 4095, 3))

        new_img = np.zeros((256,4096,3), dtype=np.uint8)
        for i in range(256):
            n_line = np.append(img2[i], (15,15,15)).reshape(4096,3)
            new_img[i] = n_line
        
        for line in new_img:
            for pixel in line:
                R, G, B = [val for val in pixel]
                UB = R.astype(np.uint8)
                LB = ((G << 4) + B).astype(np.uint8)
                file.write((LB).tobytes())
                file.write((UB).tobytes())








            
