import numpy as np
from matplotlib import pyplot as plt

# implemented just as reference to speed up other fractals
class Mandelbrot:
    def __init__(self, width, height, max_iterations, offset, zoom):
        self.width = width
        self.height = height
        self.max_iterations = max_iterations
        self.offset = offset
        self.zoom = zoom

        self.img = np.full((self.width, self.height, 3), [0,0,0], dtype=np.uint8)
        self.x = np.linspace(0, self.width, num=width, dtype=np.float32)
        self.y = np.linspace(0, self.height, num=height, dtype=np.float32)

    def render2(self):
        for x in range(self.width):
            for y in range(self.height):
                c = (x - self.offset[0]) * self.zoom + 1j * (y - self.offset[1]) * self.zoom
                z = 0
                iter = 0
                for i in range(self.max_iterations):
                    z = z**2 + c
                    if abs(z) > 2:
                        break
                    iter += 1
                color = int (255 * iter / self.max_iterations)
                self.img[x, y] = (color, color, color)

        return self.img

    def render(self):
        X = (self.x - self.offset[0]) * self.zoom
        Y = (self.y - self.offset[1]) * self.zoom
        c = X + 1j * Y[:, None]

        iter = np.full(c.shape, self.max_iterations)
        Z = np.zeros(c.shape, dtype=np.complex64)
        for i in range(self.max_iterations):
            mask = (iter == self.max_iterations)
            Z[mask] = Z[mask] ** 2 + c[mask]
            iter[mask & (Z.real * Z.real + Z.imag * Z.imag > 4.0)] = i + 1

        color = (255 * iter.T / self.max_iterations).astype(np.uint8)
        self.img = np.stack((color, color, color), axis=2)

        return self.img.copy()



if __name__ == "__main__":
    zoom = 2.2 / 600
    offset = np.array([1.3 * 800, 600]) // 2
    mandelbrot = Mandelbrot(800, 600, 30,  offset, zoom)

    img = mandelbrot.render2()
    img = mandelbrot.render2()
    img = mandelbrot.render2()
    img = mandelbrot.render2()
    img = mandelbrot.render2()
    plt.imshow(img)
    plt.show()

