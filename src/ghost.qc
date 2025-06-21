.float ghost_state;
.float ghost_gridsize;
.float ghost_frame;
.float ghost_anim;
.float ghost_chasing;
.float ghost_starttime;
.float update_nextpos;

.vector ghost_last_pos;
.vector ghost_spawn;
.vector ghost_grid_offset;
.vector ghost_last_confirmed;
.entity scatterpoint;

.string ghost;

.entity sprite;
.entity bbox;
.entity trigger;
.entity voice;
//.entity back;

.vector nextpos;

void(entity sprite_ent, entity parent_ent) ai_get_sprite =
{
	string spritepath;

	if (parent_ent.ghost == "blinky")
		spritepath = "sprites/ghosts/blinky.spr";
	else if (parent_ent.ghost == "inky")
		spritepath = "sprites/ghosts/inky.spr";
	else if (parent_ent.ghost == "pinky")
		spritepath = "sprites/ghosts/pinky.spr";
	else if (parent_ent.ghost == "clyde")
		spritepath = "sprites/ghosts/clyde.spr";
	else
		spritepath = "sprites/ghosts/blinky.spr";

	setmodel(sprite_ent,spritepath);
};

void() ResetGhosts =
{
	entity e;
	e = find(world,classname,"monster_ghost");

	while(e)
	{
		e.update_nextpos = 0;
		e.ghost_chasing = 0;
		e.nextpos = e.ghost_spawn;

		setorigin(e, e.ghost_spawn);
		setorigin(e.bbox, e.ghost_spawn);
		setorigin(e.trigger, e.ghost_spawn);
		setorigin(e.sprite, e.ghost_spawn + '0 0 64');

		e.ghost_state = 0;
		ai_get_sprite(e.sprite, e);
		e.sprite.ghost_frame = 0;
		e.sprite.ghost_anim = 2;
		e.bbox.solid = SOLID_SLIDEBOX;
		e.trigger.solid = SOLID_TRIGGER;

		e.nextthink = time + e.ghost_starttime - (level * 0.5);

		e.velocity = '0 0 0';
		e.bbox.velocity = '0 0 0';

		scattermode = 1;
		scattertime = time + 7-(get_panic_speed()*0.5);

		e = find(e, classname, "monster_ghost");
	}
}

void() ai_ghost_animation_manager =
{
    self.frame += 1;
    if (self.frame >= self.ghost_frame + self.ghost_anim)
        self.frame = self.ghost_frame;

    self.nextthink = time + self.owner.speed * 0.05;
};

void() ai_ghost_state_manager =
{
	if (self.ghost_state == 3)
	{
		self.sprite.ghost_frame = 4;
		self.sprite.ghost_anim = 4;
		if ((floor(self.origin_x/self.ghost_gridsize) == floor(self.ghost_spawn_x/self.ghost_gridsize)) && (floor(self.origin_y/self.ghost_gridsize) == floor(self.ghost_spawn_y/self.ghost_gridsize)))
		{
			ai_get_sprite(self.sprite,self);
			self.ghost_state = 0;
		}
	}

	if (self.ghost_state == 2)
	{
		setmodel(self.sprite,"sprites/ghosts/frightened.spr");

		self.sprite.ghost_frame = 0;
		self.bbox.solid = SOLID_SLIDEBOX;
		self.trigger.solid = SOLID_TRIGGER;

		//setmodel(self.back,string_null);

		/*dprint("Ghost animation time : ");
		dprint(ftos(time));
		dprint(", ");
		dprint(ftos(self.frightened_counter));
		dprint("\n");*/
		
		setsize(self.trigger, '-64 -64 0', '64 64 128');

		if (time > self.frightened_counter - 3)
		{
			self.sprite.ghost_anim = 4;
		}
		else
		{
			self.sprite.ghost_anim = 2;
		}

		if (self.frightened_counter <= time)
		{
			ai_get_sprite(self.sprite,self);
			self.ghost_state = 0;

			self.sprite.ghost_frame = 0;
			self.sprite.ghost_anim = 2;

			//self.back.ghost_frame = 6;
			//self.back.ghost_anim = 2;
		}
	}

	if (self.ghost_state == 0)
	{
		ai_get_sprite(self.sprite,self);
		//setmodel(self.back,"sprites/ghosts/blinky.spr");

		self.sprite.ghost_frame = 0;
		self.sprite.ghost_anim = 2;

		setsize(self.trigger, '-48 -48 0', '48 48 128');

		//self.back.ghost_frame = 6;
		//self.back.ghost_anim = 2;
		self.bbox.solid = SOLID_SLIDEBOX;
		self.trigger.solid = SOLID_TRIGGER;
	}
};

