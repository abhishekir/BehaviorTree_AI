abstract class Task {
  abstract int execute();  // returns FAIL = 0, SUCCESS = 1
  Blackboard blackboard;
  // You can implement an abstract clone() here, or you may not find it necessary
}

class Blackboard {
  HashMap<String, Object> lookup;

  Blackboard() {
    lookup = new HashMap<String, Object>();
  }

  public Object get(String key) {
    return lookup.get(key);
  }

  public void put(String key, Object val) {
    lookup.put(key, val);
  }
}

class Flee extends Task {
  Flee(Blackboard bb) {
    this.blackboard = bb;
  }

  int execute() {
    Agent agent = (Agent) blackboard.get("Agent");
    Agent[] enemies = (Agent[]) blackboard.get("Enemies");

    PVector steering = new PVector(0, 0);
    for (int i = 0; i < enemies.length; i++) {
      // Want a vector that points from the enemy - then don't have to flip it
      PVector displacement = new PVector(agent.x - enemies[i].x, agent.y - enemies[i].y);
      steering.add(displacement);
    }
    if (steering.mag() > MAX_ACCEL) {
      steering.setMag(MAX_ACCEL);
    }
    agent.linear_steering.add(steering);

    return SUCCESS;
  }
}

class Sequence extends Task {
  Task[] tasks;  
  
  Sequence(Task[] tasks){
    this.tasks = tasks; 
  }
  
  int execute() {
    for(Task task : tasks) {
      if(task.execute() == FAIL){
        return FAIL;
      }
    }
    return SUCCESS;
  }  
}

class Selector extends Task {
  Task[] tasks;  
  
  Selector(Task[] tasks){
    this.tasks = tasks; 
  }
  
  int execute() {
    for(Task task : tasks) {
      if(task.execute() == SUCCESS){
        return SUCCESS;
      }
    }
    return FAIL;
  }  
}

class Shoot extends Task {
  Shoot(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute() {
    Agent agent = (Agent)blackboard.get("Agent");
    
    if(agent.bullet.active){
      return FAIL;
    }
    else {
      agent.firing = true;
      return SUCCESS;
    }
  }
}

class Mark extends Task {
  Mark(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute() {
    Agent[] enemies = (Agent[])this.blackboard.get("Enemies");
    Agent agent = (Agent)blackboard.get("Agent");
    
    //task fails if there are no enemies alive to mark
    if(!anyAlive(enemies)) {
      return FAIL; 
    }
    
    Agent currClosest = enemies[0];
    
    //initialize currClosest w/ a non-dead enemy
    for(int i = 0; i < enemies.length; i += 1) {
       if(!enemies[i].dead){
         currClosest = enemies[i];
       }
    }
    
    for(int i = 0; i < enemies.length; i++){
       Agent currEnemy = enemies[i];
       //if the current enemy is closer than the current closest, and the current enemy is not dead, update the current closest
       if((dist(agent.x, agent.y, currEnemy.x, currEnemy.y) < dist(agent.x, agent.y, currClosest.x, currClosest.y)) && !currEnemy.dead) {
         currClosest = currEnemy; 
       }
    }
    
    this.blackboard.put("Mark", currClosest);
    
    return SUCCESS;
  }
}

class Help extends Task {
  Help(Blackboard bb) {
    this.blackboard = bb; 
  }
  
  int execute() {
    Agent[] allies = (Agent[])this.blackboard.get("Friends");
    Agent agent = (Agent)blackboard.get("Agent");
    
    //task fails if there are no allies alive to help
    if(!anyAlive(allies)) {
      return FAIL; 
    }
    
    //task fails if there are no alive marks among this agent's allies
    if(!anyAliveMarks(allies)){
      return FAIL; 
    }
    
    Agent currClosest = allies[0];
      
    //initialize currClosest w/ a non-dead ally w/ a non-dead mark
    for(int i = 0; i < allies.length; i += 1) {
       if(!allies[i].dead && allies[i].blackboard.get("Mark") != null && !((Agent)allies[i].blackboard.get("Mark")).dead){
         currClosest = allies[i];
       }
    }
      
    for(int i = 0; i < allies.length; i++){
      Agent currAlly = allies[i];
      //if the current ally has a mark, consider it for the closest ally
      if(currAlly.blackboard.get("Mark") != null){
        Agent currMark = (Agent)currAlly.blackboard.get("Mark");
        //if the current enemy is closer than the current closest, and the current enemy is not dead, update the current closest
        if((dist(agent.x, agent.y, currAlly.x, currAlly.y) < dist(agent.x, agent.y, currClosest.x, currClosest.y)) && !currAlly.dead && !currMark.dead) {
          currClosest = currAlly; 
        }
      }
    }
    
    
    //check if the closest 
    this.blackboard.put("Mark", (Agent)currClosest.blackboard.get("Mark"));
      
    return SUCCESS;
  }
}

class Align extends Task{
  Align(Blackboard bb){
    this.blackboard = bb; 
  }
  
  int execute(){
    if((Agent)this.blackboard.get("Mark") == null) {
      return FAIL; 
    }
    
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    
    PVector displacement = new PVector(mark.x - agent.x, mark.y - agent.y);
    float target_angle = displacement.heading();
    float rot_displacement = target_angle - agent.angle;
    
    //map to -pi to pi
    rot_displacement = ((rot_displacement + PI) % (2*PI)) - PI;
     
    if(abs(rot_displacement) <= (ALIGN_TARGET_RAD*2)){
      agent.rotation = 0;
      return SUCCESS;
    }

    float max_speed = MAX_ROT_SPEED;
    
    if(abs(rot_displacement) <= (ALIGN_SLOW_RAD*2)){
       max_speed = ((abs(rot_displacement))/ALIGN_SLOW_RAD)*(MAX_ROT_SPEED);
    }
    
    if(abs(rot_displacement) > max_speed){
      rot_displacement = (rot_displacement)*(max_speed/(abs(rot_displacement))); 
    }
    
    float rot_accel = rot_displacement - agent.rotation;
    
    if(rot_accel > MAX_ROT_ACCEL) {
      rot_accel = (rot_accel)*(MAX_ROT_ACCEL/(abs(rot_accel)));
    }
    
    agent.rotational_steering = rot_accel;
    
    return SUCCESS;
    
  }
}

class Arrive extends Task{
  Arrive(Blackboard bb){
    this.blackboard = bb; 
  }
  
  int execute(){
    if((Agent)this.blackboard.get("Mark") == null) {
      return FAIL; 
    }
    
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    
    PVector steering = new PVector(0, 0);
    PVector displacement = new PVector(mark.x - agent.x, mark.y - agent.y);
    
    if(displacement.mag() <= ARRIVE_STOP_RAD){
      agent.velocity = new PVector(0,0);
      return SUCCESS;
    }
    
    float max_speed = MAX_SPEED;
    
    //inside slow radius, scale down speed
    if(displacement.mag() <= ARRIVE_SLOW_RAD){
       max_speed = ((displacement.mag()/ARRIVE_SLOW_RAD)*MAX_SPEED);
    }
    
    if(displacement.mag() > max_speed){
      displacement.setMag(max_speed);
    }
    
    //get acceleration from current velocity to target velocity
    PVector accel = PVector.sub(displacement, agent.velocity);
    
    steering.add(accel);
    if (steering.mag() > MAX_ACCEL) {
      steering.setMag(MAX_ACCEL);
    }
    
    agent.linear_steering.add(steering);

    return SUCCESS;
    
  }
}
