.float charge;
.float tocharge;
.float map_dmmode;
.float map_coopmode;
.float tofruit;
.float fruit_grabbed;
.float usetrackersound;

.string touchsound;

.entity fruit;
.entity tracker;

void() pellet_touch;
void() power_touch;

void() fruit_despawn =
{
    self.solid = SOLID_NOT;
    setmodel(self,string_null);
}

void() fruit_touch =
{
    float fruitscore;
    string fruitstring;
    switch(level)
    {
        case 1:
            fruitscore = 200;
            fruitstring = "Cherry!";
            break;
        case 2:
            fruitscore = 400;
            fruitstring = "Strawberry!";
            break;
        case 3:
            fruitscore = 600;
            fruitstring = "Peach!";
            break;
        case 4:
            fruitscore = 800;
            fruitstring = "Apple!";
            break;
        case 5:
            fruitscore = 1500;
            fruitstring = "Melon!";
            break;
        case 6:
            fruitscore = 2500;
            fruitstring = "Galaxian!";
            break;
        case 7:
            fruitscore = 4000;
            fruitstring = "Bell!";
            break;
        case 8:
            fruitscore = 5000;
            fruitstring = "Key!";
            break;
        default:
            fruitscore = 5000;
            fruitstring = "Key!";
            break;
    }

    addscore(other,fruitscore,1,1,fruitstring,string_null,string_null,string_null,string_null);
    sound(other,CHAN_VOICE,"pac/eat_fruit.wav",1,ATTN_NORM);
    fruit_despawn();
}

void() next_level =
{
    self.tracker.pelletsgrabbed = 1;
    self.tracker.tofruit = 70;
    self.tracker.fruit_grabbed = 0;
    entity e;
    level += 1;
    e = find(world,classname,"item_pellet");
    while (e)
    {
        setmodel(e, "sprites/pellet.spr");
        setsize(e, '-48 -48 0', '48 48 128');
        e.solid = SOLID_TRIGGER;
        e.touch = pellet_touch;
        setorigin(e,e.origin);
        e = find(e,classname,"item_pellet");
    }
    e = find(world,classname,"item_power");
    while(e)
    {
        setmodel(e, "sprites/power.spr");
        setsize(e, '-48 -48 0', '48 48 128');
        e.solid = SOLID_TRIGGER;
        e.touch = power_touch;
        setorigin(e,e.origin);
        e = find(e,classname,"item_power");
    }
    e = find(world,classname,"player");
    while(e)
    {
        centerprint(e,"Level ",ftos(level));
        e = find(e,classname,"player");
    }
    if (level >= 33)
    {
        ResultScreen();
    }
    ResetGhosts();
}

void() info_scatterpoint =
{
    self.classname = "info_scatterpoint";
    self.model = "";
};

void() pactracker_think =
{
    entity e;
    if (time > scattertime)
    {
        e = find(world, classname, "monster_ghost"); 
        while(e)
        {
            /*if (countdown > time)
            {
                e.nextthink = self.ghost_starttime;
            }*/ //this is such a horrible way to do this i'm so sorry
            if (scattermode == 1) {
                e.ghost_chasing = 1;
                if (e.ghost_state == 0) 
                {
                    e.angles_y += 180;
                    e.origin = e.ghost_last_pos;
                }
            }
            else 
            {
                e.ghost_chasing = 0;
            }

            e = find(e, classname, "monster_ghost");
        }
        if (scattermode == 1)
        {
            scattermode = 0;
            scattertime = time + 40;
        }
        else
        {
            scattermode = 1;
            scattertime = time + 7-(get_panic_speed()*0.5);
        }
    }

    self.nextthink = time + 0.1;
}

void() info_pactracker =
{
    precache_sound("pac/extend.wav");

    level = 1;

    self.pelletcount = 0;
    self.pelletsgrabbed = 0;
    self.tocharge = 45;
    self.think = pactracker_think;
    self.nextthink = time + 0.1;
    self.map_dmmode = (!self.map_dmmode) ? 0 : self.map_dmmode;
    self.map_coopmode = (!self.map_coopmode) ? 0 : self.map_coopmode;
    self.tofruit = 70;
    self.fruit_grabbed = 0;
    self.touchsound = "pac/eat_dot_0.wav";

    scattermode = 1;
    scattertime = time + 10;

    /*if ((deathmatch != self.map_dmmode) || (coop != self.map_coopmode))
    {
        cvar_set("deathmatch", ftos(self.map_dmmode));
        cvar_set("coop", ftos(self.map_coopmode));
        changelevel(mapname);
    }*/
    
    if (!self.lives) self.lives = 3;
};

