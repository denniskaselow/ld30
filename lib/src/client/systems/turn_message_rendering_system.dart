part of client;

class TurnMessageRenderingSystem extends EntityProcessingSystem {
  ComponentMapper<NextTurnInfo> im;

  CanvasRenderingContext2D ctx;
  TurnMessageRenderingSystem(this.ctx) : super(Aspect.getAspectForAllOf([NextTurnInfo]));


  @override
  void processEntity(Entity entity) {
    var info = im.get(entity);

    info.timer -= world.delta;
    if (info.timer <= 0.0) {
      entity.deleteFromWorld();
      return;
    }

    String infoText = getInfoText();
    ctx..save()
       ..globalAlpha = info.timer / 1000.0
       ..fillStyle = 'grey'
       ..font = '20px Verdana'
       ..fillText(infoText, 400 - ctx.measureText(infoText).width / 2, 290)
       ..restore();
  }

  String getInfoText() {
    if (gameState.currentFaction == gameState.playerFaction) {
      return 'YOUR TURN';
    } else if (gameState.currentFaction == F_HELL) {
      return 'THE PORTALS OF HELL HAVE OPENED';
    } else if (gameState.currentFaction == F_HEAVEN) {
      return 'THE ANGELS BRING DOOMSDAY';
    } else if (gameState.currentFaction == F_ICE) {
      return 'WINTER IS COMING';
    } else if (gameState.currentFaction == F_FIRE) {
      return "IT'S GETTING HOT IN HERE";
    }
    return '';
  }
}