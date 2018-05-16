/**
 *  routecirculation - model 2
 *  Author: david
 *  Description: 
 */
model routecirculationmodel2gaml

/* Insert your model definition here */
global
{
// Importation des fichiers
	file forme_route <- file('../includes/docs/ligne.shp');
	file forme_batiment <- file('../includes/docs/terrain.shp');
	file forme_depart <- file('../includes/docs/depart.shp');
	file forme_arrivee <- file('../includes/docs/arrivee.shp');
	file forme_attente <- file('../includes/docs/zone_attente.shp');
	file forme_feux <- file('../includes/docs/feux.shp');
	graph graph_voie_pub;
	const temps_standard type: int <- 180;
	int temps_dem_1 <- 0;
	int temps_dem_2 <- temps_standard;
	int temps_dem_3 <- 0;
	int temps_dem_4 <- temps_standard;
	int temps_vert_1 <- int(temps_standard * 24 / 25);
	int temps_vert_2 <- int(temps_standard * 24 / 25);
	int temps_vert_3 <- int(temps_standard * 24 / 25);
	int temps_vert_4 <- int(temps_standard * 24 / 25);
	int temps_orange_standard <- int(temps_standard / 25);
	int temps_rouge_2 <- temps_standard;
	int temps_rouge_3 <- temps_standard;
	int temps_rouge_4 <- temps_standard;
	int temps_rouge_1 <- temps_standard;
	list liste_temps_dem <- [temps_dem_1, temps_dem_2, temps_dem_3, temps_dem_4];
	list liste_temps_vert <- [temps_vert_1, temps_vert_2, temps_vert_3, temps_vert_4];
	list liste_temps_orange <- [temps_orange_standard, temps_orange_standard, temps_orange_standard, temps_orange_standard];
	list liste_temps_rouge <- [temps_rouge_1, temps_rouge_2, temps_rouge_3, temps_rouge_4];
	//int repulsion_strength min: 1;
	int nombre_vehicule <- 20 parameter: 'nombre de vehicule' category: 'vehicules' min: 10 max: 40;
	float min_speed <- 2.0;
	float max_speed <- 5.0;
	//list list_wa <- zone_attente as list;
	geometry shape <- envelope(forme_route);
	init
	{
		create arrivee from: forme_arrivee;
		create depart from: forme_depart;
		create route from: forme_route;
		create batiment from: forme_batiment;
		create zone_attente from: forme_attente;
		create feux from: forme_feux with: [id_feu::read('id')]
		{
			set temps_dem <- liste_temps_dem at id_feu;
			set temps_vert <- liste_temps_vert at id_feu;
			set temps_rouge <- liste_temps_rouge at id_feu;
			set temps_orange <- liste_temps_orange at id_feu;
			set temps_total <- temps_rouge + temps_vert + temps_orange;
		}

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

	// Espece zone_attente
	species zone_attente
	{
		geometry style_za <- shape;
		float taille_zone_attente <- 5.0;
		rgb couleur_za <- rgb('gray');
		aspect basic
		{
			draw circle(taille_zone_attente) color: couleur_za;
		}

	}

	//Espece moto
	species moto skills: [moving]
	{
		bool is_polite <- false;
		float vitesse_actuelle <- speed;
		rgb color <- rgb('green');
		rgb couleur_av_lumiere <- color;
		rgb couleur_pendant_lumiere <- rgb('red');
		rgb couleur_arr_lumiere <- rgb('orange');
		depart point_dep <- nil;
		arrivee terminal_arr <- nil;
		point la_destination <- nil;
		point la_direction <- nil;
		int taille_moto <- 7;
		aspect basic
		{
			draw circle(taille_moto) color: color depth: 1;
		}

		reflex deplacement when: la_destination != nil
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

		reflex circulation_feux_rouge_et_feux_vert
		{
			ask feux
			{
				float distance <- myself distance_to self;
				if ((self.color = # orange) and (distance <= 27.0))
				{
					myself.speed <- myself.vitesse_actuelle / 12;
					set myself.color <- myself.couleur_arr_lumiere;
				}

				if ((self.color = # red) and (distance <= 27.0))
				{
					set myself.speed <- 0.0;
					set myself.color <- myself.couleur_pendant_lumiere;
				}

				if ((self.color = # green) and (distance <= 27.0))
				{
					myself.speed <- myself.vitesse_actuelle;
					set myself.color <- myself.couleur_av_lumiere;
				}

				if ((self.color = # green) and (distance <= 27.0) and (self.periode_temps < 165))
				{
					myself.speed <- myself.vitesse_actuelle * 4;
					set myself.color <- myself.couleur_av_lumiere;
				}

				if ((self.color = # green) and (distance <= 27.0) and ((self.periode_temps > 170) and (self.periode_temps < 175)))
				{
					myself.speed <- 0.0;
					set myself.color <- myself.couleur_av_lumiere;
				}

			}

		}

		reflex eviter_collision
		{
			ask moto
			{
				float distance <- self distance_to myself;
				if ((distance <= 75 # cm) and (myself.color = # green))
				{
					self.speed <- speed;
					myself.speed <- myself.speed + 0.5;
				}

				if ((distance <= 75 # cm) and (myself.color = # red))
				{
					self.speed <- 0.0;
					//myself.speed <- myself.speed;

				}

				if ((distance <= 75 # cm) and (myself.color = # orange))
				{
					self.speed <- 0.0;
					//myself.speed <- myself.speed;

				}

			}

		}

	}

	species feux control: fsm
	{
		int id_feu <- 0;
		int temps_dem <- liste_temps_dem at id_feu;
		int temps_rouge <- liste_temps_rouge at id_feu;
		int temps_vert <- liste_temps_vert at id_feu;
		int temps_orange <- liste_temps_orange at id_feu;
		int temps_total <- temps_rouge + temps_vert + temps_orange;
		int periode_temps update: int((time - temps_dem >= 0) ? (time - temps_dem) mod (temps_total) : (temps_total - (temps_dem - time)));
		float taille_feux <- 10.0;
		moto speed_actual <- nil;
		rgb color <- rgb('red');
		state startup initial: true
		{
			transition to: en_rouge when: periode_temps >= temps_vert + temps_orange and periode_temps < temps_total;
			transition to: en_vert when: periode_temps >= 0 and periode_temps < temps_vert;
			transition to: en_orange when: periode_temps >= temps_vert and periode_temps < temps_vert + temps_orange;
		}

		state en_vert
		{
			set color <- rgb('green');
			transition to: en_orange when: periode_temps = temps_vert;
		}

		state en_orange
		{
			set color <- rgb('orange');
			transition to: en_rouge when: periode_temps = temps_vert + temps_orange;
		}

		state en_rouge
		{
			set color <- rgb('red');
			transition to: en_vert when: periode_temps = 0;
		}

		aspect baisc
		{
			draw shape + circle(taille_feux) color: color;
			draw text: string(periode_temps) at: location + { -7, 5.0 } color: rgb('blue') size: 2.5;
		}

	}

}

experiment routecirculation type: gui
{
	parameter "fichier route" var: forme_route category: 'GIS';
	parameter "fichier batiment" var: forme_batiment category: 'GIS';
	parameter "fichier point depart" var: forme_depart category: 'GIS';
	parameter "fichier point arrive" var: forme_arrivee category: 'GIS';
	parameter "fichier zone d'attente" var: forme_attente category: 'GIS';
	parameter "fichier feux" var: forme_feux category: 'GIS';
	output
	{
		display circulation_routiere_hanoi type: opengl
		{
			species route aspect: basic;
			species batiment aspect: basic;
			species moto aspect: basic;
			species depart aspect: basic;
			species arrivee aspect: basic;
			species zone_attente aspect: basic;
			species feux aspect: baisc;
		}

	}

}