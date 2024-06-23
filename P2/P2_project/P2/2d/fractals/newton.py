import matplotlib
from scipy.optimize import fsolve
import numpy as np
from matplotlib import pyplot as plt
from matplotlib.colors import ListedColormap

# TODO Zoom and parallize
class NewtonFractal:
    def __init__(self, width, height, max_iter, xmin, xmax, ymin, ymax):
        self.width = width
        self.height = height
        self.max_iter = max_iter
        self.tol = 1e-8
        self.xmin = xmin
        self.xmax = xmax
        self.ymin = ymin
        self.ymax = ymax

        self.img = np.full((self.width, self.height, 3), [0, 0, 0], dtype=np.uint8)
        self.x = np.linspace(0, self.width, num=width, dtype=np.float32)
        self.y = np.linspace(0, self.height, num=height, dtype=np.float32)

        self.img = np.zeros((width, height))

    def newton(self, z0, f, fprime):
        z = z0
        for i in range(self.max_iter):
            dz = f(z) / fprime(z)
            if abs(dz) < self.tol:
                return z
            z -= dz
        return False

    def get_root_index(self, r, roots):
        try:
            print(f"isclose: {np.isclose(roots, r, atol=self.tol)}")
            print(f"where: {np.where(np.isclose(roots, r, atol=self.tol))}")
            return np.where(np.isclose(roots, r, atol=self.tol))[0][0]
        except IndexError:
            roots.append(r)
            return len(roots) - 1

    def get_root_index2(self, r, roots):
        ret = (len(roots)+1) * np.ones(r.shape)
        for root in roots:
            check = r - root
            ret = np.where((check.real*check.real + check.imag * check.imag) < self.tol*self.tol, roots.index(root), ret)

        return ret


    def render(self, f, fprime):
        roots = []
        X = np.linspace(self.xmin, self.xmax, self.width)
        Y = np.linspace(self.ymin, self.ymax, self.height)

        for ix, x in enumerate(X):
            for iy, y in enumerate(Y):
                z0 = x + y * 1j
                r = self.newton(z0, f, fprime)
                if r is not False:
                    ir = self.get_root_index(r, roots)
                    self.img[ix, iy] = ir

        print(f"Roots: {roots}")
        return self.img

    def render2(self, f, fprime, roots, cmap='twilight'):
        cmap = matplotlib.colormaps[cmap]
        X = np.linspace(self.xmin, self.xmax, self.width)
        Y = np.linspace(self.ymin, self.ymax, self.height)

        R = X + 1j * Y[:, None]
        iter = np.full(R.shape, self.max_iter)
        dR = np.ones(R.shape, dtype=np.complex64)
        for i in range(self.max_iter):
            mask = (iter == self.max_iter)
            dR[mask] = f(R[mask]) / fprime(R[mask])
            iter[mask & ((dR.real * dR.real + dR.imag * dR.imag) < (self.tol * self.tol))] = i + 1
            R[mask] -= dR[mask]

        iR = self.get_root_index2(R, roots).T
        self.img = cmap(iR / (len(roots)+1))[:, :, :3]
        return self.img


if __name__ == "__main__":
    newton = NewtonFractal(1600, 900, 1000, -1.5, 1.5, -1.5, 1.5)

    f = lambda  z: z ** 4 - 1
    fprime = lambda z: 4 * z ** 3
    img = newton.render2(f, fprime, [-1, -1j, 1, 1j])



    plt.imshow(img, cmap='hsv', origin='lower')
    plt.axis('off')
    plt.show()
