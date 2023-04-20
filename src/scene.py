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
            sphere.Sphere((-10+i*5 -(i//5)*25,0,10-(i//5)*4),2, (0,0,1), type=0, reflectivity=0) for i in range(0,3)
        ]
        self.spheres.append(sphere.Sphere((0,8,10),20, (0,0,0), type=1, reflectivity=0.4))
        self.spheres.append(sphere.Sphere((30,8,10),10, (0.2,1,0.5), type=1, reflectivity=0.5))
        self.spheres[0].reflectivity = 0
        self.spheres[0].color = (1,0,0)
        self.spheres[0].center = (-2.5, 6, 14)
        self.spheres[0].radius = 4
        self.spheres.append(sphere.Sphere((-30,-10,30),20, (0.2,1,0.5), type=0, reflectivity=0))
        self.camera = camera.Camera(
            position = [0, 0, 0]
        )