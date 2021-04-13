class Agent {
  float x;
  float y;
  boolean redTeam;
  float angle;
  Blackboard blackboard;
  Task btree;
  PVector velocity;
  PVector linear_steering;
  float rotational_steering;
  float rotation;  // "angle velocity"
  boolean dead;
  boolean firing;
  Bullet bullet;
  int health;

  Agent(float x, float y, boolean redTeam, float angle) {
    this.x = x;
    this.y = y;
    this.redTeam = redTeam;
    this.angle = angle;
    this.blackboard = new Blackboard();
    this.velocity = new PVector(0, 0);
    this.linear_steering = new PVector(0, 0);
    this.rotational_steering = 0;
    this.rotation = 0;
    this.dead = false;
    this.firing = false;
    this.bullet = new Bullet();
    this.health = MAX_HEALTH;
  }

  void draw() {
    if (dead) {
      return;
    }
    translate(x, y);
    rotate(angle);
    if (redTeam) {
      fill(255*(health+2)/(MAX_HEALTH+2), 0, 0);
    } else {
      fill(0, 0, 255*(health+2)/(MAX_HEALTH+2));
    }
    ellipse(0, 0, AGENT_RADIUS*2, AGENT_RADIUS*2);
    line(0, 0, AGENT_RADIUS, 0);
    rotate(-angle);
    translate(-x, -y);
  }

  void setBTree(Task btree) {
    this.btree = btree;
  }

  void act() {
    checkDeath();
    if (dead) {
      return;
    }
    linear_steering = new PVector(0, 0);
    rotational_steering = 0;
    btree.execute();
    if (linear_steering.mag() > MAX_ACCEL) {
      linear_steering.setMag(MAX_ACCEL);
    }
    velocity.add(linear_steering);
    if (velocity.mag() > MAX_SPEED) {
      velocity.setMag(MAX_SPEED);
    }
    x += velocity.x;
    y += velocity.y;
    if (Math.abs(rotational_steering) > MAX_ROT_ACCEL) {
      rotational_steering = rotational_steering > 0 ? MAX_ROT_ACCEL : -MAX_ROT_ACCEL;
    }
    if (Math.abs(rotational_steering) > MAX_ROT_SPEED) {
      rotational_steering = Math.copySign(MAX_ROT_SPEED, rotational_steering);
    }
    rotation += rotational_steering;
    angle += rotation;
    if (firing && !bullet.active) {
      PVector firingVector = PVector.fromAngle(angle);
      PVector displacementVector = firingVector.copy().setMag(AGENT_RADIUS+BULLET_WIDTH);
      bullet = new Bullet(x + displacementVector.x, y + displacementVector.y, 
        firingVector);
      bullet.draw();
    } else if (bullet.active) {
      // We'll just do this here
      bullet.update();
      bullet.draw();
    }
  }

  // We will be in charge of damaging ourselves in response to enemy collisions & bullets;
  // same for them
  void checkDamage(Agent target) {
    if (target.dead) {
      return;
    }
    
    // Enemy collision
    if (dist(x, y, target.x, target.y) < AGENT_RADIUS *2) {
      health--;
    }
    
    if (target.bullet.active && dist(x, y, target.bullet.x, target.bullet.y) < AGENT_RADIUS + BULLET_WIDTH/2) {
      health--;
      target.bullet.active = false;
    }
    // Death checked later to avoid unfair advantage to the team checked second
    return;
  }

  void checkDeath() {
    if (health <= 0) {
      dead = true;
    }
  }
}
