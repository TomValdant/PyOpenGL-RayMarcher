import pygame
from config import *

# This entire file needs to be rewritten using inheritance and rendering all the assests of each menu
# in a for loop. This will make it easier to add more menus and make the code more readable.

class resMenu():

    def __init__(self, app) -> None:
        self.app = app
        self.font = pygame.font.SysFont("Arial", 54)
        self.inMenu = False

        self.doneTxt = self.font.render("Done", True, (255, 255, 255))
        self.doneRect = self.doneTxt.get_rect()
        self.doneRect.center = (self.app.screenWidth/2, self.app.screenWidth/2 + 100)

        # slider not finished
        #self.slider = pygame.Rect(self.app.res/2 - 100, self.app.res/2 - 10, 200, 20)
        
        # temporary buttons to chose resolution between 250, 600, 1000
        self.res1Txt = self.font.render("250", True, (255, 255, 255))
        self.res1Rect = self.res1Txt.get_rect()
        self.res1Rect.center = (self.app.screenWidth/2 - 150, self.app.screenWidth/2)

        self.res2Txt = self.font.render("600", True, (255, 255, 255))
        self.res2Rect = self.res2Txt.get_rect()
        self.res2Rect.center = (self.app.screenWidth/2, self.app.screenWidth/2)

        self.res3Txt = self.font.render("1000", True, (255, 255, 255))
        self.res3Rect = self.res3Txt.get_rect()
        self.res3Rect.center = (self.app.screenWidth/2 + 150, self.app.screenWidth/2)

        # rectangle that contains all the res buttons
        self.resRect = pygame.Rect(self.app.screenWidth/2 - 250, self.app.screenWidth/2 - 50, 500, 100)

        # Resolution text on top of the rectangle
        self.resTxt = self.font.render("Resolution", True, (255, 255, 255))
        self.resTxtRect = self.resTxt.get_rect()
        self.resTxtRect.center = (self.app.screenWidth/2, self.app.screenWidth/2 - 100)


    def render(self):
            
            #self.app.screen.fill((21, 12, 80))
            self.screen.fill((21, 12, 80))
            mouse = pygame.mouse.get_pos()
    
            # render a slider (not finished)
            # pygame.draw.rect(self.screen, (255, 255, 255), self.slider)

            # render the res buttons (temporary)
            # bad design, will be changed later
            if self.res1Rect.collidepoint(mouse):
                self.res1Txt = self.font.render("250", True, (255, 0, 0))
            else:
                self.res1Txt = self.font.render("250", True, (255, 255, 255))

            self.screen.blit(self.res1Txt, self.res1Rect)

            if self.res2Rect.collidepoint(mouse):
                self.res2Txt = self.font.render("600", True, (255, 0, 0))
            else:
                self.res2Txt = self.font.render("600", True, (255, 255, 255))

            self.screen.blit(self.res2Txt, self.res2Rect)

            if self.res3Rect.collidepoint(mouse):
                self.res3Txt = self.font.render("1000", True, (255, 0, 0))
            else:
                self.res3Txt = self.font.render("1000", True, (255, 255, 255))

            self.screen.blit(self.res3Txt, self.res3Rect)

    
            # render a Done button
            
            if self.doneRect.collidepoint(mouse):
                self.doneTxt = self.font.render("Done", True, (255, 0, 0))
            else:
                self.doneTxt = self.font.render("Done", True, (255, 255, 255))
    
            self.screen.blit(self.doneTxt, self.doneRect)

            # render rectangle that contains all the res buttons
            pygame.draw.rect(self.screen, (255, 255, 255), self.resRect, 2)

            # render Resolution text on top of the rectangle
            self.screen.blit(self.resTxt, self.resTxtRect)

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
                # bad design, will be changed later
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if self.doneRect.collidepoint(event.pos):
                        self.inMenu = False
                    if self.res1Rect.collidepoint(event.pos):
                        self.app.res = 250
                        self.inMenu = False
                    if self.res2Rect.collidepoint(event.pos):
                        self.app.res = 600
                        self.inMenu = False
                    if self.res3Rect.collidepoint(event.pos):
                        self.app.res = 1000
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
