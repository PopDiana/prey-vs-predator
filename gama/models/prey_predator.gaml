/**
* Name: Prey-Predator simulation
* Author: Modified by Diana Pop
* Origin: Gama Tutorials - Predator Prey
* Year: 2021
*/

model prey_predator

global {
	int nr_preys_init <- 200;
	int nr_predators_init <- 100;
	float prey_max_energy <- 1.0;
	float prey_max_transfert <- 0.1;
	float predator_max_food_transfert <- 0.1;
	float prey_energy_consum <- 0.05;
	float predator_max_energy <- 1.0;
	float predator_energy_transfert <- 0.5;
	float predator_energy_consum <- 0.02;
	float prey_prob_reproduce <- 0.01;
	int prey_nr_max_offsprings <- 5;
	float prey_energy_reproduce <- 0.5;
	float predator_prob_reproduce <- 0.01;
	int predator_nr_max_offsprings <- 3;
	float predator_energy_reproduce <- 0.5;
	float predator_eat_vegetation_prob <- 0.4;
	file map_init <- image_file("../includes/data/raster_map.png");
	int nr_preys -> {length(prey)};
	int nr_predators -> {length(predator)};
	bool is_batch <- false;

	init {
		create prey number: nr_preys_init;
		create predator number: nr_predators_init;
		ask vegetation_cell {
			color <- rgb (map_init at {grid_x,grid_y});
			food <- 1 - (((color as list) at 0) / 255);
			food_prod <- food / 100; 
		}
	}
	
	reflex save_result when: (nr_preys > 0) and (nr_predators > 0){
		save ("cycle: "+ cycle + "; nrPreys: " + nr_preys
			+ "; minEnergyPreys: " + (prey min_of each.energy)
			+ "; maxEnergyPreys: " + (prey max_of each.energy) 
	   		+ "; nrPredators: " + nr_predators           
	   		+ "; minEnergyPredators: " + (predator min_of each.energy)          
	   		+ "; maxEnergyPredators: " + (predator max_of each.energy)) 
	   		to: "results.txt" type: "text" rewrite: (cycle = 0) ? true : false;
	}
	
	reflex stop_simulation when: ((nr_preys = 0) or (nr_predators = 0)) and !is_batch {
		do pause;
	} 
	
}

species generic_species {
	/* instead of a fixed number; determines individual power */
	float size <- rnd(1.0, 3.0); 
	rgb color;
	/* 0 marks male, 1 marks female, only females can give birth to offspring */
	bool can_birth_offspring <- bool(rnd(0, 1)); 
	float max_energy;
	float max_transfert;
	float energy_consum;
	float prob_reproduce;
	int nr_max_offsprings;
	float energy_reproduce;
	image_file my_icon;
	vegetation_cell my_cell <- one_of(vegetation_cell);
	float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy;

	
	init {
		location <- my_cell.location;
	}

	reflex basic_move {
		my_cell <- choose_cell();
		location <- my_cell.location;
	}

	reflex eat {
		energy <- energy + energy_from_eat();		
	}

	reflex die when: energy <= 0 {
		do die;
	}

	float energy_from_eat {
		return 0.0;
	}

	vegetation_cell choose_cell {
		return nil;
	}

	aspect base {
		draw circle(size) color: color;
	}

	aspect icon {
		draw my_icon size: 2 * size;
	}

	aspect info {
		draw square(size) color: color;
		draw string(energy with_precision 2) size: 3 color: #black;
	}
	
	aspect by_sex {
		draw square(size) color: color;
		draw sex() color: #white;
	}
	
	string sex {
		if can_birth_offspring = true {
			return "F";
		} else {
			return "M";
		}
	}
}

