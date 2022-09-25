package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class Nums extends FlxSprite
{
	public var targetY:Float = 0;

	public var distance:Float = 29;
	public var location:Float=300;
	public var change:Int=0;


	public function new(x:Float, y:Float,?i:Int)
	{
		super(x, y);
		loadGraphic(Paths.image('hp/num000' + i));
		antialiasing = ClientPrefs.globalAntialiasing;
	}
	var fakeFramerate:Int = Math.round((1 / 70) / 10);
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		y = FlxMath.lerp(y, (targetY * distance) + location, CoolUtil.boundTo(70 * 17, 0, 1));
	}
   
	
	
}
