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
            #sphere.Sphere((-10+i*5 -(i//5)*25,0,10-(i//5)*4),2, (0,0,1), type=0, reflectivity=0) for i in range(0,30)
        ]
        colors = [(1,1,1),(0.7,0.7,0.7)]
        reflectivities = [0,0.5]
        cpt = 0
        for i in range(-60,180,30):
            for j in range(-60,90,30):
                self.spheres.append(sphere.Sphere((i,0,j),14.99, colors[cpt], type=1, reflectivity=reflectivities[cpt]))
                cpt = not cpt
        self.spheres.append(sphere.Sphere((0,-14,0),14, (1,0,0), type=0, reflectivity=0))
        self.spheres.append(sphere.Sphere((100,-14,0),14, (0,1,0), type=0, reflectivity=0))


        self.camera = camera.Camera(
            position = [0, 0, 0]
        )