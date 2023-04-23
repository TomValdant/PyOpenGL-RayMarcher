from config import *
import engine
import scene
import time
import menus

class App:
    """
        Calls high level control functions (handle input, draw scene etc)
    """

    def __init__(self, scene, res):

        pg.init()
        self.screenWidth = 1000
        self.screenHeight = 1000
        self.res = res
        self.pauseMenu = menus.pauseMenu(self)
        pg.display.gl_set_attribute(pg.GL_CONTEXT_MAJOR_VERSION, 4)
        pg.display.gl_set_attribute(pg.GL_CONTEXT_MINOR_VERSION, 3)
        pg.display.gl_set_attribute(pg.GL_CONTEXT_PROFILE_MASK,
                                    pg.GL_CONTEXT_PROFILE_CORE)
        pg.display.set_mode((self.screenHeight, self.screenWidth), pg.OPENGL|pg.DOUBLEBUF)
        pg.display.set_caption("Ray Marcher")
        pg.mouse.set_visible(False)
        pg.event.set_grab(True)

        self.graphicsEngine = engine.Engine(self.res, self.res)
        self.scene = scene

        self.lastTime = pg.time.get_ticks()
        self.currentTime = 0
        self.numFrames = 0
        self.frameTime = 0
        self.lightCount = 0
        self.clock = pg.time.Clock()

        self.mainLoop()
    
    def mainLoop(self):

        self.running = True
        while (self.running):
            #events
            for event in pg.event.get():
                if (event.type == pg.QUIT):
                    running = False
                if (event.type == pg.KEYDOWN):
                    if (event.key == pg.K_ESCAPE):
                        self.pauseMenu.show()
                        if not self.running:
                            break
                        self.__init__(self.scene, self.res)

            if not self.running:
                break

            playerDirZ = [0,0]
            playerDirZ[0] = cos(self.scene.camera.forwards[0])
            playerDirZ[1] = sin(self.scene.camera.forwards[0])

            playerDirX = [0,0]
            playerDirX[0] = cos(self.scene.camera.forwards[0] + pi/2)
            playerDirX[1] = sin(self.scene.camera.forwards[0] + pi/2)

            mouse = pg.mouse.get_pos()
            self.scene.camera.forwards[0] += (mouse[0] - self.screenWidth/2) / 1000
            self.scene.camera.forwards[1] -= (mouse[1] - self.screenHeight/2) / 1000
            pg.mouse.set_pos((self.screenWidth/2, self.screenHeight/2))

            moveStep = 0.3
            
            keys = pg.key.get_pressed()
            #if keys[pg.K_ESCAPE]:
                #self.pauseMenu.show()
            if keys[pg.K_z]:
                self.scene.camera.position[2] += playerDirZ[0]*moveStep
                self.scene.camera.position[0] += playerDirZ[1]*moveStep
            if keys[pg.K_s]:
                self.scene.camera.position[2] -= playerDirZ[0]*moveStep
                self.scene.camera.position[0] -= playerDirZ[1]*moveStep
            if keys[pg.K_q]:
                self.scene.camera.position[2] -= playerDirX[0]*moveStep
                self.scene.camera.position[0] -= playerDirX[1]*moveStep
            if keys[pg.K_d]:
                self.scene.camera.position[2] += playerDirX[0]*moveStep
                self.scene.camera.position[0] += playerDirX[1]*moveStep
            if keys[pg.K_SPACE]:
                self.scene.camera.position[1] -= moveStep
            if keys[pg.K_LSHIFT]:
                self.scene.camera.position[1] += moveStep
            if keys[pg.K_RIGHT]:
                self.scene.camera.forwards[0] += 0.05
            if keys[pg.K_LEFT]:
                self.scene.camera.forwards[0] -= 0.05
            if keys[pg.K_UP]:
                self.scene.camera.forwards[1] += 0.05
            if keys[pg.K_DOWN]:
                self.scene.camera.forwards[1] -= 0.05
            
            self.scene.spheres[-2].center[0] = 75*cos(time.time())
            self.scene.spheres[-2].center[1] = 20*(cos(time.time()*3) -1)
            self.scene.spheres[-2].center[2] = 75*sin(time.time())

            #render
            self.graphicsEngine.renderScene(self.scene)
            
            self.clock.tick(60)

            #timing
            self.calculateFramerate()
        self.quit()
    
    def calculateFramerate(self):

        self.currentTime = pg.time.get_ticks()
        delta = self.currentTime - self.lastTime
        if (delta >= 1000):
            framerate = max(1,int(1000.0 * self.numFrames/delta))
            pg.display.set_caption(f"Running at {framerate} fps.")
            self.lastTime = self.currentTime
            self.numFrames = -1
            self.frameTime = float(1000.0 / max(1,framerate))
        self.numFrames += 1

    def quit(self):
        #self.graphicsEngine.destroy()
        pg.quit()