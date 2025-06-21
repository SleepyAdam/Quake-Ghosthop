float finaltime;
float finalscore;

void() write_score = //This is a horrible disgusting way of getting around Quake's lack of string manipulation by sending a string one byte at a time.
{
	float minutes;
	float seconds;
	for(seconds = finaltime;seconds > 60;seconds = seconds - 60)
	{
		minutes += 1;
	}

	float minutelength = count_digits(minutes);
	float secondlength = count_digits(seconds);
    float scorelength = count_digits(finalscore);
	float levellength = count_digits(level);
    float i,digit;

    WriteByte(MSG_ALL, SVC_FINALE);
	if (level >= 33)
	{
		level = 32;
		WriteByte(MSG_ALL,'G');
		WriteByte(MSG_ALL,'A'); 
		WriteByte(MSG_ALL,'M');
		WriteByte(MSG_ALL,'E');
		WriteByte(MSG_ALL,' ');
		WriteByte(MSG_ALL,'C');
		WriteByte(MSG_ALL,'O');
		WriteByte(MSG_ALL,'M');
		WriteByte(MSG_ALL,'P');
		WriteByte(MSG_ALL,'L');
		WriteByte(MSG_ALL,'E');
		WriteByte(MSG_ALL,'T');
		WriteByte(MSG_ALL,'E');
		WriteByte(MSG_ALL,'!');
	}
    WriteByte(MSG_ALL,10);
    WriteByte(MSG_ALL,10);
    WriteByte(MSG_ALL,'S');
    WriteByte(MSG_ALL,'C');
    WriteByte(MSG_ALL,'O');
    WriteByte(MSG_ALL,'R');
    WriteByte(MSG_ALL,'E');
	for (i = 0; i < 25 - scorelength; i = i + 1)
    {
        WriteByte(MSG_ALL, '.');
    }

    for (i = scorelength - 1; i >= 0; i = i - 1)
    {
        digit = get_digit(finalscore, i);
        WriteByte(MSG_ALL, num_from_digit(digit));
    }
	WriteByte(MSG_ALL,10);
	WriteByte(MSG_ALL,'T');
	WriteByte(MSG_ALL,'I');
	WriteByte(MSG_ALL,'M');
	WriteByte(MSG_ALL,'E');
	for (i = 0; i < 23 - minutelength; i = i + 1)
    {
        WriteByte(MSG_ALL, '.');
    }
	for (i = minutelength - 1; i >= 0; i = i - 1)
    {
        digit = get_digit(minutes, i);
        WriteByte(MSG_ALL, num_from_digit(digit));
    }
	WriteByte(MSG_ALL,':');
	if (secondlength == 1) WriteByte(MSG_ALL, '0');
	for (i = secondlength - 1; i >= 0; i = i - 1)
    {
        digit = get_digit(seconds, i);
        WriteByte(MSG_ALL, num_from_digit(digit));
    }
	WriteByte(MSG_ALL,10);
	WriteByte(MSG_ALL,'D');
	WriteByte(MSG_ALL,'I');
	WriteByte(MSG_ALL,'F');
	WriteByte(MSG_ALL,'F');
	WriteByte(MSG_ALL,'I');
	WriteByte(MSG_ALL,'C');
	WriteByte(MSG_ALL,'U');
	WriteByte(MSG_ALL,'L');
	WriteByte(MSG_ALL,'T');
	WriteByte(MSG_ALL,'Y');
	if (skill == 0)
	{
		for (i = 0; i < 16; i = i + 1)
		{
			WriteByte(MSG_ALL, '.');
		}
		WriteByte(MSG_ALL,'E');
		WriteByte(MSG_ALL,'A');
		WriteByte(MSG_ALL,'S');
		WriteByte(MSG_ALL,'Y');
	}
	if (skill == 1)
	{
		for (i = 0; i < 14; i = i + 1)
		{
			WriteByte(MSG_ALL, '.');
		}
		WriteByte(MSG_ALL,'N');
		WriteByte(MSG_ALL,'O');
		WriteByte(MSG_ALL,'R');
		WriteByte(MSG_ALL,'M');
		WriteByte(MSG_ALL,'A');
		WriteByte(MSG_ALL,'L');
	}
	if (skill == 2)
	{
		for (i = 0; i < 16; i = i + 1)
		{
			WriteByte(MSG_ALL, '.');
		}
		WriteByte(MSG_ALL,'H');
		WriteByte(MSG_ALL,'A');
		WriteByte(MSG_ALL,'R');
		WriteByte(MSG_ALL,'D');
	}
	if (skill == 3)
	{
		for (i = 0; i < 11; i = i + 1)
		{
			WriteByte(MSG_ALL, '.');
		}
		WriteByte(MSG_ALL,'N');
		WriteByte(MSG_ALL,'I');
		WriteByte(MSG_ALL,'G');
		WriteByte(MSG_ALL,'H');
		WriteByte(MSG_ALL,'T');
		WriteByte(MSG_ALL,'M');
		WriteByte(MSG_ALL,'A');
		WriteByte(MSG_ALL,'R');
		WriteByte(MSG_ALL,'E');
	}
	WriteByte(MSG_ALL,10);
	WriteByte(MSG_ALL,'L');
	WriteByte(MSG_ALL,'E');
	WriteByte(MSG_ALL,'V');
	WriteByte(MSG_ALL,'E');
	WriteByte(MSG_ALL,'L');
	for (i = 0; i < 25 - levellength; i = i + 1)
    {
        WriteByte(MSG_ALL, '.');
    }
	for (i = levellength - 1; i >= 0; i = i - 1)
    {
        digit = get_digit(level, i);
        WriteByte(MSG_ALL, num_from_digit(digit));
    }

    WriteByte(MSG_ALL, 0); 
}

void() custom_intermissionthink =
{
	if (!intermission_running)
		return;

	self.view_ofs = '0 0 0';
	self.velocity = '0 0 0';
	self.fixangle = TRUE;
	self.angles = self.v_angle = FindIntermission().mangle;
	self.button0 = self.button1 = self.button2 = 0; 
	self.avelocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
};

void() custom_changelevel =
{
	entity pos;
	finaltime = time;
	finalscore = 0;
	intermission_running = 1;

// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte(MSG_ALL, SVC_CDTRACK);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 3);

	pos = FindIntermission();

	other = find(world, classname, "player");
	while (other != world)
	{
        other.health = 1;
        other.deadflag = DEAD_NO;
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE; 
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		finalscore += other.frags;
		setorigin(other, pos.origin);
		other = find(other, classname, "player");
	}

    write_score();
};


void() ResultScreen =
{
	entity o;

    // find a trigger changelevel
	o = find(world, classname, "trigger_changelevel");
	if (!o || mapname == "start")
	{ // go back to same map if no trigger_changelevel
		o = spawn();
		o.map = mapname;
	}

	nextmap = o.map;

	if (o.nextthink < time)
	{
		o.think = custom_changelevel;
		o.nextthink = time + 0.1;
	}
}