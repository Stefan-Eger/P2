import math
import time

import numpy as np

import matplotlib
import matplotlib.pyplot as plt


class DomainColoring:
    def __init__(self, width: int, height: int, xmin=-2, xmax=2, ymin=-2, ymax=2, bpm=0.0):

        self.xmin = xmin
        self.xmax = xmax
        self.ymin = ymin
        self.ymax = ymax
        self.width = width
        self.height = height
        matplotlib.rcParams['toolbar'] = 'None'

        x = np.linspace(xmin, xmax, width)
        y = np.linspace(ymin, ymax, height)
        X, Y = np.meshgrid(x, y)
        #Meshgrid on complex Plane
        self.Z = X + 1j * Y

        self.bpm = bpm

    # https://github.com/jcponce/complex/blob/gh-pages/dctools/hsb/dcolorhsb.js#L169
    # hue sat and val function has been reengineered to recreate domain colouring in tutorial
    # https://complex-analysis.com/content/domain_coloring.html
    def __hue(self, x, y):

        #angle = np.angle(x + 1j * y)
        #ret = (angle + np.pi) / (2 * np.pi)
        ret = (np.pi - math.atan2(-y, -x)) / (2 * np.pi)
        return ret

    def __sat(self, z):
        sharp = 1.0 / 2.0
        satAux = np.log(np.sqrt(z.real * z.real + z.imag * z.imag)) / np.log(1.5)
        ret = np.clip(sharp * (satAux - np.floor(satAux)) + 0.7, 0.0, 1.0)
        return ret

    def __val(self, z):
        sharp = 1.0 / 2.0
        nContour = 16  # how many contour lines

        phase = (np.pi - np.arctan2(z.imag, -z.real)) / (2 * np.pi)  # 0...1
        valAux = nContour * phase
        ret = np.clip(sharp * (valAux - np.floor(valAux)) + 0.7, 0.0, 1.0)
        return ret

    def __plot(self, F, cmap):

        cmap = matplotlib.colormaps[cmap]
        img = np.zeros((self.height, self.width, 3))

        print(f"img: {img.shape}, F: {F.shape}")
        # hue, saturation, Value -> HSV or HSB
        # using hue from cmap and value for modulo and phase
        for j in range(self.width):
            for i in range(self.height):
                #print(f'i = {i}, j = {j}')
                #print(f'F = {F[i, j]}')
                hue = self.__hue(F.real[i][j], F.imag[i][j])

                # choose either modulo, phase or enhanced
                modulo = self.__sat(F.real[i][j], F.imag[i][j])
                phase = self.__val(F.real[i][j], F.imag[i][j])
                enhanced = min(modulo, phase)

                img[i][j] = cmap(hue)[:3]
                img[i][j] *= phase
                img[i][j] *= 255

        return np.transpose(img, (1, 0, 2))

    def __plot2(self, F, cmap):

        cmap = matplotlib.colormaps[cmap]
        img = np.zeros((self.height, self.width, 3))

        #print(f"img: {img.shape}, F: {F.shape}")
        bpm2pi =  abs(np.sin(self.bpm/3))
        hue = (np.pi - np.arctan2(-F.imag, -F.real))*bpm2pi / (2 * np.pi)

        # choose either modulo, phase or enhanced
        modulo = self.__sat(F)
        phase = self.__val(F)
        enhanced = np.minimum(modulo, phase)

        selected = enhanced

        img = cmap(hue)[:, :, :3]
        img = np.stack((img[:, :, 0] * selected, img[:, :, 1] * selected, img[:, :, 2] * selected),
                       axis=2)

        return np.transpose(img, (1, 0, 2))

    def plot_complex_function(self, complex_function, cmap='twilight'):
        """
        Plot the complex function
        e.g:
        def complex_function(z):
            return (z - 1) / ((z ** 2) + z + 1)
        :param complex_function: the z function which will be plotted
        :return image of complex function domain colouring
        """
        #start_time = time.time()
        # Which function to use
        F = complex_function(self.Z)
        # F = complex_power_function(Z, 3 - 2j)
        img = self.__plot2(F, cmap=cmap)
        #print("--- %s seconds ---" % (time.time() - start_time))
        return img

    def plot_complex_power_function(self, power_function, c, cmap='twilight'):
        """
        Plot the complex power function
        e.g:
            def complex_power_function(z, c):
                ret = np.exp(c * np.log(z))
                return ret
        :param power_function: the z power function which will be plotted
        :param c: complex input variable c
        :return image of complex function domain colouring
        """
        #start_time = time.time()
        # Which function to use
        #F = complex_function(self.Z)
        F = complex_power_function(self.Z, c)
        img = self.__plot2(F, cmap=cmap)
        #print("--- %s seconds ---" % (time.time() - start_time))
        return img
    def setBPM(self, bpm):
        self.bpm = bpm


def complex_function(z):
    return (z - 1) / ((z ** 2) + z + 1)


def complex_power_function(z, c):
    #ret =  math.exp(c * math.log(z))
    ret = np.exp(c * np.log(z))
    #print(ret)
    return ret


def main():
    dc = DomainColoring(800, 600)
    img = dc.plot_complex_function(complex_function, cmap='twilight')
    plt.imshow(img)
    plt.show()

if __name__ == "__main__":
    main()
