from generic_species import *

out = open("results.txt", "w")


class Predator(GenericSpecies):
    energy = 15
    sensing_range = 30
    reproduction_prob = 0.05
    eat_vegetation_prob = 0.4

    def __init__(self, world):
        GenericSpecies.__init__(self, world)

    def reproduce(self):
        rand = random.uniform(0, 1)
        partner = self.world.closest_neighbor(self, Predator)
        if partner is not None:
            if rand <= self.reproduction_prob and \
                    self.energy > 1.5 and \
                    self.distance(partner) <= self.sensing_range and \
                    self.can_birth_offspring is True and partner.can_birth_offspring is False:
                Predator(self.world)
                out.write(str(self) + " has mated with " + str(partner) + "\n")

    def eat(self, factor):
        if self.energy + factor > 15:
            self.energy = 15
        else:
            self.energy = self.energy + factor

    def set_appearance(self):
        self.appearance = Circle(Point(self.x, self.y), self.size)
        self.appearance.setFill("red")
        if self.world.display:
            self.appearance.draw(self.world.simulation_win)

    def move(self):
        GenericSpecies.move(self)
        self.reproduce()
        self.energy = self.energy - 1
        prey = self.world.closest_neighbor(self, Prey)
        grass = self.world.closest_neighbor(self, Vegetation)
        if prey is not None:
            if self.distance(prey) <= self.sensing_range and self.size >= prey.size:
                self.eat(prey.size)
                out.write(str(self) + " has eaten " + str(prey) + "\n")
                World.closest_neighbor(self.world, self, Prey).die()
        else:
            if grass is not None:
                rand = random.uniform(0, 1)
                if self.distance(grass) <= self.sensing_range and rand <= self.eat_vegetation_prob:
                    self.eat(5)
                    out.write(str(self) + " has eaten some grass\n")
                    World.closest_neighbor(self.world, self, Vegetation).die()
        if self.energy <= 0:
            self.die()

    def __str__(self):
        return "Predator at (%d, %d)" % (self.x, self.y)


class Prey(GenericSpecies):
    energy = 5
    sensing_range = 20
    reproduction_prob = 0.06

    def __init__(self, world):
        GenericSpecies.__init__(self, world)

    def reproduce(self):
        rand = random.uniform(0, 1)
        partner = self.world.closest_neighbor(self, Prey)
        if partner is not None:
            if rand <= self.reproduction_prob and self.energy > 1.5 and self.distance(partner) <= self.sensing_range and \
                    self.can_birth_offspring is True and partner.can_birth_offspring is False:
                Prey(self.world)
                out.write(str(self) + " has mated with " + str(partner) + "\n")

    def eat(self):
        if self.energy + 5 > 15:
            self.energy = 15
        else:
            self.energy = self.energy + 5

    def move(self):
        GenericSpecies.move(self)
        self.reproduce()
        grass = self.world.closest_neighbor(self, Vegetation)
        if grass is not None:
            if self.distance(grass) <= self.sensing_range:
                self.eat()
                out.write(str(self) + " has eaten some grass\n")
                World.closest_neighbor(self.world, self, Vegetation).die()
        if self.energy <= 0:
            self.die()

    def set_appearance(self):
        self.appearance = Circle(Point(self.x, self.y), self.size)
        self.appearance.setFill("blue")
        if self.world.display:
            self.appearance.draw(self.world.simulation_win)

    def __str__(self):
        return "Prey at (%d, %d)" % (self.x, self.y)


class Vegetation(GenericSpecies):
    reproduction_prob = 0.07

    def __init__(self, world):
        GenericSpecies.__init__(self, world)

    def reproduce(self):
        rand = random.uniform(0, 1)
        if rand <= self.reproduction_prob and self.world.nr_vegetation <= self.world.nr_prey + self.world.nr_predators:
            Vegetation(self.world)
            Vegetation(self.world)
            self.world.nr_vegetation = self.world.nr_vegetation + 2

    def die(self):
        self.world.nr_vegetation = self.world.nr_vegetation - 1
        GenericSpecies.die(self)

    def move(self):
        self.reproduce()

    def set_appearance(self):
        self.appearance = Rectangle(Point(self.x, self.y), Point(self.x + 2 * self.size, self.y + 2 * self.size))
        self.appearance.setFill("green")
        if self.world.display:
            self.appearance.draw(self.world.simulation_win)


class World(object):

    def __init__(self, nr_prey, nr_predators, nr_vegetation):
        self.display = True
        self.nr_prey = nr_prey
        self.nr_predators = nr_predators
        self.nr_vegetation = nr_vegetation
        self.species = []

        # size of the map
        self.simulation_win = GraphWin("Prey vs. Predator Simulation", 500, 500)
        self.simulation_win.setBackground("white")

        self.population_win = GraphWin("Population size in time", 750, 250)

        for iterator in range(nr_prey):
            Prey(self)

        for iterator in range(nr_predators):
            Predator(self)

        for iterator in range(nr_vegetation):
            Vegetation(self)

    def add_species(self, x):
        self.species.append(x)

    def nearby_species(self, x):
        nearby = []
        for species_iterator in self.species:
            if species_iterator.is_alive and x.distance(species_iterator) < x.sensing_range and species_iterator != x:
                nearby.append(species_iterator)
        return nearby

    def closest_neighbor(self, x, t):
        closest_distance = 999999
        neighbor = None
        for species_iterator in self.nearby_species(x):
            if isinstance(species_iterator, t) and x.distance(species_iterator) < closest_distance:
                neighbor = species_iterator
                closest_distance = x.distance(species_iterator)
        return neighbor

    def run(self):

        step = 0

        while step < self.population_win.getWidth() and self.nr_prey > 0 and self.nr_predators > 0:
            self.nr_prey = 0
            self.nr_predators = 0
            for species_iterator in self.species:
                if species_iterator.is_alive:
                    species_iterator.move()
                    if isinstance(species_iterator, Prey):
                        self.nr_prey = self.nr_prey + 1
                    elif isinstance(species_iterator, Predator):
                        self.nr_predators = self.nr_predators + 1
                else:
                    self.species.remove(species_iterator)

            prey_population = Circle(Point(step * 10, self.population_win.getHeight() - self.nr_prey), 5)
            prey_population.setFill("blue")
            prey_population.draw(self.population_win)

            predator_population = Circle(Point(step * 10, self.population_win.getHeight() - self.nr_predators), 5)
            predator_population.setFill("red")
            predator_population.draw(self.population_win)

            out.write("\n\nPredators remaining: " + str(self.nr_predators) +
                      " Prey remaining: " + str(self.nr_prey) + "\n\n")
            step = step + 1

        out.write("\n\nSimulation Done")
        out.close()


random.seed(10)
# number of prey, predators and vegetation
env = World(150, 200, 200)
env.run()