entity() ai_ghost_getplayer =
{
	entity e;
	entity return_player;
	float best_dist;
	float dist;

	best_dist = -1;

	e = find(world, classname, "player");
	while (e)
	{
		dist = vlen(self.origin - e.origin);

		if (best_dist < 0 || dist < best_dist)
		{
			best_dist = dist;
			return_player = e;
		}

		e = find(e, classname, "player");
	}
	return return_player;
};

vector(entity target) ai_ghost_gettarget =
{
	vector returnme;

	if (self.ghost_state == 3)
		return self.ghost_spawn;
	else
	{
		if (self.ghost_chasing == 1)
		{
			returnme = target.origin;
			if (self.ghost == "pinky")
			{
				if (target.velocity != '0 0 0')
					returnme = target.origin + normalize(target.velocity) * 512;
				else
				{
					makevectors(target.angles);
					returnme = target.origin + v_forward * 512;
				}
				returnme_z = target.origin_z;
			}
			else if (self.ghost == "inky")
			{
				entity inkysblinky;
				returnme = target.origin;
				inkysblinky = find(world, classname, "monster_ghost");
				while(inkysblinky)
				{
					returnme = mirror_across(inkysblinky.origin,target.origin);
					returnme_z = target.origin_z;
					if (inkysblinky.ghost == "blinky") break;
					inkysblinky = find(inkysblinky, classname, "monster_ghost");
				}
			}
			else if (self.ghost == "clyde")
			{
				returnme = target.origin;
				if (vlen(self.origin - target.origin) < 256)
				{
					returnme = self.scatterpoint.origin;
				}
			}
		}
		else
		{
			returnme = self.scatterpoint.origin;
		}
		return returnme;
	}
};

vector() ai_ghost_getdir =
{
	vector to_player;
	float best_dir = 0;
	float angle_to_player, angle_facing, angle_diff, saved_yangles;

	// Get direction to player
	vector target;
	entity player_ent;
	player_ent = ai_ghost_getplayer();
	target = ai_ghost_gettarget(player_ent);

	to_player = normalize(target - self.origin);
	saved_yangles = self.angles_y;

	/*if (self.ghost_state == 0)
	{
		if (vlen(player_ent.origin - target) > vlen(player_ent.origin - self.origin))
		{
			to_player = normalize(target - self.origin);
			dprint(self.ghost);
			to_player = normalize(player_ent.origin - self.origin);
			dprint("Player targeted.");
		}
	}
	dprint("\n");*/

	// Convert to yaw
	angle_to_player = vectoyaw(to_player);
	angle_facing = self.angles_y;

	if (self.ghost_state == 2) 
	{
		angle_to_player += 180;
	}

	// Normalize angles to 0–360
	while (angle_to_player < 0) angle_to_player += 360;
	while (angle_facing < 0) angle_facing += 360;
	while (angle_to_player > 360) angle_to_player -= 360;
	while (angle_facing > 360) angle_facing -= 360;

	// Find the difference
	angle_diff = angle_to_player - angle_facing;
	if (angle_diff > 180) angle_diff -= 360;
	if (angle_diff < -180) angle_diff += 360;
	
	// Decide which way to turn
	if (angle_diff > 45)
	{
		// Turn right
		best_dir += 90;
	}
	else if (angle_diff < -45)
	{
		// Turn left
		best_dir -= 90;
	}
	// else: stay facing forward

	vector check_start,check_end,test_pos,left_pos,right_pos,best_ground_hit,offset;
	float i,check_dir,pass,half_width,best_floor_z;
	best_floor_z = self.origin_z;
	pass = 0;
	half_width = self.ghost_gridsize * 0.5 - 1;

	// Determine direction to check
	check_dir = 90;
	if (angle_diff < -45)
		check_dir = -90;
	if (angle_diff >= 45)
		check_dir = 90;

	for (i = 0; i < 1; i = i)
	{
		if (fabs(best_dir) == 90 && pass == 0)
		{
			check_dir = -check_dir;
			pass = 1;
		}

		// Setup movement direction
		vector temp_angles;
		temp_angles = self.angles;
		temp_angles_y = anglemod(self.angles_y + best_dir);
		makevectors(temp_angles); // updates v_forward, v_right, etc.

		// Position ghost one tile forward
		float move_dist;

		if (best_dir == 0) // forward
			move_dist = 8;
		else // side turn
			move_dist = half_width + 8;

		test_pos = self.origin + (v_forward * move_dist);

		// Calculate left and right offset positions
		left_pos  = test_pos - v_right * half_width;
		right_pos = test_pos + v_right * half_width;

		float w;
		float inc;
		float div;

		div = 8;
		inc = self.ghost_gridsize / (div - 1);
		//dprint("Hits :");
		for (w = 0; w < div; w = w + 1)
		{
			if (w == 0)
			{
				check_start = left_pos + '0 0 64';
				check_end = left_pos + '0 0 -64';
			}
			else if (w == div - 1)
			{
				check_start = right_pos + '0 0 64';
				check_end = right_pos + '0 0 -64';
			}
			else
			{
				float frac = w / (div - 1); // 0.0 to 1.0
				vector midpoint = left_pos + v_right * self.ghost_gridsize * frac;

				check_start = midpoint + '0 0 64';
				check_end = midpoint + '0 0 -64';
			}

			traceline(check_start, check_end, TRUE, self);
			float floor_hit = trace_fraction;
			if (trace_fraction < 1 && fabs(trace_endpos_z - self.origin_z) < 64)
			{
				best_floor_z = trace_endpos_z;
				best_ground_hit = trace_endpos;
			}

			//dprint(ftos(floor_hit));
			//dprint(", ");
			//particle(check_start, '0 0 0', 254, 200);

			if (floor_hit == 1)
				break;
		}
		//dprint("\n");

		if (best_dir == 0) // only for forward checks
		{
			vector extra1 = test_pos + v_forward * (half_width);

			check_start = extra1 + '0 0 64';
			check_end   = extra1 + '0 0 -64';
			traceline(check_start, check_end, TRUE, self);
			if (trace_fraction == 1)
				w = 0; // failed - overwrite loop success
		}

		offset = v_forward * self.ghost_gridsize * 0.0625;
		offset_z = best_floor_z - self.origin_z;

		if (fabs(offset_z) > 64)
			w = 0; // too steep - overwrite loop success

		// Only allow movement if all points hit floor
		if (w == div)
		{
			i = 1;
			break;
		}

		if (fabs(best_dir) == 270)
		{
			i = 2;
			break;
		}

		best_dir = best_dir + check_dir;
	}

	self.angles_y += best_dir;

	// Clamp angle to 0–360 (optional)
	if (self.angles_y >= 360) self.angles_y -= 360;
	if (self.angles_y < 0) self.angles_y += 360;

	// Move forward self.ghost_gridsize units in current direction
	makevectors(self.angles); // sets v_forward

	if (i != 2)
	{
		return self.origin + offset;
	}
	else
		return self.origin;

};

