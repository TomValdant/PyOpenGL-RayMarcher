from config import *
import sphere
import camera

class Scene:
    """
        Holds pointers to all objects in the scene
    """


    def __init__(self):
        """
            Set up scene objects.
        """
        
        self.spheres = [
            sphere.Sphere((-10+i*5 -(i//5)*25,0,10-(i//5)*4),2, (0,0,1), type=0, reflectivity=0) for i in range(0,2)
        ]
        self.spheres.append(sphere.Sphere((0,0,10),2, (1,0,0), type=1, reflectivity=0))
        self.camera = camera.Camera(
            position = [0, 0, 0]
        )