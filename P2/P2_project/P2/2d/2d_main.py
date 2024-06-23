import numpy as np
import pygame

from fractals.mandelbrot import Mandelbrot
from fractals.newton import NewtonFractal
from P2.util.UDP_Input import UDP_Input
from phase_portraits.domain_coloring import DomainColoring


class P2_Engine:
    def __init__(self, zfunc, ztype='simple', cam_data=None, cmap='hsv', title='None', width=800, height=600, background_color=(0, 0, 0)):
        # Pygame Variables
        self.title = title
        self.width = width
        self.height = height
        self.background_color = background_color
        self.clock = pygame.time.Clock()
        self.zoom = 1.0

        # UDP Address and port input
        self.cam_data = cam_data

        # Domain Coloring function
        self.zfunc = zfunc # z function
        self.ztype = ztype # simple or exponential
        self.cmap = cmap

        # Domain Coloring Init
        self.phase_portraits = DomainColoring(width, height)

        # Fractal Mandelbrot Init
        self.zoom = 2.2 / height
        self.offset = np.array([1.3 * width, height]) // 2
        self.mandelbrot = Mandelbrot(self.width, self.height, 30, self.offset, self.zoom)

        # Newton Fractal Init
        self.newton = NewtonFractal(self.width, self.height, 1000, -2, 2, -2, 2)

        # Pygame initialization
        pygame.init()
        self.window = pygame.display.set_mode((width, height), pygame.SCALED)
        pygame.display.set_caption(self.title)

        self.running = True
        self.debug = True

    def __keyboardListener(self, event):
        if event.key == pygame.K_ESCAPE:
            self.running = False
        if event.key == pygame.K_SPACE:
            self.debug = False

    def __mouseWheelListener(self, event):
        if event.y < 0:
            x, y = pygame.mouse.get_pos()
            print(f'Scroll Up x: {x} and y: {y}')
            self.mandelbrot.zoom += 1.0 / self.height
        elif event.y > 0:
            x, y = pygame.mouse.get_pos()
            print(f'Scroll Down x: {x} and y: {y}')
            self.mandelbrot.zoom -= 1.0 / self.height

    def __EventListener(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                self.__keyboardListener(event)
            elif event.type == pygame.MOUSEWHEEL:
                self.__mouseWheelListener(event)

    def loop(self):
        while self.running:
            # Listening for all Inputs
            self.__EventListener()

            # get UDP Inputs
            bpm = 0.0
            if self.cam_data is not None:
                bpm = self.cam_data.getValue()
                self.phase_portraits.setBPM(bpm)
                #bpm = int(bpm) % 20 + 1
                bpm = 3*np.sin(bpm * 0.5) + 1

            # Update Current Image
            self.window.fill(self.background_color)

            # PHASE PORTRAITS
            # img = self.phase_portraits.plot_complex_function(lambda z: (z - 1) / ((z ** 2) + z + 1)) * 255
            if self.ztype == 'simple':
                img = self.phase_portraits.plot_complex_function(self.zfunc, cmap=self.cmap) * 255
            elif self.ztype == 'exponential':
                img = self.phase_portraits.plot_complex_power_function(self.zfunc, c=bpm + 1j * bpm, cmap=self.cmap) * 255

            # MANDELBROT
            # img = self.mandelbrot.render()

            # NEWTON FRACTAL
            #f = lambda z: z ** 4 - 1
            #fprime = lambda z: 4 * z ** 3
            #img = self.newton.render2(f, fprime, [-1, -1j, 1, 1j], cmap='twilight') * 255

            # pushing img to framebuffer
            current_image = pygame.surfarray.make_surface(img)
            self.window.blit(current_image, (0, 0))
            pygame.display.flip()

            # Show FPS
            self.clock.tick()
            pygame.display.set_caption(f"FPS: {self.clock.get_fps() :.2f}")
            # pygame.display.set_caption("f(z) = z**4 - 1, f'(z) = 4 * z**3")


def main():
    cam_data = UDP_Input()

    app = P2_Engine(lambda z: z**4 - 1, cmap='hsv', cam_data=cam_data)
    #app = P2_Engine(lambda z: (z - 1) / ((z ** 2) + z + 1), cmap='hsv', cam_data=cam_data)
    #app = P2_Engine(lambda z, c: np.exp(c * np.log(z)), ztype='exponential', cmap='inferno', cam_data=cam_data)
    app.loop()

    cam_data.close()


# starting Engine
if __name__ == "__main__":
    main()
