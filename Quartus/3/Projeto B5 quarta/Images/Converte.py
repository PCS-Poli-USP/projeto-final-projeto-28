import matplotlib.pyplot as plt
import numpy as np
from PIL import Image




file_name = input("Nome do arquivo sem extenção:\n")
with open(f"{file_name}.dat", "wb") as file:
    for line in np.sqrt(plt.imread(f'{file_name}.bmp')).astype(np.uint8):
        for pixel in line:
            R, G, B = [val for val in pixel]
            UB = R.astype(np.uint8)
            LB = ((G << 4) + B).astype(np.uint8)
            file.write((LB).tobytes())
            file.write((UB).tobytes())


    img = Image.fromarray(np.sqrt(plt.imread(f'{file_name}.bmp')).astype(np.uint8)**2, 'RGB')
    img.show()

            