species prey parent: generic_species {
	rgb color <- #blue;
	float max_energy <- prey_max_energy;
	float max_transfert <- prey_max_transfert;
	float energy_consum <- prey_energy_consum;
	float prob_reproduce <- prey_prob_reproduce;
	int nr_max_offsprings <- prey_nr_max_offsprings;
	float energy_reproduce <- prey_energy_reproduce;
	image_file my_icon <- image_file("../includes/data/sheep.png");

	float energy_from_eat {
		float energy_transfert <- 0.0;
		if(my_cell.food > 0) {
			energy_transfert <- min([max_transfert, my_cell.food]);
			my_cell.food <- my_cell.food - energy_transfert;
		} 			
		return energy_transfert;
	}

	vegetation_cell choose_cell {
		return (my_cell.neighbors2) with_max_of (each.food);
	}
	
	/* reproduce only when other prey near */
	reflex reproduce when: (energy >= energy_reproduce) and (flip(prob_reproduce)) 
	and (my_cell.neighbors2 first_with (!(empty(prey inside (each))))) != nil and can_birth_offspring {
		
		let other_prey_cells <- my_cell.neighbors2 first_with (!(empty(prey inside (each))));
 		list<prey> possible_partners <- prey inside other_prey_cells;
 		/* choose a male partner */
 		prey partner <- possible_partners first_with !each.can_birth_offspring; 
 		
 		if partner != nil {
			int no_offsprings <- rnd(1, nr_max_offsprings);
			create species(self) number: no_offsprings {
				my_cell <- myself.my_cell;
				location <- my_cell.location;
				/* offspring will take energy from both parents */
				energy <- myself.energy / no_offsprings + partner.energy / no_offsprings;
			}

			energy <- energy / no_offsprings;
			/* partner also loses energy */
			partner.energy <- partner.energy / no_offsprings;
		}
	}
}

species predator parent: generic_species {
	rgb color <- #red;
	float max_energy <- predator_max_energy;
	float energy_transfert <- predator_energy_transfert;
	float energy_consum <- predator_energy_consum;
	float prob_reproduce <- predator_prob_reproduce;
	int nr_max_offsprings <- predator_nr_max_offsprings;
	float max_food_transfert <- predator_max_food_transfert;
	float energy_reproduce <- predator_energy_reproduce;
	float eat_vegetation_prob <- predator_eat_vegetation_prob;
	image_file my_icon <- image_file("../includes/data/wolf.png");


	float energy_from_eat {
		list<prey> reachable_preys <- prey inside (my_cell);
		if(! empty(reachable_preys)) {
			prey chosen_prey <- shuffle(reachable_preys) first_with (each.size <= self.size);
			if chosen_prey != nil {
				let factor <- chosen_prey.size;
				ask chosen_prey {
					do die;
				}
				/* gain more energy with bigger prey */	
				if energy + energy_transfert * factor > max_energy {
					return max_energy - energy;
				} else {
					return energy + energy_transfert;
				}		
			}		
			return 0.0;
		} else { 
			/* predator will eat grass in desperate times, 
			 * only with a decreased probability to stomach it
			 */
			if flip(eat_vegetation_prob) {
				
				float food_energy_transfert <- 0.0;
				
				if my_cell.food > 0 {
					food_energy_transfert <- min([max_food_transfert, my_cell.food]);
					my_cell.food <- my_cell.food - food_energy_transfert;
				} 	
						
				return food_energy_transfert;	
			}	
		}

		return 0.0;
	}
	
	
	/* reproduce only when other predator near*/
	reflex reproduce when: (energy >= energy_reproduce) and (flip(prob_reproduce)) and 
 		(my_cell.neighbors2 first_with (!(empty(predator inside (each))))) != nil and can_birth_offspring {
 			
 		let other_predator_cells <- my_cell.neighbors2 first_with (!(empty(predator inside (each))));
 		list<predator> possible_partners <- predator inside other_predator_cells;
 		predator partner <- possible_partners first_with !each.can_birth_offspring; /* choose a male partner */
 		
 		if partner != nil {
			int no_offsprings <- rnd(1, nr_max_offsprings);
			create species(self) number: no_offsprings {
				my_cell <- myself.my_cell;
				location <- my_cell.location;
				/* offspring will take energy from both parents */
				energy <- myself.energy / no_offsprings + partner.energy / no_offsprings;
			}
			energy <- energy / no_offsprings;
			/* partner also loses energy */
			partner.energy <- partner.energy / no_offsprings; 
		}
	}

	vegetation_cell choose_cell {
		vegetation_cell my_cell_tmp <- shuffle(my_cell.neighbors2) first_with (!(empty(prey inside (each))));
		if my_cell_tmp != nil {
			return my_cell_tmp;
		} else {
			return one_of(my_cell.neighbors2);
		}
	}
}

