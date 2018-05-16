/**
 *  routecirculation - model 1
 *  Author: david
 *  Description: 
 */
model routecirculationmodel1gaml

/* Insert your model definition here */
global
{
// Importation des fichiers
	file forme_route <- file('../includes/docs/ligne.shp');
	file forme_batiment <- file('../includes/docs/terrain.shp');
	file forme_depart <- file('../includes/docs/depart.shp');
	file forme_arrivee <- file('../includes/docs/arrivee.shp');
	int nombre_vehicule <- 20 parameter: 'nombre de vehicule' category: 'vehicules' min: 10 max: 40;
	float min_speed <- 2.0;
	float max_speed <- 5.0;
	graph graph_voie_pub;
	geometry shape <- envelope(forme_route);
	init
	{
		create arrivee from: forme_arrivee;
		create depart from: forme_depart;
		create route from: forme_route;
		create batiment from: forme_batiment;
		set graph_voie_pub <- as_edge_graph(route);
		create moto number: nombre_vehicule
		{
			set location <- any_location_in(one_of(depart));
			set speed <- (rnd(max_speed - min_speed) / 2) + min_speed;
			set point_dep <- one_of(depart);
			set terminal_arr <- one_of(arrivee);
			set la_destination <- any_location_in(terminal_arr);
		}

	}

	reflex create_motos when: flip(0.7)
	{
		create moto number: 1
		{
			set location <- any_location_in(one_of(depart));
			set speed <- (rnd(max_speed - min_speed) / 4) + min_speed;
			set point_dep <- one_of(depart);
			set terminal_arr <- one_of(arrivee);
			set la_destination <- any_location_in(terminal_arr);
		}

	}

}

entities
{
//Espece route
	species route
	{
		geometry style_route <- shape + 15.0;
		rgb couleur_route <- rgb('gray');
		aspect basic
		{
			draw style_route color: couleur_route;
		}

	}

	//Espece batiment
	species batiment
	{
		geometry style_batiment <- shape + 3.0;
		rgb couleur_batiment <- rgb('brown');
		float hauteur_batiment <- 100 # m;
		aspect basic
		{
			draw style_batiment color: couleur_batiment depth: hauteur_batiment;
		}

	}

	//Espece arrivee
	species arrivee
	{
		float taille_pt_arrive <- 10.0;
		rgb couleur_pt_arrive <- rgb('red');
		float epaisseur_pt_arrive <- 5 # m;
		aspect basic
		{
			draw circle(taille_pt_arrive) color: couleur_pt_arrive depth: epaisseur_pt_arrive;
		}

	}

	//Espece depart
	species depart
	{
		float taille_pt_depart <- 5.0;
		float epaisseur_pt_depart <- rnd(5) # m;
		rgb couleur_pt_depart <- rgb('lightblue');
		aspect basic
		{
			draw circle(taille_pt_depart) color: couleur_pt_depart depth: epaisseur_pt_depart;
		}

	}

	//Espece moto
	species moto skills: [moving]
	{
		rgb color <- rgb('green');
		depart point_dep <- nil;
		arrivee terminal_arr <- nil;
		point la_destination <- nil;
		float taille_moto <- 7.0;
		aspect basic
		{
			draw circle(taille_moto) color: color depth: 1;
		}

		reflex deplacement
		{
			do action: aller_vers_destination;
		}

		action aller_vers_destination
		{
			do goto target: la_destination on: graph_voie_pub;
			switch la_destination
			{
				match location
				{
					do action: die;
				}

			}

		}

		reflex eviter_collision
		{
			ask moto
			{
				float distance <- self distance_to myself;
				if (distance <= 70 # cm)
				{
				//write ('Ta distance par rapport a moi' +distance);
					//self.speed <- speed / 0.05;
					myself.speed <- myself.speed;
				}

			}

		}

	}

}

experiment routecirculation type: gui
{
	parameter "fichier route" var: forme_route category: 'GIS';
	parameter "fichier batiment" var: forme_batiment category: 'GIS';
	parameter "fichier point depart" var: forme_depart category: 'GIS';
	parameter "fichier point arrive" var: forme_arrivee category: 'GIS';
	output
	{
		display circulation_routiere_hanoi type: opengl
		{
			species route aspect: basic;
			species batiment aspect: basic;
			species moto aspect: basic;
			species depart aspect: basic;
			species arrivee aspect: basic;
		}

	}

}