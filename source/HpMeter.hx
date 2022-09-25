package;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;

#if sys
import sys.FileSystem;
#end

using StringTools;

class HpMeter extends FlxTypedGroup<FlxBasic>
{
    var baseX:Flaot=0;
    var baseY:Flaot=0;
    var face:FlxSprite;
    var back:FlxSprite;
    
    var left:FlxSprite;
    var mid:FlxSprite;
    var right:FlxSprite;

    var leftUpper:FlxSprite;
    var midUpper:FlxSprite;
    var rightUpper:FlxSprite;

    var leftLower:FlxSprite;
    var midLower:FlxSprite;
    var rightLower:FlxSprite;
     
    var leftUpper:Int;
    var midUpper:Int;
    var rightUpper:Int;

    var leftRLower:Int;
    var midRLower:Int;
    var rightRLower:Int;



	public function new(baseX:Flaot,baseY:Float,cam:FlxGObject,leftR:Int,midR:Int,rightR:Int)
	{
		super();
	
        this.baseX = baseX;
        this.baseY = baseY;


        face = new FlxSprite(baseX,baseY);
		face.frames = Paths.getSparrowAtlas('hp/hp');
		face.animation.addByPrefix('bump', 'hp', 24, false);
      
        back = new FlxSprite(baseX,baseY).loadGraphic(Paths.image('hp/hpback'));
	
        leftRUpper=leftR-1;
        midUpper=midR-1;
        rightUpper=rightR-1;

        leftRLower=leftR+1;
        midRLower=midR+1;
        rightRLower=rightR+1;

       
        watchNumbers(leftRUpper);
        watchNumbers(midUpper);
        watchNumbers(rightUpper);
        watchNumbers(leftRLower);
        watchNumbers(midRLower);
        watchNumbers(rightRLower);
        watchNumbers(left);
        watchNumbers(mid);
        watchNumbers(right);


    
        left = new FlxSprite(baseX+90,baseY+33).loadGraphic(Paths.image('hp/num000'+leftR));
        mid = new FlxSprite(baseX+120,baseY+33).loadGraphic(Paths.image('hp/num000'+midR));
        right = new FlxSprite(baseX+150,baseY+33).loadGraphic(Paths.image('hp/num000'+rightR));

        leftUpper = new FlxSprite(baseX+90,baseY+33).loadGraphic(Paths.image('hp/num000'+leftRUpper));
        midUpper = new FlxSprite(baseX+120,baseY+33).loadGraphic(Paths.image('hp/num000'+midUpper));
        rightUpper = new FlxSprite(baseX+150,baseY+33).loadGraphic(Paths.image('hp/num000'+rightUpper));
    
    
        leftLower = new FlxSprite(baseX+90,baseY+33).loadGraphic(Paths.image('hp/num000'+leftRLower));
        midLower = new FlxSprite(baseX+120,baseY+33).loadGraphic(Paths.image('hp/num000'+midRLower));
        rightLower = new FlxSprite(baseX+150,baseY+33).loadGraphic(Paths.image('hp/num000'+rightRLower));
       
        add(back);
        add(left);
        add(mid);
        add(right);
        add(leftUpper);
        add(midUpper);
        add(rightUpper);
        add(leftLower);
        add(midLower);
        add(rightLower);
        add(face);
     


    	
			
        
		

	
		
	}
    public function watchNumbers(i:Int)
        {
          if(i<0)i=9;
          if(i>9)i=0;
        }
 
        public function watchNumbers(i:Int)
            {
              if(i<0)i=9;
              if(i>9)i=0;
            }






	override public function update(elapsed:Float)
        {
            super.update(elapsed)
        
 
            watchNumbers(leftRUpper);
            watchNumbers(midUpper);
            watchNumbers(rightUpper);
            watchNumbers(leftRLower);
            watchNumbers(midRLower);
            watchNumbers(rightRLower);
            watchNumbers(left);
            watchNumbers(mid);
            watchNumbers(right);
    





        }
	


	



}
