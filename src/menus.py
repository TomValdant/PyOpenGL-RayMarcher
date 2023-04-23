import pygame
from config import *

class resMenu():

    def __init__(self, app) -> None:
        self.app = app
        self.font = pygame.font.SysFont("Arial", 20)
        self.inMenu = False

        self.doneTxt = self.font.render("Done", True, (255, 255, 255))
        self.doneRect = self.doneTxt.get_rect()
        self.doneRect.center = (self.app.res/2, self.app.res/2)

        # slider not finished
        self.slider = pygame.Rect(self.app.res/2 - 100, self.app.res/2 - 10, 200, 20)

    def render(self):
            
            #self.app.screen.fill((21, 12, 80))
            self.screen.fill((21, 12, 80))
    
            # render a slider (not finished)
            pygame.draw.rect(self.screen, (255, 255, 255), self.slider)
    
            # render a Done button
            mouse = pygame.mouse.get_pos()
            if self.doneRect.collidepoint(mouse):
                self.doneTxt = self.font.render("Done", True, (255, 0, 0))
            else:
                self.doneTxt = self.font.render("Done", True, (255, 255, 255))
    
            self.screen.blit(self.doneTxt, self.doneRect)

            pygame.display.flip()

    def mainLoop(self):
        while self.inMenu:
            self.app.clock.tick(60)
            self.render()
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.inMenu = False
                    self.app.running = False
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.inMenu = False
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if self.doneRect.collidepoint(event.pos):
                        self.inMenu = False

    def show(self, screen):
        self.inMenu = True
        self.screen = screen
        self.mainLoop()

class pauseMenu():

    def __init__(self, app) -> None:
        self.app = app
        self.font = pygame.font.SysFont("Arial", 54)
        self.inMenu = False
        self.options = resMenu(self.app)

        self.resumeTxt = self.font.render("Resume", True, (255, 255, 255))
        self.resumeRect = self.resumeTxt.get_rect()
        self.resumeRect.center = (self.app.screenWidth/2, self.app.screenWidth/2 - 60)

        self.optionsTxt = self.font.render("Options", True, (255, 255, 255))
        self.optionsRect = self.optionsTxt.get_rect()
        self.optionsRect.center = (self.app.screenWidth/2, self.app.screenWidth/2 + 30)

        self.quitTxt = self.font.render("Quit", True, (255, 255, 255))
        self.quitRect = self.quitTxt.get_rect()
        self.quitRect.center = (self.app.screenWidth/2, self.app.screenWidth/2 + 120)

    def render(self):

        self.screen.fill((21, 12, 80))

        # render a Resume button ----------------------
        
        # check if the mouse is over the button
        mouse = pygame.mouse.get_pos()
        if self.resumeRect.collidepoint(mouse):
            self.resumeTxt = self.font.render("Resume", True, (255, 0, 0))
        else:
            self.resumeTxt = self.font.render("Resume", True, (255, 255, 255))

        self.screen.blit(self.resumeTxt, self.resumeRect)


        # render a Options button ----------------------

        # check if the mouse is over the button
        if self.optionsRect.collidepoint(mouse):
            self.optionsTxt = self.font.render("Options", True, (255, 0, 0))
        else:
            self.optionsTxt = self.font.render("Options", True, (255, 255, 255))

        self.screen.blit(self.optionsTxt, self.optionsRect)


        # render a Quit button ----------------------

        # check if the mouse is over the button
        if self.quitRect.collidepoint(mouse):
            self.quitTxt = self.font.render("Quit", True, (255, 0, 0))
        else:
            self.quitTxt = self.font.render("Quit", True, (255, 255, 255))
        
        self.screen.blit(self.quitTxt, self.quitRect)
        

        # draw surface to openGl texture
        # texture = surfaceToTexture(self.surf)
        

        # glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)



        #self.screen.blit(self.surf, (0, 0))

        pygame.display.flip()




        #pygame.display.flip()

    def mainLoop(self):
        while self.inMenu:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.app.running = False
                    self.inMenu = False
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.inMenu = False
                        pygame.mouse.set_pos(self.app.screenWidth/2, self.app.screenHeight/2)
                # check if user clicked on buttons
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if self.resumeRect.collidepoint(event.pos):
                        self.inMenu = False
                        pygame.mouse.set_pos(self.app.screenWidth/2, self.app.screenHeight/2)
                    if self.optionsRect.collidepoint(event.pos):
                        self.options.show(self.screen)
                    if self.quitRect.collidepoint(event.pos):
                        self.app.running = False
                        self.inMenu = False
                        

            self.render()
            self.app.clock.tick(60)

    def show(self):
        self.inMenu = True
        pygame.mouse.set_visible(True)
        self.screen = pygame.display.set_mode((self.app.screenWidth, self.app.screenHeight))
        self.mainLoop()