void() restore_player_velocity =
{
    self.owner.velocity_x = self.velocity_x;
	self.owner.velocity_y = self.velocity_y;
    remove(self);
};

void(entity player, vector saved_vel) spawn_velocity_restore =
{
    local entity v_restore;
    v_restore = spawn();
    v_restore.owner = player;
    v_restore.velocity = saved_vel;
    v_restore.nextthink = time + 0.01;
    v_restore.think = restore_player_velocity;
};

void(entity attacker,entity inflictor,float rkills) ai_damaged =
{
    entity ghost_bbox = self.owner;
	entity ghost = self;
    entity scorer = world;

	float c;

    // Prefer attacker if it's a player
    if (attacker && attacker.classname == "player")
        scorer = attacker;
    else if (inflictor && inflictor.owner && inflictor.owner.classname == "player")
        scorer = inflictor.owner;

    // Ghost death logic
    ghost_bbox.origin = ghost.ghost_last_pos;
    ghost_bbox.ghost_state = 3;
    ghost_bbox.sprite.frame = 5;
    ghost_bbox.sprite.ghost_frame = 5;
    ghost_bbox.sprite.ghost_anim = 4;
    ghost_bbox.frightened_counter = 0;
	ghost_bbox.bbox.solid = SOLID_NOT;
	ghost_bbox.trigger.solid = SOLID_NOT;

	sound(attacker,CHAN_VOICE,"ghosts/eat_ghost.wav",1,ATTN_NONE);
	
	/*dprint("Attacker : ");
	dprint(attacker.classname);
	dprint("\n");*/

    // Scoring
    if (scorer != world)
    {
        float score = 200;
		float i;
		c = 1;
		for (i = 1;i < scorer.ghost_combo;i = i + 1)
		{
			c = c * 2;
		}
        if (inflictor && (inflictor.classname == "missile"))
		{
			score += 10; //round(vlen(scorer.origin - ghost.origin)/25); // splash bonus
			inflictor.rocket_kills += 1;
			if (scorer.rj_active == 0)
				addscore(scorer, score, c, 1, "Ghost Rocket x",ftos(scorer.ghost_combo),string_null,string_null,string_null);
			else
				addscore(scorer, score+100, c, 1, "AIR STRIKE! x",ftos(scorer.ghost_combo),string_null,string_null,string_null);
			if (inflictor.rocket_kills == 2)
				addscore(scorer, 500, 1, 1, "Double Ghost Rocket",string_null,string_null,string_null,string_null);
			else if (inflictor.rocket_kills == 3)
				addscore(scorer, 1000, 1, 1,"Triple Ghost Rocket!",string_null,string_null,string_null,string_null);
			else if (inflictor.rocket_kills == 4)
				addscore(scorer, 1500, 1, 1, "QUAD GHOST ROCKET!",string_null,string_null,string_null,string_null);
			else if (inflictor.rocket_kills >= 5)
				addscore(scorer, 500*(inflictor.rocket_kills-1), 1, 1, "OVERKILL! ",ftos(inflictor.rocket_kills)," IN ONE!",string_null,string_null);
		}
		else
		{
			if (scorer.rj_active == FALSE)
				addscore(scorer, score, c, 1, "Chomped Ghost x",ftos(scorer.ghost_combo),string_null,string_null,string_null);
			else
				addscore(scorer, score+200, c, 1, "DEATH FROM ABOVE!",string_null,string_null,string_null,string_null);
		}

		scorer.ghost_combo += 1;
    }
}

