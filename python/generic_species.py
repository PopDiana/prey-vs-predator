from graphics import *
import random


class GenericSpecies(object):

    def __init__(self, world):
        self.world = world
        self.is_alive = True
        self.vx = 4
        self.vy = 4
        self.x = random.uniform(0, self.world.simulation_win.getWidth())
        self.y = random.uniform(0, self.world.simulation_win.getHeight())
        self.size = random.randint(6, 10)
        self.can_birth_offspring = bool(random.randint(0, 1))
        self.world.add_species(self)
        self.set_appearance()

    def set_appearance(self):
        self.appearance = Circle(Point(self.x, self.y), self.size)
        if self.world.display:
            self.appearance.draw(self.world.win)

    def eat(self):
        pass

    def reproduce(self):
        pass

    def die(self):
        if self.world.display:
            self.appearance.undraw()
        self.is_alive = False

    def move(self):
        dx = random.uniform(-self.vx, self.vx)
        dy = random.uniform(-self.vy, self.vy)
        if self.is_inside_window(dx, dy):
            self.x = self.x + dx
            self.y = self.y + dy
            self.appearance.move(dx, dy)

    def distance(self, other):
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

    def is_inside_window(self, dx, dy):
        tx = self.x + dx
        ty = self.y + dy
        if self.size / 2 < tx < self.world.simulation_win.getWidth() - self.size / 2 and \
                self.size / 2 < ty < self.world.simulation_win.getHeight() - self.size / 2:
            return True
        else:
            return False
