import java.util.HashMap;

static final float AGENT_RADIUS = 20;
static final int ARENA_SIZE = 800;
static final int TEAM_SIZE = 5;
// Agent max speed
static final float MAX_SPEED = 5;
static final float MAX_ACCEL = 8;
static final float MAX_ROT_SPEED = ((float) Math.PI)/20;
static final float MAX_ROT_ACCEL = ((float) Math.PI)/30;
static final float ALIGN_TARGET_RAD = ((float) Math.PI)/60;
static final float ALIGN_SLOW_RAD = ((float) Math.PI)/15;
static final float ARRIVE_SLOW_RAD = 100;
static final float ARRIVE_STOP_RAD = 50;
static final float BULLET_WIDTH = 3;
static final float BULLET_SPEED = 10;
static final int MAX_HEALTH = 200;

// Return codes for Behavior Tree tasks.
// If you wanted to implement an action that takes several frames,
// you could add a BUSY signal as well as a way to keep track of where
// you are in the tree, picking up again on the next frame.  But this assignment
// doesn't require that.
static final int FAIL = 0;
static final int SUCCESS = 1;

Agent[] redTeam = new Agent[TEAM_SIZE];
Agent[] blueTeam = new Agent[TEAM_SIZE];

void settings() {
  size(ARENA_SIZE, ARENA_SIZE);
}

void setup() {
  // Since there's no object representing a team, each agent will have its own blackboard with which to advertise
  // relevant information to its peers (like its target).  The information could be encoded as strings to be parsed, but
  // to keep things simple, we'll point to actual objects when it makes sense to.
  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i] = new Agent((float)ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, true, (float)PI);
    redTeam[i].blackboard.put("Friends", redTeam);
    redTeam[i].blackboard.put("Enemies", blueTeam);
    redTeam[i].blackboard.put("Agent", redTeam[i]);

    //left branch of red team btree
    //Shoot redShoot = new Shoot(redTeam[i].blackboard);
    
    //right branch of red team btree
    /*Mark redMark = new Mark(redTeam[i].blackboard);
    Align redAlign = new Align(redTeam[i].blackboard);
    Sequence markThenAim = new Sequence(new Task[] {redMark, redAlign});
    
    //red team btree
    Sequence redBtree = new Sequence(new Task[] {redShoot, markThenAim});
    
    redTeam[i].setBTree(redMark);*/
   
    blueTeam[i] = new Agent((float)3*ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, false, 0);
    blueTeam[i].blackboard.put("Enemies", redTeam);
    blueTeam[i].blackboard.put("Friends", blueTeam);
    blueTeam[i].blackboard.put("Agent", blueTeam[i]);
    
    //left branch of blue team btree
    Shoot blueShoot = new Shoot(blueTeam[i].blackboard);
    
    //right branch of blue team btree
    //help or mark branch for blue team
    Help blueHelp = new Help(blueTeam[i].blackboard);
    Mark blueMark = new Mark(blueTeam[i].blackboard);
    //Task loBlueMarkingTasks[] = {blueHelp, blueMark};
    Selector blueMarkingTasks = new Selector(new Task[]{blueHelp, blueMark});

    //arrive then aim branch for blue team
    Align blueAlign = new Align(blueTeam[i].blackboard);
    Arrive blueArrive = new Arrive(blueTeam[i].blackboard);
    //Task loBlueMovementTasks[] = {blueAlign, blueArrive};
    Sequence blueMovementTasks = new Sequence(new Task[]{blueAlign, blueArrive});
    
    //overall right branch for blue team
    //Task loBlueMarkingThenMovement[] = {blueMarkingTasks, blueMovementTasks};
    Sequence blueMarkingThenMovement = new Sequence(new Task[]{blueMarkingTasks, blueMovementTasks});
    
    //blue team btree
    //Task loBlueBtree[] = {blueShoot, blueMarkingThenMovement};
    Selector blueBtree = new Selector(new Task[]{blueShoot, blueMarkingThenMovement});
    
    blueTeam[i].setBTree(blueBtree);
    
    //mark then align
    Align redAlign = new Align(redTeam[i].blackboard);
    Mark redMark = new Mark(redTeam[i].blackboard);
    //Task loRedMarkingTasks[] = {redMark, redAlign};
    Sequence redMarkingTasks = new Sequence(new Task[]{redMark, redAlign});
    
    //shoot or mark and align
    Shoot redShoot = new Shoot(redTeam[i].blackboard);
    //Task loRedBtree[] = {redShoot, redMarkingTasks};
    Selector redBTree = new Selector(new Task[]{redShoot, redMarkingTasks});
    redTeam[i].setBTree(redBTree);
  }
}

void draw() {
  background(128, 128, 128);
  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i].act();
    blueTeam[i].act();
  }
  for (int i = 0; i < TEAM_SIZE; i++) {
    for (int j = 0; j < TEAM_SIZE; j++) {
      if (!redTeam[i].dead) {
        redTeam[i].checkDamage(blueTeam[j]);
      }
      if (!redTeam[i].dead) {
        blueTeam[i].checkDamage(redTeam[j]);
      }
    }
    redTeam[i].draw();
    blueTeam[i].draw();
  }
}

//returns true if there are any currently alive agents in the given array of agents
boolean anyAlive(Agent[] agents){
  for(int i = 0; i < agents.length; i += 1) {
    if(!agents[i].dead) {
      return true; 
    }
  }
  
  return false;
}

//returns true if there are currently any alive marks in the given array of agents
boolean anyAliveMarks(Agent[] agents) {
   for(int i = 0; i < agents.length; i += 1) {
    if(agents[i].blackboard.get("Mark") != null) {
      if(!((Agent)agents[i].blackboard.get("Mark")).dead){
        return true;
      }
    }
  }
  
  return false;
}
