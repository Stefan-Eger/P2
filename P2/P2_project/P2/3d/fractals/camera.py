import numpy as np

from numpy.linalg import inv

class Camera:
    def __init__(self):
        self.camInvTranslate2World = np.eye(4, dtype=np.float32)
        self.camRotate2World = np.eye(4, dtype=np.float32)

        self.SPEED_MOVEMENT = 2.0
        self.SPEED_ROTATION = 5.0

    def __translate(self, matrix, x, y, z):
        """
        [Column][Row]
        """
        ret = matrix
        ret[3, 0] -= x
        ret[3, 1] -= y
        ret[3, 2] -= z
        return ret

    def movement(self, direction):
        """

        :param direction: using [x, y, z] direction
        :return:
        """
        # multiply in order to take rotation into account
        translate = self.camRotate2World @ np.array([direction[0], direction[1], direction[2], 1.0], dtype=np.float32)
        self.__translate(self.camInvTranslate2World, translate[0], translate[1], translate[2])


    def __skewMat(self, u):
        """
        [Column][Row]
        """
        mat = np.zeros((3,3), dtype=np.float32)
        ux, uy, uz = u[0], u[1], u[2]
        mat[0][1] = uz
        mat[0][2] = -uy

        mat[1][0] = -uz
        mat[1][2] = ux

        mat[2][0] = uy
        mat[2][1] = -ux

        return mat
    def rotate(self, axis, theta):
        c, s = np.cos(theta), np.sin(theta)
        n = axis / np.linalg.norm(axis)
        rotation = np.eye(4, dtype=np.float32)
        # Rodrigues rotation formula
        mat = c * np.eye(3, dtype=np.float32) + s * self.__skewMat(n) + (1-c) * np.outer(n, n)
        rotation[0:3, 0:3] = mat

        self.camRotate2World = rotation @ self.camRotate2World



    def getViewMatrix(self):
        return self.camRotate2World.T @ self.camInvTranslate2World

    def getRotationMatrix(self):
        return self.camRotate2World