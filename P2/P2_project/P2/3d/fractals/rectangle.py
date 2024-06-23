import numpy as np
from OpenGL.GL import *


class Rectangle:
    def __init__(self):
        # x, y, z, r, g, b
        self.vertices = (
            1.0, 1.0, 0.0,      # top right
            1.0, -1.0, 0.0,     # bottom right
            -1.0, -1.0, 0.0,    # bottom left
            -1.0, 1.0, 0.0      # top left
        )
        self.indices = (
            0, 1, 3,
            1, 2, 3
        )

        self.vertices = np.array(self.vertices, dtype=np.float32)
        self.indices = np.array(self.indices, dtype=np.int32)
        self.vertex_count = 4

        # Vertex Arttribute Object
        self.vao = glGenVertexArrays(1)
        glBindVertexArray(self.vao)

        # VERTICES
        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, self.vertices.nbytes, self.vertices, GL_STATIC_DRAW)

        # INDICES
        self.ebo = glGenBuffers(1)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.indices.nbytes, self.indices, GL_STATIC_DRAW)

        # index of buffer(layout) (1 element contains 3 and one line of data is 6 * 4 (sizeof(float)) (stride),
        # void* -> offest in bytes)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 12, ctypes.c_void_p(0))


    def destroy(self):
        glDeleteVertexArrays(1, [self.vao])
        glDeleteBuffers(2, [self.vbo, self.ebo])
