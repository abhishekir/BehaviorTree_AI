class Bullet {
  boolean active;
  float x;
  float y;
  PVector velocity;

  Bullet() {
    active = false;
    x = 0;
    y = 0;
    velocity = new PVector(0, 0);
  }

  Bullet(float x, float y, PVector direction) {
    active = true;
    this.x = x;
    this.y = y;
    this.velocity = direction.setMag(BULLET_SPEED);
  }

  void draw() {
    if (!active) {
      return;
    }
    fill(0, 0, 0);
    ellipse(x, y, BULLET_WIDTH, BULLET_WIDTH);
  }

  void update() {
    if (!active) {
      return;
    }
    x += velocity.x;
    y += velocity.y;
    if (x < 0 || y < 0 || x > ARENA_SIZE || y > ARENA_SIZE) {
      // offscreen
      active = false;
    }
  }
}