void() pellet_touch =
{
    if (other.classname == "player")
    {
        if (floor(other.pelletsgrabbed/100) < 4)
            other.pellet_combo = floor(other.pelletsgrabbed/100) + 1;
        else
            other.pellet_combo = 5;
        self.tracker.pelletsgrabbed += 1;
        other.pelletsgrabbed += 1;
        other.charge += 1;
        if (other.printpellets == 1)
            addscore(other,10,other.pellet_combo,1,"Pellet"," x",ftos(other.pellet_combo),string_null,string_null);
        else
            addscore(other,10,other.pellet_combo,0,string_null,string_null,string_null,string_null,string_null);

        if (self.tracker.pelletsgrabbed >= self.tracker.pelletcount)
        {
            //sprint(other,"ALL DONE!\n");
            next_level();
        }

        if (self.tracker.pelletsgrabbed >= self.tracker.tofruit)
        {
            self.tracker.fruit.touch = fruit_touch;
            setsize(self.tracker.fruit, '-64 -64 -64', '64 64 64');
            self.tracker.fruit.solid = SOLID_TRIGGER;
            self.tracker.fruit.nextthink = time + 10;
            self.tracker.fruit.think = fruit_despawn;
            self.tracker.tofruit += 100;
            if (self.tracker.fruit_grabbed == 0)
            {
                setmodel(self.tracker.fruit,"sprites/fruits.spr");
                self.tracker.fruit.frame = (level - 1) < 7 ? (level - 1) : 7;
                dprint("Fruit spawned!");
            }
            self.tracker.fruit_grabbed = 1;
        }

        if (other.charge == self.tracker.tocharge)
        {
            other.charge = 0;
            other.ammo_rockets += 1;
            other.currentammo = other.ammo_rockets;
        }
        if (self.usetrackersound == 1)
        {
            if(self.tracker.touchsound != string_null)
                sound(other,CHAN_ITEM,self.tracker.touchsound,1,ATTN_NORM);
            if (self.tracker.touchsound == "pac/eat_dot_0.wav")
                self.tracker.touchsound = "pac/eat_dot_1.wav";
            else if (self.tracker.touchsound == "pac/eat_dot_1.wav")
                self.tracker.touchsound = "pac/eat_dot_0.wav";
        }
        else
            if(self.touchsound != string_null)
                sound(other,CHAN_ITEM,self.touchsound,1,ATTN_NORM);
        self.solid = SOLID_NOT;
        setmodel(self,string_null);
        //dprint(ftos(other.pelletsgrabbed));
        //dprint("\n");
        /*dprint(ftos(self.tracker.pelletsgrabbed));
        dprint(", ");
        dprint(ftos(self.tracker.pelletcount));
        dprint("\n");*/
    }
}

void() power_touch =
{
    if (other.classname == "player")
    {
        self.netname = "Power Pellet!";
        pellet_touch();
        powerup_touch();

        entity e;
        e = find(world, classname, "monster_ghost");
    
        while (e)
        {
            if (e.ghost_state != 3)
            {
                if (e.ghost_state != 2)
                {
                    e.angles_y += 180;
                    e.velocity = '0 0 0';
                }
                e.ghost_state = 2;
                e.frightened_counter = time + get_panic_speed();
                setorigin(e,e.ghost_last_pos);
                e.nextthink = time;
                e.voice.nextthink = time;
            }
            e = find(e, classname, "monster_ghost");
        }
    }
}

void() pellet_spawn =
{
    self.tracker = find(world, classname, "info_pactracker");
    if (self.tracker != world)
    {
        self.tracker.pelletcount = self.tracker.pelletcount + 1;
        dprint(ftos(self.tracker.pelletcount));
        dprint("\n");
        self.solid = SOLID_TRIGGER;
        if (self.classname == "item_power")
            self.touch = power_touch;
        else
            self.touch = pellet_touch;
    }
    else
    {
        dprint("Pac tracker not found!\n");
        self.nextthink = time + 0.01;
    }
}

void() item_pellet =
{
    precache_model("sprites/pellet.spr");
    precache_sound("pac/eat_dot_0.wav");
    precache_sound("pac/eat_dot_1.wav");

    setmodel(self, "sprites/pellet.spr");
    setsize(self, '-48 -48 0', '48 48 128');
    self.think = pellet_spawn;
    self.nextthink = time;
    self.usetrackersound = 1;
}

void() item_power =
{
    precache_model("sprites/power.spr");
    precache_sound("items/damage.wav");
	precache_sound("items/damage2.wav");
	precache_sound("items/damage3.wav");

    setmodel(self, "sprites/power.spr");
    setsize(self, '-48 -48 0', '48 48 128');
    self.think = pellet_spawn;
    self.nextthink = time;
    self.items = IT_QUAD;
    self.noise = "items/damage.wav";
}

void() tracker_find =
{
    self.tracker = find(world, classname, "info_pactracker");
    if (self.tracker)
    {
        dprint("Fruit found!\n");
        self.tracker.fruit = self;
    }
    else
    {
        dprint("Pac tracker not found!\n");
        self.nextthink = time + 0.01;
    }
}

void() item_fruit =
{
    precache_model("sprites/fruits.spr");
    precache_sound("pac/eat_fruit.wav");
    setmodel(self,string_null);
    self.think = tracker_find;
    self.nextthink = time + 1;
}