import numpy as np
import pygame as pg
from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader

from camera import Camera
from rectangle import Rectangle
from P2.util.UDP_Input import UDP_Input

VERTEX_FILEPATH = 'shaders/vertex.glsl'
FRAGMENT_FILEPATH = 'shaders/fragment.glsl'

HORIZONTAL_FOV = 90.0

class Raymarching:
    def __init__(self, width, height, cam_data=None):
        # UDP Address and port input
        self.cam_data = cam_data

        pg.init()
        pg.display.set_mode((width, height), pg.OPENGL|pg.DOUBLEBUF)
        self.clock = pg.time.Clock()
        glClearColor(0.1, 0.1, 0.1, 1.0)
        self.running = True
        self.runTime = 0.0
        self.width = width
        self.height = height
        self.dt = 0.0

        self.shaderProgram = self.__createShaderProgram()
        glUseProgram(self.shaderProgram)

        # init constant Buffers
        self.__initBuffer()
        # init buffers which change over run time
        self.timeLocation = glGetUniformLocation(self.shaderProgram, "u_time")
        self.cam2WorldLocation = glGetUniformLocation(self.shaderProgram, "u_cam_to_world")
        self.camBPMLocation = glGetUniformLocation(self.shaderProgram, "u_cam_bpm")

        self.camera = Camera()
        self.camera.movement(np.array([0, 0, -2.0]))
        self.rectangle = Rectangle()
        self.loop()
    def __initBuffer(self):
        # uniform buffer for window and camera
        resolutionLocation = glGetUniformLocation(self.shaderProgram, "u_resolution")
        glUniform2f(resolutionLocation, self.width, self.height)

        invResolutionLocation = glGetUniformLocation(self.shaderProgram, "u_inv_resolution")
        glUniform2f(invResolutionLocation, np.float32(1.0 / self.width), np.float32(1.0 / self.height))

        aspectRatioLocation = glGetUniformLocation(self.shaderProgram, "u_aspect_ratio")
        glUniform1f(aspectRatioLocation, np.float32(self.width / self.height))

        horizontalFOVLocation = glGetUniformLocation(self.shaderProgram, "u_hfov")
        fov = self.__deg2rad(0.5 * HORIZONTAL_FOV)
        fov = np.tan(fov)
        print("fov: ", fov)
        glUniform1f(horizontalFOVLocation, fov)

    def __deg2rad(self, deg):
        return deg * np.pi / 180.0

    def __keyDownListener(self, event):
        if event.key == pg.K_ESCAPE:
            self.running = False

        if event.key == pg.K_KP_ENTER:
            print(f"CAM2World: \n{self.camera.getViewMatrix()}")

    def __keyPressedListener(self, keys):
        if keys[pg.K_w]:
            dir = np.array([0.0, 0.0, 1.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_s]:
            dir = np.array([0.0, 0.0, -1.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_a]:
            dir = np.array([1.0, 0.0, 0.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_d]:
            dir = np.array([-1.0, 0.0, 0.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_SPACE]:
            dir = np.array([0.0, -1.0, 0.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_LSHIFT]:
            dir = np.array([0.0, 1.0, 0.0], dtype=np.float32).T * self.camera.SPEED_MOVEMENT * self.dt
            self.camera.movement(dir)

        if keys[pg.K_j]:
            angle = self.camera.SPEED_ROTATION * self.dt * -1.0
            axis = self.camera.getRotationMatrix() @ np.array([0.0, 1.0, 0.0, 1.0])
            self.camera.rotate(axis[0:3], angle)

        if keys[pg.K_l]:
            angle = self.camera.SPEED_ROTATION * self.dt * 1.0
            axis = self.camera.getRotationMatrix() @ np.array([0.0, 1.0, 0.0, 1.0])
            self.camera.rotate(axis[0:3], angle)

        if keys[pg.K_i]:
            angle = self.camera.SPEED_ROTATION * self.dt * -1.0
            axis = self.camera.getRotationMatrix() @ np.array([1.0, 0.0, 0.0, 1.0])
            self.camera.rotate(axis[0:3], angle)

        if keys[pg.K_k]:
            angle = self.camera.SPEED_ROTATION * self.dt * 1.0
            axis = self.camera.getRotationMatrix() @ np.array([1.0, 0.0, 0.0, 1.0])
            self.camera.rotate(axis[0:3], angle)

        if keys[pg.K_e]:
            angle = self.camera.SPEED_ROTATION * self.dt * 1.0
            axis = self.camera.getRotationMatrix() @ np.array([0.0, 0.0, 1.0, 1.0])
            self.camera.rotate(axis[0:3], angle)
        if keys[pg.K_q]:
            angle = self.camera.SPEED_ROTATION * self.dt * -1.0
            axis = self.camera.getRotationMatrix() @ np.array([0.0, 0.0, 1.0, 1.0])
            self.camera.rotate(axis[0:3], angle)



    def __mouseWheelListener(self, event):
        if event.y < 0:
            x, y = pg.mouse.get_pos()
            print(f'Scroll Up x: {x} and y: {y}')
        elif event.y > 0:
            x, y = pg.mouse.get_pos()
            print(f'Scroll Down x: {x} and y: {y}')

    def __EventListener(self):
        for event in pg.event.get():
            if event.type == pg.QUIT:
                self.running = False
            elif event.type == pg.KEYDOWN:
                self.__keyDownListener(event)
            elif event.type == pg.MOUSEWHEEL:
                self.__mouseWheelListener(event)

            keys = pg.key.get_pressed()
            self.__keyPressedListener(keys)

    def __createShaderProgram(self):
        with open(VERTEX_FILEPATH, 'r') as f:
            vertex_src = f.read()
        with open(FRAGMENT_FILEPATH, 'r') as f:
            fragment_src = f.read()

        shaderProgram = compileProgram(
            compileShader(vertex_src, GL_VERTEX_SHADER),
            compileShader(fragment_src, GL_FRAGMENT_SHADER)
        )
        return shaderProgram

    def loop(self):
        while self.running:
            self.__EventListener()

            # get UDP Inputs
            bpm = 0.0
            if self.cam_data is not None:
                bpm = self.cam_data.getValue()

            # draw new Frame
            self.dt = self.clock.get_time() / 1000.0
            glClear(GL_COLOR_BUFFER_BIT)
            # update Fragment UBO
            glUniform1f(self.timeLocation, np.float32(self.runTime))
            glUniform1f(self.camBPMLocation, np.float32(bpm))
            glUniformMatrix4fv(self.cam2WorldLocation, 1, GL_FALSE, self.camera.getViewMatrix())
            glUseProgram(self.shaderProgram)
            # draw Rectangle on which is used to display the fragment shader
            glBindVertexArray(self.rectangle.vao)
            glDrawElements(GL_TRIANGLES, self.rectangle.indices.size, GL_UNSIGNED_INT,  ctypes.c_void_p(0))
            pg.display.flip()

            glBindVertexArray(0)
            self.clock.tick(60)
            self.runTime += self.clock.get_time() / 1000.0

            #pg.display.set_caption(f"BPM: {bpm:.2f}")
            pg.display.set_caption(f"FPS: {self.clock.get_fps() :.2f}")
            #pg.display.set_caption(f"Runtime: {self.runTime :.2f}")

        self.quit()

    def quit(self):
        self.rectangle.destroy()
        glDeleteProgram(self.shaderProgram)
        pg.quit()





if __name__ == '__main__':
    np.set_printoptions(suppress=True)

    cam_data = UDP_Input()
    raymarcher = Raymarching(800, 800, cam_data)
    cam_data.close()