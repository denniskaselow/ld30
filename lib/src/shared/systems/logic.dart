part of shared;


class SpawningSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> tm;
  ComponentMapper<Spawner> sm;
  UnitManager unitManager;
  SpawningSystem() : super(Aspect.getAspectForAllOf([Transform, Spawner]));

  @override
  void processEntity(Entity entity) {
    var s = sm.get(entity);
    s.spawnTime -= world.delta;
    if (s.spawnTime <= 0.0) {
      var t = tm.get(entity);
      if (unitManager.isTileEmpty(t.x, t.y)) {
        world.createAndAddEntity([new Transform(t.x, t.y), new Unit(s.type, 10), new Renderable('peasant_${s.type}')]);
        s.spawnTime = 10000.0;
      }
    }
  }
}

class MovementSystem extends EntityProcessingSystem {
  UnitManager unitManager;
  ComponentMapper<Unit> um;
  ComponentMapper<Transform> tm;
  ComponentMapper<Move> mm;

  MovementSystem() : super(Aspect.getAspectForAllOf([Transform, Move, Unit]));


  @override
  void processEntity(Entity entity) {
    var u = um.get(entity);
    if (u.movesLeft > 0) {
      var t = tm.get(entity);
      var m = mm.get(entity);
      var targetX = t.x + m.x;
      var targetY = t.y + m.y;
      if (targetX >= 0 && targetY >= 0 && targetX < TILES_X && targetY < TILES_Y) {
        var targetEntity = unitManager.getEntity(targetX, targetY);
        if (null == targetEntity) {
          unitManager.unitCoords[t.x][t.y] = null;
          t.x += m.x;
          t.y += m.y;
          unitManager.unitCoords[t.x][t.y] = entity;
          u.movesLeft -= 1;
        } else {
          var otherUnit = um.get(targetEntity);
          if (otherUnit.faction != u.faction) {
            targetEntity..addComponent(new Defender(-m.x, -m.y))
                        ..changedInWorld();
            entity..addComponent(new Attacker(m.x, m.y));
            u.movesLeft -= 1;
          }
        }
      }
    }
    entity..removeComponent(Move)
          ..changedInWorld();
  }
}

class AttackerSystem extends EntityProcessingSystem {
  ComponentMapper<Attacker> am;
  ComponentMapper<Transform> tm;
  ComponentMapper<Unit> um;
  UnitManager unitManager;

  AttackerSystem() : super(Aspect.getAspectForAllOf([Transform, Attacker, Unit]));

  @override
  void processEntity(Entity entity) {
    var a = am.get(entity);
    var t = tm.get(entity);

    a.duration -= world.delta;
    if (a.duration <= 0.0) {
      entity..removeComponent(Attacker)
            ..changedInWorld();
      t.displacementX = 0.0;
      t.displacementY = 0.0;
      var enemyEntity = unitManager.getEntity(t.x + a.x, t.y + a.y);
      var unit = um.get(entity);
      var enemyUnit = um.get(enemyEntity);
      var strength = unit.offStrength + enemyUnit.defStrength;
      var counter = 0;
      while (counter < 10 && enemyUnit.health > 0.0 && unit.health > 0.0) {
        var fightResult = random.nextDouble() * strength;
        if (fightResult <= unit.offStrength) {
          enemyUnit.health -= unit.offStrength / 10;
        } else {
          unit.health -= enemyUnit.defStrength / 10;
        }
        counter++;
      }
      if (enemyUnit.health < 0.0) {
        enemyEntity..addComponent(new KilledInAction())
                   ..changedInWorld();
      } else if (unit.health < 0.0) {
        entity..addComponent(new KilledInAction())
              ..changedInWorld();
      }
    } else {
      var displacementFactor = sin(PI/2 * a.duration / 50.0);
      t.displacementX = TILE_SIZE / 2 * a.x * displacementFactor;
      t.displacementY = TILE_SIZE / 2 * a.y * displacementFactor;
    }
  }
}

class DefenderSystem extends EntityProcessingSystem {
  ComponentMapper<Defender> dm;
  ComponentMapper<Transform> tm;

  DefenderSystem() : super(Aspect.getAspectForAllOf([Transform, Defender]));

  @override
  void processEntity(Entity entity) {
    var d = dm.get(entity);
    var t = tm.get(entity);

    d.duration -= world.delta;
    if (d.duration <= 0.0) {
      entity..removeComponent(Defender)
            ..changedInWorld();
      t.displacementX = 0.0;
      t.displacementY = 0.0;
    } else {
      var displacementFactor = -sin(PI/2 * d.duration / 50.0);
      t.displacementX = TILE_SIZE / 4 * d.x * displacementFactor;
      t.displacementY = TILE_SIZE / 4 * d.y * displacementFactor;
    }
  }
}

class KilledInActionSystem extends EntityProcessingSystem {
  KilledInActionSystem() : super(Aspect.getAspectForAllOf([KilledInAction]));

  @override
  void processEntity(Entity entity) {
    entity.deleteFromWorld();
  }
}