void() ai_ghost_stun =
{
	entity parent_ent;
	parent_ent = self.owner;

	parent_ent.origin = parent_ent.ghost_last_pos;
	parent_ent.velocity = '0 0 0';
	self.velocity = '0 0 0';
	if (parent_ent.ghost_state == 2)
	{
		ai_damaged(self.last_attacker,self.last_inflictor,self.rocket_kills);
		//setmodel(parent_ent.back,string_null);
	}
	else
	{
		parent_ent.nextthink = time + 2.5;
		parent_ent.bbox.solid = SOLID_NOT;
		parent_ent.trigger.solid = SOLID_NOT;
		parent_ent.sprite.frame = 2;
		parent_ent.sprite.ghost_frame = 2;
		parent_ent.sprite.ghost_anim = 4;

		//setmodel(parent_ent.back,string_null);
	}
};

void() ai_damage_player =
{
    entity parent_ent = self.owner;
	if (other.classname == "player")
	{
		if (parent_ent.ghost_state == 0)
		{
			T_Damage(other, parent_ent, parent_ent, 999);
		}
		else
		{
			vector original_velocity = other.velocity;
			ai_damaged(other,other,0);
			spawn_velocity_restore(other, original_velocity);
		}
	}
};

float() ghost_speed_manager =
{
	float returnspeed;
	returnspeed = 0.0625/self.speed;

	if (self.ghost_state == 2) {
		returnspeed = (0.0625/self.speed)*1.33;
	}
	if (self.ghost_state == 3) {
		returnspeed = (0.0625/self.speed)*0.75;
	}

	return returnspeed;
}

void() particle_trails =
{
	if (self.ghost_state == 0)
		particle(self.bbox.origin, -self.bbox.velocity*10, 253, 1);
}

void() ai_ghost_create_trigger =
{
    self.trigger = spawn();

};

void() ai_ghost_voicethink =
{
	dprint(self.owner.ghost);
	dprint(": playing voice\n");

	self.nextthink = time + 0.4;

	if (!self.owner)
		return; // failsafe

	if (self.owner.ghost_state == 0)
	{
		sound(self.owner, CHAN_BODY, "ghosts/siren0.wav", 1, ATTN_NORM);
	}
	else if (self.owner.ghost_state == 2)
	{
		sound(self.owner, CHAN_BODY, "ghosts/fright.wav", 1, ATTN_NONE);
		self.nextthink = time + 1.056;
	}
	else if (self.owner.ghost_state == 3)
	{
		sound(self.owner, CHAN_BODY, "ghosts/eyes.wav", 1, ATTN_NORM);
		self.nextthink = time + 0.25;
	}
};