grid vegetation_cell width: 50 height: 50 neighbors: 4 {
	float max_food <- 1.0;
	float food_prod <- rnd(0.01);
	float food <- rnd(1.0) max: max_food update: food + food_prod;
	rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
	list<vegetation_cell> neighbors2 <- (self neighbors_at 2);
}

experiment prey_predator type: gui {
	parameter "Initial number of preys: " var: nr_preys_init min: 0 max: 1000 category: "Prey";
	parameter "Prey max energy: " var: prey_max_energy category: "Prey";
	parameter "Prey max transfert: " var: prey_max_transfert category: "Prey";
	parameter "Prey energy consumption: " var: prey_energy_consum category: "Prey";
	parameter "Initial number of predators: " var: nr_predators_init min: 0 max: 200 category: "Predator";
	parameter "Predator max energy: " var: predator_max_energy category: "Predator";
	parameter "Predator energy transfert: " var: predator_energy_transfert category: "Predator";
	parameter "Predator energy consumption: " var: predator_energy_consum category: "Predator";
	parameter 'Prey probability reproduce: ' var: prey_prob_reproduce category: 'Prey';
	parameter 'Prey no. max offsprings: ' var: prey_nr_max_offsprings category: 'Prey';
	parameter 'Prey energy reproduce: ' var: prey_energy_reproduce category: 'Prey';
	parameter 'Predator probability reproduce: ' var: predator_prob_reproduce category: 'Predator';
	parameter 'Predator no. max offsprings: ' var: predator_nr_max_offsprings category: 'Predator';
	parameter 'Predator energy reproduce: ' var: predator_energy_reproduce category: 'Predator';
	parameter 'Predator probability to eat vegetation: ' var: predator_eat_vegetation_prob category: 'Predator';

	output {
		display main_display {
			grid vegetation_cell lines: #black;
			species prey aspect: icon;
			species predator aspect: icon;
		}

		display info_display {
			grid vegetation_cell lines: #black;
			species prey aspect: info;
			species predator aspect: info;
		}
			
		display display_by_sex {
			grid vegetation_cell lines: #black;
			species prey aspect: by_sex;
			species predator aspect: by_sex;
		}

		display Population_information refresh: every(5#cycles) {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "number_of_prey" value: nr_preys color: #blue;
				data "number_of_predator" value: nr_predators color: #red;
			}
			
			chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
				data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue;
				data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue;
				data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue;
				data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue;
			}
			chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
				data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red;
				data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red;
				data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red;
				data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red;
			}
		}

		monitor "Number of preys" value: nr_preys;
		monitor "Number of predators" value: nr_predators;
		monitor "Number of female preys" value: prey count (each.can_birth_offspring = true);
		monitor "Number of male preys" value: prey count (each.can_birth_offspring = false);
		monitor "Number of female predators" value: predator count (each.can_birth_offspring = true);
		monitor "Number of male predators" value: predator count (each.can_birth_offspring = false);
	}
}

experiment optimization type: batch repeat: 2 keep_seed: true until: ( time > 200 ) {
	parameter "Prey max transfert:" var: prey_max_transfert min: 0.05 max: 0.5 step: 0.05;
	parameter "Prey energy reproduce:" var: prey_energy_reproduce min: 0.05 max: 0.75 step: 0.05;
	parameter "Predator energy transfert:" var: predator_energy_transfert min: 0.1 max: 1.0 step: 0.1;
	parameter "Predator energy reproduce:" var: predator_energy_reproduce min: 0.1 max: 1.0 step: 0.1;
	parameter "Batch mode:" var: is_batch <- true;
	
	method tabu maximize: nr_preys + nr_predators iter_max: 10 tabu_list_size: 3;
	
	reflex save_results_explo {
		ask simulations {
			save [int(self),prey_max_transfert,prey_energy_reproduce,
				predator_energy_transfert,predator_energy_reproduce,self.nr_predators,self.nr_preys] 
		   		to: "results.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}		
	}
}
