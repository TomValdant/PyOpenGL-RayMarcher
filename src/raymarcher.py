from config import *
import app
import scene

if __name__ == "__main__":
    myScene = scene.Scene()
    myApp = app.App(myScene, 600)
    myApp.quit()