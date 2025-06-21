float level;
float scattertime;
float scattermode;
float intermission_running;
//float countdown;

.float printpellets;
.float printmessages;
.float locked;

.float last_land_time;
.float old_flags;
.float last_warn_time;
.float frightened_counter;
.float scary;
.float lives;
.float rocket_kills;
.float ghost_basespeed;
.float ghost_combo;
.float pellet_combo;
.float life_points;
.float rj_active;
.float rj_combo;

.float pelletcount;
.float pelletsgrabbed;

.float ascorestring1;
.float ascorestring2;
.float ascorestring3;
.float ascorestring4;
.float ascorestring5;
.float bscorestring1;
.float bscorestring2;
.float bscorestring3;
.float bscorestring4;
.float bscorestring5;
.float cscorestring1;
.float cscorestring2;
.float cscorestring3;
.float cscorestring4;
.float cscorestring5;
.float dscorestring1;
.float dscorestring2;
.float dscorestring3;
.float dscorestring4;
.float dscorestring5;
.float escorestring1;
.float escorestring2;
.float escorestring3;
.float escorestring4;
.float escorestring5;

.vector lastvel;
.vector saved_horiz_velocity;

.entity child;
.entity last_attacker;
.entity last_inflictor;

.float game_started;

.void() splash_react;

float round(float f)
{
    if (fabs(floor(f) - f) < fabs(ceil(f) - f))
        return floor(f);
    else
        return ceil(f);
}

vector angle_from_vector(vector v)
{
    vector angles;
    angles_x = -vectoangles(v).x; // pitch
    angles_y = vectoangles(v).y;  // yaw
    angles_z = 0;
    return angles;
}

float dotproduct(vector a, vector b)
{
    return a_x*b_x + a_y*b_y + a_z*b_z;
}


vector mirror_across(vector A, vector B)
{
    vector Bnorm, proj, rej;
    float dot;

    Bnorm = normalize(B);
    dot = dotproduct(A, Bnorm);
    proj = Bnorm * dot;
    rej = A - proj;
    return A - (rej * 2);
}

float power_of_ten(float n)
{
    float result = 1;
    while (n > 0)
    {
        result *= 10;
        n -= 1;
    }
    return result;
}


float get_digit(float val, float n)
{
    return floor(val / power_of_ten(n)) % 10;
}

float count_digits(float n)
{
    float count;
    n = fabs(n);
    count = 0;

    if (n < 1)
        return 1;

    while (n >= 1)
    {
        count = count + 1;
        n = n / 10;
    }

    return count;
}

float num_from_digit(float digit)
{
    return 48 + digit; // 48 = '0'
}


float() get_panic_speed =
{
    float panic_time,i,baseline;

	baseline = 8;
	if (level > 12) baseline = 10;
	i = level;

	while (i > baseline) i -= baseline;
	panic_time = 10 - i;

    return panic_time;
}

float() get_ghost_speed =
{
    float ghost_speed,i,softlimit,hardlimit,loop;

    ghost_speed = 0;
    softlimit = 3.5;
    hardlimit = 5;
    loop = level - 1;

    for (i = 1;i < loop;i = i + 1)
    {
        if ((ghost_speed + self.ghost_basespeed) >= softlimit) break;
        ghost_speed += 0.2;
    }
    
    for (i = i;i < loop;i = i + 1)
        if ((ghost_speed + self.ghost_basespeed) >= hardlimit) break;
        ghost_speed += 0.1;
    
    /*dprint("Speed : ");
    dprint(ftos(ghost_speed + self.ghost_basespeed));
    dprint("\n");*/

    return ghost_speed + self.ghost_basespeed;
}

void(entity e, float score, float mult, float print, string scorestring, string scorestring2, string scorestring3, string scorestring4, string scorestring5) addscore =
{
    if (e.rj_active == TRUE) e.rj_combo += score*mult*0.5;

    e.frags += score*mult;
    e.life_points += score*mult;

    if (print == 1 && e.printmessages == 1)
    {
        sprint(e,ftos(e.frags));
        sprint(e," | +");
        sprint(e,ftos(score*mult));
        sprint(e," ");
        sprint(e,scorestring);
        sprint(e,scorestring2);
        sprint(e,scorestring3);
        sprint(e,scorestring4);
        sprint(e,scorestring5);
        sprint(e,"\n");
    }
    if (e.life_points >= 25000)
    {
        e.lives += 1;
        e.life_points = 0;
        sprint(e,"Extra Life! ");
        sprint(e,ftos(e.lives));
        sprint(e," Lives Left.");
        sprint(e,"\n");
        sound(e,CHAN_AUTO,"pac/extend.wav",1,ATTN_NORM);
    }
}

void() ResetGhosts;

void() ResultScreen;

void() monster_ghost;

void() custom_intermissionthink;

float SVC_ENDGAME = 26;