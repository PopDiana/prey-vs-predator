
## Prey vs. Predator

Three types of entities are considered in this model: prey, predators and vegetation cells. Preys eat grass on the vegetation cells and predators eat prey. At each simulation step, grass grows on the vegetation cells. Concerning the predators and prey, at each simulation step, they move (to a neighboring cell), eat, die if they do not have enough energy, and eventually reproduce.

For the project in the **gama** folder, GAMA 1.8.1 (with JDK) needs to be installed.

For the project in the **python** folder, *prey_predator.py* needs to be run (python v.3.7). Data will
be logged in the *results.txt* file, to change the file simply modify the line:

```out = open("results.txt", "w")```