void() ai_ghost_think =
{
	if (self.target)
	{
		self.scatterpoint = find(world, targetname, self.target);
	}
	if (!self.scatterpoint)
	{
		self.scatterpoint = self;
		/*dprint("Couldn't find scatterpoint for ");
		dprint(self.ghost);
		dprint("\n");*/
	}

	
	self.origin = self.nextpos;
	self.origin_x = round(self.nextpos_x);
	self.origin_y = round(self.nextpos_y);
	self.origin_z = round(self.nextpos_z);
	self.nextpos = ai_ghost_getdir();

	ai_ghost_state_manager();
	self.ghost_last_pos = self.origin;
	makevectors(self.angles);
	//setorigin(self.back, self.origin - (v_forward * 5) + '0 0 64');
	
	/*dprint("Ghost at : ");
	dprint(ftos(self.origin_x));
	dprint(", ");
	dprint(ftos(self.origin_y));
	dprint("\n");*/

	self.bbox.takedamage = DAMAGE_YES;
	self.bbox.health = 1;
	self.bbox.th_die = ai_ghost_stun;

	self.speed = get_ghost_speed();
	self.nextthink = time + ghost_speed_manager();

	/*self.velocity = (self.nextpos - self.origin) * ghost_speed_manager();
	self.bbox.velocity = self.velocity;
	//self.bbox.touch = ai_damage_player;*/

	setorigin(self.bbox, self.origin);
	setorigin(self.sprite, self.origin + '0 0 64');
	setorigin(self.trigger, self.origin);

	particle_trails();

	//ai_check_player_overlap();
};

void() monster_ghost =
{
	precache_model("sprites/ghosts/blinky.spr");
	precache_model("sprites/ghosts/inky.spr");
	precache_model("sprites/ghosts/pinky.spr");
	precache_model("sprites/ghosts/clyde.spr");
	precache_model("sprites/ghosts/frightened.spr");

	precache_sound("ghosts/siren0.wav");
	precache_sound("ghosts/fright.wav");
	precache_sound("ghosts/eyes.wav");
	precache_sound("ghosts/eat_ghost.wav");
	precache_sound("pac/extend.wav");

	if (!self.ghost)
		self.ghost = "blinky";

	if (!self.ghost_basespeed)
	{
		self.ghost_basespeed = 2;
	}

	self.bbox = spawn();
	self.sprite = spawn();
	self.trigger = spawn();
	self.voice = spawn();
	//self.back = spawn();
	self.bbox.owner = self;
	self.sprite.owner = self;
	self.trigger.owner = self;
	self.voice.owner = self;
	//self.back.owner = self;
	self.bbox.origin = self.origin;
	self.sprite.origin = self.origin + '0 0 64';

	self.voice.classname = "ghost_voice";
	self.voice.think = ai_ghost_voicethink;
	self.voice.nextthink = time;
	self.voice.owner = self;


    if (deathmatch)
	{
		remove(self);
		return;
	}

	self.movetype = MOVETYPE_FLY;

	self.bbox.movetype = MOVETYPE_FLY;
	self.bbox.solid = SOLID_SLIDEBOX;
	setsize(self.bbox, '-48 -48 0', '48 48 112');

	self.trigger.movetype = MOVETYPE_NONE;
    self.trigger.solid = SOLID_TRIGGER;
    setsize(self.trigger, '-48 -48 0', '48 48 128');
    self.trigger.touch = ai_damage_player;

	//self.bbox.splash_react = ai_damage_player;

	ai_get_sprite(self.sprite,self);

	self.sprite.frame = 0;
	self.sprite.ghost_frame = 0;
	self.sprite.ghost_anim = 2;
	self.sprite.nextthink = time + self.speed*0.05;
	self.sprite.think = ai_ghost_animation_manager;

	/*self.back.frame = 6;
	self.back.ghost_frame = 6;
	self.back.ghost_anim = 2;
	self.back.nextthink = time + self.speed*0.05;
	self.back.think = ai_ghost_animation_manager;*/
	
	self.speed = self.ghost_basespeed;
	self.ghost_chasing = 0;
	self.ghost_gridsize = 128;
	self.ghost_last_pos = self.origin;
	self.ghost_spawn = self.origin;
	self.ghost_grid_offset_x = ((self.ghost_spawn_x/self.ghost_gridsize) - (floor(self.ghost_spawn_x/self.ghost_gridsize)))*self.ghost_gridsize;
	self.ghost_grid_offset_y = ((self.ghost_spawn_y/self.ghost_gridsize) - (floor(self.ghost_spawn_y/self.ghost_gridsize)))*self.ghost_gridsize;

	self.ghost_state = 0;

	self.nextpos = self.origin;

	if (!self.ghost_starttime) 
		self.ghost_starttime = 3;
    self.think = ai_ghost_think;
	self.nextthink = time + self.ghost_starttime;

	/*dprint(ftos(self.ghost_grid_offset_x));
	dprint(", ");
	dprint(ftos(self.ghost_grid_offset_y));
	dprint("\n");*/
};