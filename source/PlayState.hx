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

class PlayState extends MusicBeatState
{
	public static var STRUM_X = -500;
	public static var STRUM_X_MIDDLESCROLL = -278;


	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;


	public var TIME_R:Int = 255;
	public var TIME_G:Int = 255;
	public var TIME_B:Int = 255;
	
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var finalshowdown:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	var parrry:FlxSprite = new FlxSprite(700, 300); //Needs to be global for later
	public var spacebar = new FlxSprite(750, 400);



	


	var heyTimer:Float;

	
	var wiggleShit:WiggleEffect = new WiggleEffect();

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	
	var parryMiss:Int = 0;

	var	beys:FlxSprite; 
	var	beysAlert:FlxSprite; 
	var	beysglow:FlxSprite; 
	var boltsGroup:FlxTypedGroup<FlxSprite>;
	var boltsGroup2:FlxTypedGroup<FlxSprite>;

	var	overlay:FlxSprite; 


	var baseX=625;
	var baseY=350;
	var musthitaddX=290;
	var musthitaddY=100;
	var camChange=89;

    var thunderVolume:Array<Float>=[0.2,0.3,0.45,0.5,0.6,0.7,0.75];

	var adj:Int = 65;

  /*  var hitwindowTest:FlxSprite;

    var hitcounterText:FlxText;*/

	var timeClash:Float=0.12;//2 frames?
	var hitwindow:Float=0.4;////the player has this much time to hitspace


	/////
	function thunderSound()
		{
			FlxG.sound.play(Paths.music("thunder"+FlxG.random.int(0,7),"platform"),thunderVolume[FlxG.random.int(0,6)]);
		}

		override public function create()
			{
				#if MODS_ALLOWED
				Paths.destroyLoadedImages();
				#end
		
				// for lua
				instance = this;
		
				debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
				debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
				];
				
				// For the "Just the Two of Us" achievement
				for (i in 0...keysArray.length)
				{
					keysPressed.push(false);
				}
		
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
		
				// Gameplay settings
				healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
				healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
				instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
				practiceMode = ClientPrefs.getGameplaySetting('practice', false);
				cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
				// var gameCam:FlxCamera = FlxG.camera;
				camGame = new FlxCamera();
				camHUD = new FlxCamera();
				camOther = new FlxCamera();
				camHUD.bgColor.alpha = 0;
				camOther.bgColor.alpha = 0;
		
				FlxG.cameras.reset(camGame);
				FlxG.cameras.add(camHUD);
				FlxG.cameras.add(camOther);
				grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		
				FlxCamera.defaultCameras = [camGame];
				CustomFadeTransition.nextCamera = camOther;
				//FlxG.cameras.setDefaultDrawTarget(camGame, true);
		
				persistentUpdate = true;
				persistentDraw = true;
		
				if (SONG == null)
					SONG = Song.loadFromJson('tutorial');
		
				Conductor.mapBPMChanges(SONG);
				Conductor.changeBPM(SONG.bpm);
		
				#if desktop
				storyDifficultyText = CoolUtil.difficulties[storyDifficulty];
		
				// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
				if (isStoryMode)
				{
					detailsText = "lol";
				}
				else
				{
					detailsText = "Freeplay";
				}
		
				// String for when the game is paused
				detailsPausedText = "Paused - " + detailsText;
				#end
		
				GameOverSubstate.resetVariables();
				var songName:String = Paths.formatToSongPath(SONG.song);
				curStage = PlayState.SONG.stage;
				//trace('stage is: ' + curStage);
				
				 curStage="platform";
		
		
				var stageData:StageFile = StageData.getStageFile(curStage);
				if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
					stageData = {
						directory: "",
						defaultZoom: 0.9,
						isPixelStage: false,
					
						boyfriend: [770, 100],
						opponent: [100, 100],
						timeBarColor:[255,255,255],
				
						hitwindow:0.4,
						delay:0.12
					
					};
				}
		
				defaultCamZoom = stageData.defaultZoom;
				isPixelStage = stageData.isPixelStage;
				BF_X = stageData.boyfriend[0];
				BF_Y = stageData.boyfriend[1];
				DAD_X = stageData.opponent[0];
				DAD_Y = stageData.opponent[1];
				TIME_R =stageData.timeBarColor[0];
				TIME_G =stageData.timeBarColor[1];
				TIME_B =stageData.timeBarColor[2];
				timeClash =stageData.delay;
				hitwindow =stageData.hitwindow;

		
		
				boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
				dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
				
				
			
		
		
				//stage shit starts here
		
		
		
		
				var bfbars:FlxSprite = new FlxSprite(1108.35, 551.75).loadGraphic(Paths.image('bfbars',"platform"));
				bfbars.antialiasing = ClientPrefs.globalAntialiasing;
				var	bfplatform:FlxSprite  = new FlxSprite(1025.6, 491.35).loadGraphic(Paths.image('bfplatform',"platform"));
				bfplatform.antialiasing = ClientPrefs.globalAntialiasing;
				var stand:FlxSprite  = new FlxSprite(-276.35, 282.85).loadGraphic(Paths.image('stand',"platform"));
				stand.antialiasing = ClientPrefs.globalAntialiasing;
				var bayplace:FlxSprite  = new FlxSprite(-124.85, 398.45).loadGraphic(Paths.image('grands',"platform"));
				bayplace.antialiasing = ClientPrefs.globalAntialiasing;
				var cloud1:FlxSprite  = new FlxSprite(742.9, -161.9).loadGraphic(Paths.image('clouds2',"platform"));
				cloud1.antialiasing = ClientPrefs.globalAntialiasing;
				var cloud2:FlxSprite  = new FlxSprite(-517.7, -316.7).loadGraphic(Paths.image('clouds',"platform"));
				cloud2.antialiasing = ClientPrefs.globalAntialiasing;
				var city1:FlxSprite  = new FlxSprite(-347.6, 224).loadGraphic(Paths.image('cityone',"platform"));
				city1.antialiasing = ClientPrefs.globalAntialiasing;
				var city2:FlxSprite  = new FlxSprite(-541.2, 301.8).loadGraphic(Paths.image('citytwo',"platform"));
				city2.antialiasing = ClientPrefs.globalAntialiasing;
				var farbg:FlxSprite  = new FlxSprite(-429.3, -162.75).loadGraphic(Paths.image('skyback',"platform"));
				farbg.antialiasing = ClientPrefs.globalAntialiasing;


			
			
				city2.scrollFactor.set(0.65, 0.7);
				city1.scrollFactor.set(0.75, 0.7);
				cloud2.scrollFactor.set(0.7, 0.5);
				cloud1.scrollFactor.set(0.8, 0.7);
		
				overlay = new FlxSprite(-648.1, -426.15);
				overlay.frames =  Paths.getSparrowAtlas('overlay',"platform");
				overlay.animation.addByPrefix('flash', 'overlayforlights',20,false);
				overlay.animation.addByNames('white', ['overlayforlights0000'],1,true);
				overlay.alpha=0;
				overlay.blend=ADD;
		
		
				beys = new FlxSprite(83.5, 440.5);
				beys.frames =  Paths.getSparrowAtlas('theboys',"platform");
				beys.animation.addByPrefix('idle', 'idle',24,true);
				for(i in 0...4)
					{
						beys.animation.addByPrefix('attack'+i, 'attack'+i,24,false);
					}
				beys.animation.addByNames('finalclashin', ['attack00000', 'attack00001'], 24, false);
				beys.animation.addByNames('finalclashloop', ['attack00002', 'attack00003','attack00004','attack00003'], 24, true);
				beys.animation.play('idle');
		
		
				beysglow = new FlxSprite(83.5, 440.5);
				beysglow.frames =  Paths.getSparrowAtlas('alertshit',"platform");
				beysglow.animation.addByPrefix('glow', 'glow',24,true);
				beysglow.alpha=0;
				beysglow.animation.play('glow');
		
				beysAlert = new FlxSprite(83.5, 440.5);
				beysAlert.frames =  Paths.getSparrowAtlas('alertshit',"platform");
				beysAlert.animation.addByPrefix('alert', 'alert',24,true);
				beysAlert.alpha=0;
				beysAlert.animation.play('alert');
		
		
				add(farbg);
				
				boltsGroup2= new FlxTypedGroup<FlxSprite>();
				add(boltsGroup2);
				for (i in 0...5)
					{
						var farbolts:FlxSprite = new FlxSprite((i*325), 100);
						farbolts.frames =  Paths.getSparrowAtlas('lightingtwo',"platform");
						farbolts.animation.addByPrefix('0', 'bglight0',24,false);
						farbolts.animation.addByPrefix('1', 'bglight1',24,false);
						farbolts.animation.addByPrefix('2', 'bglight2',24,false);
						farbolts.animation.addByPrefix('3', 'bglight3',24,false);
						farbolts.animation.addByPrefix('4', 'bglight4',24,false);
						farbolts.alpha=0;
						boltsGroup2.add(farbolts);
					} 
				  
		
				add(cloud2);
				add(city2);
				add(city1);

			    spacebar.frames =  Paths.getSparrowAtlas('Extras',"platform");
				spacebar.animation.addByPrefix('press', 'Spacebar',20,false);
				spacebar.animation.addByPrefix('pressLoop', 'Spacebar',24,true);
				spacebar.alpha=0;
			
				boltsGroup= new FlxTypedGroup<FlxSprite>();
				add(boltsGroup);
				for (i in 0...4)
					{
						var bolts:FlxSprite = new FlxSprite(i*325, -200);
						bolts.frames =  Paths.getSparrowAtlas('lighting',"platform");
						bolts.animation.addByPrefix('0', 'light0',24,false);
						bolts.animation.addByPrefix('1', 'light1',24,false);
						bolts.animation.addByPrefix('2', 'light2',24,false);
						bolts.alpha=0;
						boltsGroup.add(bolts);
					} 
				  //layering
				  add(bayplace);
				  add(beys);
				  add(beysglow);
				  add(beysAlert);
				  add(stand);
				  add(bfplatform);
				  add(cloud1);
				 
				  add(dadGroup);
				  add(boyfriendGroup);
			  
				  add(bfbars);
				  add(overlay);


				  parrry.frames = Paths.getSparrowAtlas('parrry',"platform");
				  parrry.animation.addByPrefix('parryanim', 'parryanim', 23, false); //yes, the 23 is intentional
				  parrry.alpha=0;
				  parrry.scrollFactor.set();

				  parrry.antialiasing = ClientPrefs.globalAntialiasing;
				  spacebar.antialiasing = ClientPrefs.globalAntialiasing;

				  add(parrry);
				  add(spacebar);
				
				
				var rain:FlxSprite= new FlxSprite(-200,-100);
				rain.frames =  Paths.getSparrowAtlas('GroundbreakingCalled',"platform");
				rain.animation.addByPrefix('rains', 'Rain',24,true);
				rain.animation.play('rains');
				rain.scale.set(2,2);
				add(rain);


		
				
				
		
		
				#if LUA_ALLOWED
				luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
				luaDebugGroup.cameras = [camOther];
				add(luaDebugGroup);
				#end
		
		
		
				// "GLOBAL" SCRIPTS
				#if LUA_ALLOWED
				var filesPushed:Array<String> = [];
				var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];
		
				#if MODS_ALLOWED
				foldersToCheck.insert(0, Paths.mods('scripts/'));
				if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
					foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
				#end
		
				for (folder in foldersToCheck)
				{
					if(FileSystem.exists(folder))
					{
						for (file in FileSystem.readDirectory(folder))
						{
							if(file.endsWith('.lua') && !filesPushed.contains(file))
							{
								luaArray.push(new FunkinLua(folder + file));
								filesPushed.push(file);
							}
						}
					}
				}
				#end
				
		
				// STAGE SCRIPTS
				#if (MODS_ALLOWED && LUA_ALLOWED)
				var doPush:Bool = false;
				var luaFile:String = 'stages/' + curStage + '.lua';
				if(FileSystem.exists(Paths.modFolders(luaFile))) {
					luaFile = Paths.modFolders(luaFile);
					doPush = true;
				} else {
					luaFile = Paths.getPreloadPath(luaFile);
					if(FileSystem.exists(luaFile)) {
						doPush = true;
					}
				}
		
				if(doPush) 
					luaArray.push(new FunkinLua(luaFile));
				#end
		
			
			
		
		
				
		
		
		
		
				boyfriend = new Boyfriend(0, 0, SONG.player1);
				startCharacterPos(boyfriend);
				boyfriendGroup.add(boyfriend);
				startCharacterLua(boyfriend.curCharacter);
				dad = new Character(0, 0, SONG.player2);
				startCharacterPos(dad);
				dadGroup.add(dad);
				startCharacterLua(dad.curCharacter);
		
			
				
				
		
		
				var camPos:FlxPoint = new FlxPoint(baseX,baseY);
			
				
		
				var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
				if (OpenFlAssets.exists(file)) {
					dialogueJson = DialogueBoxPsych.parseDialogue(file);
				}
		
				var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
				if (OpenFlAssets.exists(file)) {
					dialogue = CoolUtil.coolTextFile(file);
				}
				var doof:DialogueBox = new DialogueBox(false, dialogue);
				// doof.x += 70;
				// doof.y = FlxG.height * 0.5;
				doof.scrollFactor.set();
				doof.finishThing = startCountdown;
				doof.nextDialogueThing = startNextDialogue;
				doof.skipDialogueThing = skipDialogue;
		
				Conductor.songPosition = -5000;
				strumLine = new FlxSprite(STRUM_X, 50).makeGraphic(FlxG.width, 10);
				if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
				
				strumLine.scrollFactor.set();
		
				var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
				timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
				timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				timeTxt.scrollFactor.set();
				timeTxt.alpha = 0;
				timeTxt.borderSize = 2;
				timeTxt.visible = showTime;
			
				timeTxt.x=218;
				timeTxt.y=(ClientPrefs.downScroll?20:677);
				
				if(ClientPrefs.timeBarType == 'Song Name')
				{
					timeTxt.text = SONG.song;
				}
				updateTime = showTime;
		
				timeBarBG = new AttachedSprite('timeBar');
				timeBarBG.x = timeTxt.x;
				timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
				timeBarBG.scrollFactor.set();
				timeBarBG.alpha = 0;
				timeBarBG.visible = showTime;
				timeBarBG.color = FlxColor.BLACK;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				add(timeBarBG);
		
		
			
		
				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
					'songPercent', 0, 1);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(0xFF000000, FlxColor.fromRGB(TIME_R,TIME_G,TIME_B));
				timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				add(timeBar);
				add(timeTxt);
				timeBarBG.sprTracker = timeBar;
		
				strumLineNotes = new FlxTypedGroup<StrumNote>();
				add(strumLineNotes);
				add(grpNoteSplashes);
		
				if(ClientPrefs.timeBarType == 'Song Name')
				{
					timeTxt.size = 24;
					timeTxt.y += 3;
				}
		
				var splash:NoteSplash = new NoteSplash(100, 100, 0);
				grpNoteSplashes.add(splash);
				splash.alpha = 0.0;
		
				opponentStrums = new FlxTypedGroup<StrumNote>();
				playerStrums = new FlxTypedGroup<StrumNote>();
		
				// startCountdown();
		
				generateSong(SONG.song);
				#if LUA_ALLOWED
				for (notetype in noteTypeMap.keys())
				{
					var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
					if(FileSystem.exists(luaToLoad))
					{
						luaArray.push(new FunkinLua(luaToLoad));
					}
					else
					{
						luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
						if(FileSystem.exists(luaToLoad))
						{
							luaArray.push(new FunkinLua(luaToLoad));
						}
					}
				}
				for (event in eventPushedMap.keys())
				{
					var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
					if(FileSystem.exists(luaToLoad))
					{
						luaArray.push(new FunkinLua(luaToLoad));
					}
					else
					{
						luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
						if(FileSystem.exists(luaToLoad))
						{
							luaArray.push(new FunkinLua(luaToLoad));
						}
					}
				}
				#end
				noteTypeMap.clear();
				noteTypeMap = null;
				eventPushedMap.clear();
				eventPushedMap = null;
		
				// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
				// add(strumLine);
		
				camFollow = new FlxPoint();
				camFollowPos = new FlxObject(0, 0, 1, 1);
		
				snapCamFollowToPos(camPos.x, camPos.y);
				if (prevCamFollow != null)
				{
					camFollow = prevCamFollow;
					prevCamFollow = null;
				}
				if (prevCamFollowPos != null)
				{
					camFollowPos = prevCamFollowPos;
					prevCamFollowPos = null;
				}
				add(camFollowPos);
		
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
				FlxG.camera.zoom = defaultCamZoom;
				FlxG.camera.focusOn(camFollow);
		
				FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
				FlxG.fixedTimestep = false;
				moveCameraSection(0);
		
		
		
		
		
				healthBarBG = new AttachedSprite('healthBar');
				healthBarBG.y = FlxG.height * 0.89;
				healthBarBG.scrollFactor.set();
				healthBarBG.visible = !ClientPrefs.hideHud;
				healthBarBG.xAdd = -4;
				healthBarBG.yAdd = -4;
				healthBarBG.x=50;healthBarBG.y=50;
				add(healthBarBG);
				if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;
		
				healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, BOTTOM_TO_TOP, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
					'health', 0, 2);
				healthBar.scrollFactor.set();
				
				healthBar.visible = !ClientPrefs.hideHud;
				healthBar.alpha = ClientPrefs.healthBarAlpha;
				add(healthBar);
				healthBarBG.sprTracker = healthBar;
		
				iconP1 = new HealthIcon(boyfriend.healthIcon, true);
				iconP1.y = healthBar.y - 75;
				iconP1.visible = !ClientPrefs.hideHud;
				iconP1.alpha = ClientPrefs.healthBarAlpha;
				add(iconP1);
		
				iconP2 = new HealthIcon(dad.healthIcon, false);
				iconP2.y = healthBar.y - 75;
				iconP2.visible = !ClientPrefs.hideHud;
				iconP2.alpha = ClientPrefs.healthBarAlpha;
				add(iconP2);
				reloadHealthBarColors();
		
				scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				scoreTxt.scrollFactor.set();
				scoreTxt.borderSize = 1.25;
				scoreTxt.visible = !ClientPrefs.hideHud;
				add(scoreTxt);
		
				scoreTxt.x=-100;
				scoreTxt.y=(ClientPrefs.downScroll?FlxG.height-30:7);
		
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled;
				add(botplayTxt);
				if(ClientPrefs.downScroll) {
					botplayTxt.y = timeBarBG.y - 78;
				}
		
		
		
				strumLineNotes.cameras = [camHUD];
				grpNoteSplashes.cameras = [camHUD];
				notes.cameras = [camHUD];
				healthBar.cameras = [camHUD];
				healthBarBG.cameras = [camHUD];
				iconP1.cameras = [camHUD];
				iconP2.cameras = [camHUD];
				scoreTxt.cameras = [camHUD];
				botplayTxt.cameras = [camHUD];
				timeBar.cameras = [camHUD];
				timeBarBG.cameras = [camHUD];
				timeTxt.cameras = [camHUD];
				doof.cameras = [camHUD];
		
				iconP1.x=iconP2.x=healthBar.x-68;
		
			/*	hitwindowTest = new FlxSprite();
				hitwindowTest.makeGraphic(300,300, FlxColor.CYAN);
				hitwindowTest.cameras = [camHUD];
				hitwindowTest.alpha=0;
				hitwindowTest.setPosition(0,0);
				hitwindowTest.scrollFactor.set();

				add(hitwindowTest);

		
		
		
				hitcounterText = new FlxText();
				hitcounterText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				hitcounterText.scrollFactor.set();
				hitcounterText.setPosition(100,100);
				hitcounterText.borderSize = 2;
				hitcounterText.text="space hit :"+pressedSpaceCounter+" times";
				hitcounterText.cameras = [camHUD];

				add(hitcounterText);*/

		
		

		
		
				startingSong = true;
		
		
				// SONG SPECIFIC SCRIPTS
				#if LUA_ALLOWED
				var filesPushed:Array<String> = [];
				var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];
		
				#if MODS_ALLOWED
				foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
				if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
					foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
				#end
		
				for (folder in foldersToCheck)
				{
					if(FileSystem.exists(folder))
					{
						for (file in FileSystem.readDirectory(folder))
						{
							if(file.endsWith('.lua') && !filesPushed.contains(file))
							{
								luaArray.push(new FunkinLua(folder + file));
								filesPushed.push(file);
							}
						}
					}
				}
				#end
				//camHUD.alpha=0;
		
				var daSong:String = Paths.formatToSongPath(curSong);
				if (isStoryMode && !seenCutscene)
				{
					switch (daSong)
					{
						
						default:
							startCountdown();
					}
					seenCutscene = true;
				} else {
					startCountdown();
				}
				RecalculateRating();
		
				//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
				CoolUtil.precacheSound('missnote1');
				CoolUtil.precacheSound('missnote2');
				CoolUtil.precacheSound('missnote3');
		
				#if desktop
				// Updating Discord Rich Presence.
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
		
				if(!ClientPrefs.controllerMode)
				{
					FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
					FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
				}
		
				Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
				callOnLuas('onCreatePost', []);
			
			if(Storage.startingTime!=0)
				setStatsToStorage();
				
				
				
		
				FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				
		
		
				super.create();
			}

	
	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	function startCharacterPos(char:Character) {
		
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				if(endingSong) {
					endSong();
				} else {
					startCountdown();
				}
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end
		if(endingSong) {
			endSong();
		} else {
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			if(endingSong) {
				doof.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				doof.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
		{
			if(startedCountdown) {
				callOnLuas('onStartCountdown', []);
				return;
			}
	
			inCutscene = false;
			var ret:Dynamic = callOnLuas('onStartCountdown', []);
			if(ret != FunkinLua.Function_Stop) {
				if (Storage.startingTime > 0) skipArrowStartTween = true;
	
				generateStaticArrows(0);
				generateStaticArrows(1);
				for (i in 0...playerStrums.length) {
					setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
					setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
				}
				for (i in 0...opponentStrums.length) {
					setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
					setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
					//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
				}
	
				startedCountdown = true;
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crochet * 5;
				setOnLuas('startedCountdown', true);
				callOnLuas('onCountdownStarted', []);
	
				var swagCounter:Int = 0;
			
			
				if ( Storage.startingTime != 0) {
					clearNotesBefore(Storage.startingTime);
					setSongTime(Storage.startingTime - 500);
					return;
				}
	
	
	
	
	
				startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
				{
				
					if(tmr.loopsLeft % 2 == 0) {
						if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
						{
							boyfriend.dance();
						}
						if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
						{
							dad.dance();
						}
					}
					else if(dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.animation.curAnim.name.startsWith("sing"))
					{
						dad.dance();
					}
	
					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					introAssets.set('default', ['ready', 'set', 'go']);
					introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
	
					var introAlts:Array<String> = introAssets.get('default');
					var antialias:Bool = ClientPrefs.globalAntialiasing;
					if(isPixelStage) {
						introAlts = introAssets.get('pixel');
						antialias = false;
					}
	
					
	
					switch (swagCounter)
					{
						case 0:
							FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						case 1:
							countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
							countdownReady.scrollFactor.set();
							countdownReady.updateHitbox();
	
							if (PlayState.isPixelStage)
								countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));
	
							countdownReady.screenCenter();
							countdownReady.antialiasing = antialias;
							add(countdownReady);
							FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownReady);
									countdownReady.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						case 2:
							countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
							countdownSet.scrollFactor.set();
	
							if (PlayState.isPixelStage)
								countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));
	
							countdownSet.screenCenter();
							countdownSet.antialiasing = antialias;
							add(countdownSet);
							FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownSet);
									countdownSet.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						case 3:
							countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
							countdownGo.scrollFactor.set();
	
							if (PlayState.isPixelStage)
								countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));
	
							countdownGo.updateHitbox();
	
							countdownGo.screenCenter();
							countdownGo.antialiasing = antialias;
							add(countdownGo);
							FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownGo);
									countdownGo.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						case 4:
					}
	
					notes.forEachAlive(function(note:Note) {
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.5;
						}
					});
					callOnLuas('onCountdownTick', [swagCounter]);
	
					swagCounter += 1;
					// generateSong('fresh');
				}, 5);
			}
		}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
		{
			startingSong = false;
	
			previousFrameTime = FlxG.game.ticks;
			lastReportedPlayheadPosition = 0;
	
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
			FlxG.sound.music.onComplete = finishSong;
			vocals.play();
	

	
	
	
		

	
			if(paused) {
				//trace('Oopsie doopsie! Paused sound');
				FlxG.sound.music.pause();
				vocals.pause();
			}
	
			// Song duration in a float, useful for the time left feature
			songLength = FlxG.sound.music.length;
		
			
			if ( Storage.startingTime != 0) {
				clearNotesBefore(Storage.startingTime);
				setSongTime(Storage.startingTime - 500);
				return;
			}

			setOnLuas('songLength', songLength);
			callOnLuas('onSongStart', []);
		}
	public function clearNotesBefore(time:Float)
		{
			var i:Int = unspawnNotes.length - 1;
			while (i >= 0) {
				var daNote:Note = unspawnNotes[i];
				if(daNote.strumTime - 500 < time)
				{
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;
	
					daNote.kill();
					unspawnNotes.remove(daNote);
					daNote.destroy();
				}
				--i;
			}
	
			i = notes.length - 1;
			while (i >= 0) {
				var daNote:Note = notes.members[i];
				if(daNote.strumTime - 500 < time)
				{
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;
	
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				--i;
			}
		}
	
		public function setSongTime(time:Float)
		{
			if(time < 0) time = 0;
	
			FlxG.sound.music.pause();
			vocals.pause();
	
			FlxG.sound.music.time = time;
			FlxG.sound.music.play();
	
			vocals.time = time;
			vocals.play();
			Conductor.songPosition = time;
		}


        var first:Int=300000;//300000
		var second:Int=600000;///600000
		var last:Int=900000;///900000
		var finale:Int=1200000;

		public var curSave =0;

		var savedFirst=false;
		var savedSecond=false;
		var savedThird=false;
		var savedFinale=false;



		public function setStatsToStorage()
			{
	
				songScore =Storage.songScore[curSave];
				songMisses =Storage.songMisses[curSave];
				ratingName =Storage.ratingName[curSave];
				ratingPercent =Storage.ratingPercent[curSave];
				parryMiss =Storage.parryMiss[curSave];
	
			}
   

      

		public function resetStats()
			{
				Storage.startingTime=0;
				Storage.songScore = [0,0,0];
				Storage.songMisses = [0,0,0];
				Storage.ratingName =["?","?","?"];
				Storage.ratingPercent= [0.0,0.0,0.0];
				Storage.parryMiss = [0,0,0];
				curSave=0;
				savedFirst=false;
				savedSecond=false;
			    savedThird=false;
				savedFinale=false;
			
			}
		

		function saveOnes(n:Bool=false)
			{
				if(!n)
					{
						Storage.songScore[curSave]= songScore;
						Storage.songMisses[curSave]=songMisses;
						Storage.ratingName[curSave]=ratingName;
						Storage.ratingPercent[curSave]=ratingPercent;
						Storage.parryMiss[curSave]=parryMiss;
						curSave++; 
						n=true;
					}
			}	
	

		function checkPointCheck()
			{
					
				if(first<FlxG.sound.music.time&&FlxG.sound.music.time<second)
					{
						Storage.startingTime=first;
						saveOnes(savedFirst);
					}
				if(second<FlxG.sound.music.time&&FlxG.sound.music.time<last)
					{
						Storage.startingTime=second;
						saveOnes(savedSecond);
					}

				if(last<FlxG.sound.music.time&&FlxG.sound.music.time<finale)
					{
						Storage.startingTime=last;
						saveOnes(savedThird);
					}
				if(finale<FlxG.sound.music.time)
						{
							Storage.startingTime=finale;
							saveOnes(savedFinale);
						}	
			
			
			
			}
		
	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1)
							{ //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[1]) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event[2].toLowerCase()) {
				
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event[2]);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[3];
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event[1])) {
			eventPushedMap.set(event[1], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[1]]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event[1]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
		{
			for (i in 0...4)
			{
				// FlxG.log.add(i);
				var targetAlpha:Float = 1;
				if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;
	
				var babyArrow:StrumNote = new StrumNote(STRUM_X, strumLine.y, i, player);
				if (!isStoryMode  && !skipArrowStartTween)
				{
					babyArrow.y -= 10;
					babyArrow.alpha = 0;
					FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				}
				else
				{
					babyArrow.alpha = targetAlpha;
				}
	
				if (player == 1)
				{
					playerStrums.add(babyArrow);
				}
				else
				{
					if(ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;
						if(i > 1) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}
					opponentStrums.add(babyArrow);
				}
	
				strumLineNotes.add(babyArrow);
				babyArrow.postAddedToGroup();
			}
		}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}


			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;
		
		
	


		

		

			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;





			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
 
    var doDamage=false;
    var pressedSpaceCounter=0;


	var showDownShit=false;
function notHittingEffect()
	{
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		health -=0.333;
		parryMiss++;
		boyfriend.playAnim(missAnims[ FlxG.random.int(0,3)]);
		doDamage=false;
		pressedSpaceCounter=0;
	}

public var tolerance:Int = 10;

function hittingSpaceSHit()
	{
	
		if(pressedSpaceCounter==0&&FlxG.keys.anyPressed([SPACE])){
			parrry.animation.stop();
			pressedSpaceCounter++;
			FlxTween.tween(parrry, {alpha: 0}, 0.5);
		trace('Pressed Space!');
		}
		if(pressedSpaceCounter==0){
			trace("No spaces! or Too many spaces! Ya fucked it up!");
			doDamage=true;
			FlxTween.tween(parrry, {alpha: 0}, 3);}
		else if(pressedSpaceCounter>tolerance){doDamage=true;}
	}

    var missAnims:Array<String>=["singUPmiss","singDOWNmiss","singRIGHTmiss","singLEFTmiss"];
  
	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
    var timerShit=false;



	override public function update(elapsed:Float)
		{
		    
			//hitcounterText.text="space hit :"+pressedSpaceCounter+" times";

			
			if(!boyfriend.animation.curAnim.name.startsWith("sing")&&!moveCam)
				{camFollow.x = (baseX+musthitaddX);camFollow.y =(baseY+musthitaddY);}
		

		
			 switch beys.animation.curAnim.name
			 {
				case "idle":timerShit=false;
				default :
                if(!timerShit)
					{
						new FlxTimer().start(timeClash, function(tmr:FlxTimer)
							{								
								showDownShit=true;
						
								new FlxTimer().start(hitwindow, function(tmr:FlxTimer)
									{								
										showDownShit=false;
										if(pressedSpaceCounter==0&&doDamage || pressedSpaceCounter>tolerance&&doDamage) 
											{
												//trace('YOU DIDNT HIT SPACE');
												notHittingEffect();
											
											}
										else {pressedSpaceCounter = 0;}
										resyncVocals();
									});	
						
						
						
							});	
							timerShit=true;
					}
			 }



			if(showDownShit)
				hittingSpaceSHit();

		


				checkPointCheck();
	
				
			
	
	
			
	
			callOnLuas('onUpdate', [elapsed]);
	
		
			if(!inCutscene) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
				if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
					boyfriendIdleTime += elapsed;
					if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriendIdled = true;
					}
				} else {
					boyfriendIdleTime = 0;
				}
			}
	
			super.update(elapsed);
	
			if(ratingName == '?') {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Missed Parries: ' + parryMiss + ' | Rating: ' + ratingName;
			} else {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Missed Parries: ' + parryMiss + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
			}
	
			if(botplayTxt.visible) {
				botplaySine += 180 * elapsed;
				botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
			}
	
			if (controls.PAUSE && startedCountdown && canPause)
			{
				var ret:Dynamic = callOnLuas('onPause', []);
				if(ret != FunkinLua.Function_Stop) {
					persistentUpdate = false;
					persistentDraw = true;
					paused = true;
	
				
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
					}
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					//}
			
					#if desktop
					DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
					#end
				}
			}
	
			if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			{
				openChartEditor();
			}
			if (health > 2)
				health = 2;
	
			// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
			// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);
	
			 var mult:Float = FlxMath.lerp(1, iconP1.scale.y, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();
	
			var mult:Float = FlxMath.lerp(1, iconP2.scale.y, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();
	
			var iconOffset:Int = 26;
	
			iconP1.y = ((healthBar.height * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.y - 150) / 2 - iconOffset)+adj;
			iconP2.y = ((healthBar.height * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.y) / 2 - iconOffset-22 * 2)+adj ;
	
		
	
			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else
				iconP1.animation.curAnim.curFrame = 0;
	
			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
	
			if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
				persistentUpdate = false;
				paused = true;
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
			}
	
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += FlxG.elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
	
				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;
	
					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) / 2;
						Conductor.lastSongPos = Conductor.songPosition;
						// Conductor.songPosition += FlxG.elapsed * 1000;
						// trace('MISSED FRAME');
					}
	
					if(updateTime) {
						var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
						if(curTime < 0) curTime = 0;
						songPercent = (curTime / songLength);
	
						var songCalc:Float = (songLength - curTime);
						if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;
	
						var secondsTotal:Int = Math.floor(songCalc / 1000);
						if(secondsTotal < 0) secondsTotal = 0;
	
						if(ClientPrefs.timeBarType != 'Song Name')
							timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
	
				// Conductor.lastSongPos = FlxG.sound.music.time;
			}
	
			if (camZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}
			
			FlxG.watch.addQuick("SongPos", FlxG.sound.music.time);
			FlxG.watch.addQuick("Storage CP", Storage.startingTime);
			
			

			// RESET = Quick Game Over Screen
			if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
			{
				health = 0;
				trace("RESET = True");
			}
			doDeathCheck();
	
			var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);
			if (unspawnNotes[0] != null)
			{
				var time:Float = 1500;
				if(roundedSpeed < 1) time /= roundedSpeed;
	
				while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
				{
					var dunceNote:Note = unspawnNotes[0];
					notes.insert(0, dunceNote);
	
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
				}
			}
	
			if (generatedMusic)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					/*if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}*/
	
					// i am so fucking sorry for this if condition
					var strumX:Float = 0;
					var strumY:Float = 0;
					var strumAngle:Float = 0;
					var strumAlpha:Float = 0;
					if(daNote.mustPress) {
						strumX = playerStrums.members[daNote.noteData].x;
						strumY = playerStrums.members[daNote.noteData].y;
						strumAngle = playerStrums.members[daNote.noteData].angle;
						strumAlpha = playerStrums.members[daNote.noteData].alpha;
					} else {
						strumX = opponentStrums.members[daNote.noteData].x;
						strumY = opponentStrums.members[daNote.noteData].y;
						strumAngle = opponentStrums.members[daNote.noteData].angle;
						strumAlpha = opponentStrums.members[daNote.noteData].alpha;
					}
	
					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;
					var center:Float = strumY + Note.swagWidth / 2;
	
					if(daNote.copyX) {
						daNote.x = strumX;
					}
					if(daNote.copyAngle) {
						daNote.angle = strumAngle;
					}
					if(daNote.copyAlpha) {
						daNote.alpha = strumAlpha;
					}
					if(daNote.copyY) {
						if (ClientPrefs.downScroll) {
							daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
							if (daNote.isSustainNote && !ClientPrefs.keSustains) {
								//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
								if (daNote.animation.curAnim.name.endsWith('end')) {
									daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
									daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
									if(PlayState.isPixelStage) {
										daNote.y += 8;
									} else {
										daNote.y -= 19;
									}
								} 
								daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);
	
								if(daNote.mustPress || !daNote.ignoreNote)
								{
									if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
										&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
									{
										var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
										swagRect.height = (center - daNote.y) / daNote.scale.y;
										swagRect.y = daNote.frameHeight - swagRect.height;
	
										daNote.clipRect = swagRect;
									}
								}
							}
						} else {
							daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
	
							if(!ClientPrefs.keSustains)
							{
								if(daNote.mustPress || !daNote.ignoreNote)
								{
									if (daNote.isSustainNote
										&& daNote.y + daNote.offset.y * daNote.scale.y <= center
										&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
									{
										var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
										swagRect.y = (center - daNote.y) / daNote.scale.y;
										swagRect.height -= swagRect.y;
	
										daNote.clipRect = swagRect;
									}
								}
							}
						}
					}
	
					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}
	
					if(daNote.mustPress && cpuControlled) {
						if(daNote.isSustainNote) {
							if(daNote.canBeHit) {
								goodNoteHit(daNote);
							}
						} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
							goodNoteHit(daNote);
						}
					}
	
					// WIP interpolation shit? Need to fix the pause issue
					// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * songSpeed));
	
					var doKill:Bool = daNote.y < -daNote.height;
					if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;
	
					if(ClientPrefs.keSustains && daNote.isSustainNote && daNote.wasGoodHit) doKill = true;
	
					if (doKill)
					{
						if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			checkEventNote();
	
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
			}
			
			#if debug
			if(!endingSong && !startingSong) {
				if(FlxG.keys.justPressed.THREE) {health+=0.5;}
				if (FlxG.keys.justPressed.ONE) {
					KillNotes();
					FlxG.sound.music.onComplete();
				}
				if(FlxG.keys.justPressed.TWO) { 
					FlxG.sound.music.pause();
					vocals.pause();
					Conductor.songPosition += 10000;
					notes.forEachAlive(function(daNote:Note)
					{
						if(daNote.strumTime + 800 < Conductor.songPosition) {
							daNote.active = false;
							daNote.visible = false;
	
							daNote.kill();
							notes.remove(daNote, true);
							daNote.destroy();
						}
					});
					for (i in 0...unspawnNotes.length) {
						var daNote:Note = unspawnNotes[0];
						if(daNote.strumTime + 800 >= Conductor.songPosition) {
							break;
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
						daNote.destroy();
					}
	
					FlxG.sound.music.time = Conductor.songPosition;
					FlxG.sound.music.play();
	
					vocals.time = Conductor.songPosition;
					vocals.play();
				}
				if(FlxG.keys.justPressed.THREE) { 
					practiceMode = true;
					FlxG.sound.music.pause();
					vocals.pause();
					Conductor.songPosition = (1200000 - 30000);
					notes.forEachAlive(function(daNote:Note)
					{
						if(daNote.strumTime + 800 < Conductor.songPosition) {
							daNote.active = false;
							daNote.visible = false;
	
							daNote.kill();
							notes.remove(daNote, true);
							daNote.destroy();
						}
					});
					for (i in 0...unspawnNotes.length) {
						var daNote:Note = unspawnNotes[0];
						if(daNote.strumTime + 800 >= Conductor.songPosition) {
							break;
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
						daNote.destroy();
					}
	
					FlxG.sound.music.time = Conductor.songPosition;
					FlxG.sound.music.play();
	
					vocals.time = Conductor.songPosition;
					vocals.play();
				}
			}
			#end
	
	
			checkPointCheck();
	
			
			setOnLuas('cameraX', camFollowPos.x);
			setOnLuas('cameraY', camFollowPos.y);
			setOnLuas('botPlay', cpuControlled);
			callOnLuas('onUpdatePost', [elapsed]);
		}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		CustomFadeTransition.nextCamera = camOther;
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0 ) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;
				

				paused = true;
				
				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				
				
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][2] != null)
				value1 = eventNotes[0][2];

			var value2:String = '';
			if(eventNotes[0][3] != null)
				value2 = eventNotes[0][3];

			triggerEventNote(eventNotes[0][1], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}
	
   var light:Int=0;
   var lightanim:Int=0;
   var lightfar:Int=0;
   var lightanimfar:Int=0;
   var moveCam:Bool=false;
   var switch1andtwo = false;

   public function triggerEventNote(eventName:String, value1:String, value2:String) {
	switch(eventName) {
		case 'DramaticCamera':
			FlxTween.tween(FlxG.camera, {zoom: 3}, 10);
			FlxTween.tween(FlxG.camera.target, {x: 700, y: 700}, 10, {
							onComplete: function(twn:FlxTween)
							{
								isCameraOnForcedPos = true;
								camFollow.x = FlxG.camera.target.x;
								camFollow.y = FlxG.camera.target.y;
								camZooming = false;
								defaultCamZoom = 3; // safety net
							}
						});
// turns out target is a direct link/combination to camFollow and camFollowPos, and it's own seperate property to tween
FlxTween.tween(camFollow, {x: 700, y: 700}, 10);
			//Kevin Kuntz to the rescue. Thanks dude!

		case 'EndFinalClash':
			overlay.blend = NORMAL;
			finalshowdown = false;
			overlay.animation.play('white');
			FlxTween.tween(overlay, { alpha: 1}, 0.5);

		case 'FinalClash':
			switch1andtwo = true;
			for (i in 0...playerStrums.length) {
				FlxTween.tween(playerStrums.members[i], {alpha: 0}, 0.1);
			}
			spacebar.animation.play('pressLoop');
			FlxTween.tween(spacebar,{alpha: 1}, 0.25);
			FlxTween.tween(beysglow, {alpha: 1}, 0.8,{onComplete: function(twn:FlxTween)
				{
					FlxTween.tween(beysglow, {alpha: 0}, 0.000001); ////oh my fucking GOD
					new FlxTimer().start(timeClash, function(tmr:FlxTimer){camGame.shake(0.0093, 0.1);});
					beys.animation.play('finalclashin',true);
					beys.animation.finishCallback = function(fuck:String)
						{
							FlxTween.tween(spacebar,{alpha: 0}, 0.25);
							finalshowdown = true;	
							beys.animation.play('finalclashloop',true);
						}  
				
				}});
		case 'Dragons':
			var dragons:FlxSprite = new FlxSprite(310, 50);
				dragons.frames = Paths.getSparrowAtlas('dragons',"platform");
				dragons.animation.addByPrefix('dragons', 'dragons', 24, false);
			dragons.animation.play('dragons');
			add(dragons);
			FlxTween.tween(dragons, { alpha: 0}, 5, {ease: FlxEase.expoIn});

		case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);
				}
				reloadHealthBarColors();
	 
			case 'Play Animation':
					var char:Character = dad;
					if(switch1andtwo){
						var temp:String;
						temp = value1;
						value1 = value2;   //This is here because right at the end of the chart I fucked up the playanims for Ryuga and BF
						value2 = temp;     //And didnt feel like placing them all down again
					}
					switch(value2.toLowerCase().trim()) {
						case 'bf' | 'boyfriend':
							char = boyfriend;
						default:
							var val2:Int = Std.parseInt(value2);
							if(Math.isNaN(val2)) val2 = 0;
			
							switch(val2) {
								case 1: char = boyfriend;
								case 2: char = dad;
							}
					}
	
					if (char != null)
					{
						char.playAnim(value1, true);
						char.specialAnim = true;
					}

		case "MoveCamtoDad":
			moveCam=!moveCam;
				
			moveCamera(moveCam);

	
	
	
		case "tweenINHud":
			FlxTween.tween(camHUD, { alpha: 1}, 0.5);

		case "tweenOUTHud":
			FlxTween.tween(camHUD, { alpha: 0}, 0.5);

		case 'lightShow':
			if(ClientPrefs.lowQuality){return;}
			thunderSound();
			camGame.shake(0.0095, 0.1);
			camHUD.shake(0.0095, 0.1);
			overlay.alpha=0.38;
			overlay.animation.play("flash");
			if (value1 == " "){value1 = "";} //cuz i keep making these with whitespaces
			if (value1 =="") 
				{
					light = FlxG.random.int(0,3);
					lightanim =FlxG.random.int(0,2);
					boltsGroup.members[light].alpha=1;
					boltsGroup.members[light].animation.play(Std.string(lightanim));
				}
			else
				{
					boltsGroup.members[Std.parseInt(value1)].alpha=1;
					boltsGroup.members[Std.parseInt(value1)].animation.play(value2);
				}

		case 'lightShowFar':
			if(ClientPrefs.lowQuality){return;}
			thunderSound();
			camGame.shake(0.0075, 0.1);
			camHUD.shake(0.0075, 0.1);
			overlay.alpha=0.2;
			overlay.animation.play("flash");
			if (value1 == " "){value1 = "";}
			if (value1 =="") 
				{
					lightfar = FlxG.random.int(0,4);
					lightanimfar =FlxG.random.int(0,4);
					boltsGroup2.members[lightfar].alpha=1;
					boltsGroup2.members[lightfar].animation.play(Std.string(lightanimfar));
				}
			else
				{
					boltsGroup2.members[Std.parseInt(value1)].alpha=1;
					boltsGroup2.members[Std.parseInt(value1)].animation.play(value2);
				}
		case "beyShowDown":
				FlxTween.tween(beysglow, {alpha: 1}, 0.8,{onComplete: function(twn:FlxTween)
					{
					
						FlxTween.tween(beysglow, {alpha: 0}, 0.000001); ////oh my fucking GOD
						new FlxTimer().start(timeClash, function(tmr:FlxTimer){camGame.shake(0.0093, 0.1);});
					
						beys.animation.play('attack'+FlxG.random.int(0,3),true);
					
						beys.animation.finishCallback = function(fuck:String)
							{			
								beys.animation.play('idle',true);
								beysglow.animation.play('glow',true);//sync
							}  
					
				
					}});
				case 'Camera Follow Pos':
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;
	
					isCameraOnForcedPos = false;
					if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
					{
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
		
	}
	callOnLuas('onEvent', [eventName, value1, value2]);
}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;
		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		
			camFollow.set(baseX,baseY);
		
		else
			camFollow.set(baseX+musthitaddX,baseY+musthitaddY);
		

		
		
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					
					
					health -= 0.05 * healthLoss;
		            
						
					
		
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
				
						health -= 0.05 * healthLoss;
				
	
					
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

	

		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('MENU'));

					cancelMusicFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new MainMenuState());

	
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new MainMenuState());
				FlxG.sound.playMusic(Paths.music('MENU'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}


		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];


		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});
			
			if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;
		
			health -= daNote.missHealth * healthLoss;
		
		
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		

		if(char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			
			health -= 0.05 * healthLoss;
			
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));


			if(boyfriend.hasMissAnimations) 
					boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
				
			
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

        if(health>0.02)
			health-=0.02;



		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			
			
				char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
		{
			if (!note.wasGoodHit)
			{
				if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;
	
				if(note.hitCausesMiss) {
					noteMiss(note);
					if(!note.noteSplashDisabled && !note.isSustainNote) {
						spawnNoteSplashOnNote(note);
					}
	
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
					
					note.wasGoodHit = true;
					if (!note.isSustainNote)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					return;
				}
	
				if (!note.isSustainNote)
				{
					combo += 1;
					popUpScore(note);
					if(combo > 9999) combo = 9999;
				}
				
				health += note.hitHealth * healthGain;
	
				if(!note.noAnimation) {
					var daAlt = '';
					if(note.noteType == 'Alt Animation') daAlt = '-alt';
		
					var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];
					
					switch animToPlay
					{
					  case 'singLEFT': camFollow.x = (baseX+musthitaddX)-camChange;camFollow.y =(baseY+musthitaddY);
					  case 'singRIGHT':camFollow.x =(baseX+musthitaddX)+camChange;camFollow.y =	(baseY+musthitaddY);
					  case 'singUP':camFollow.y =(baseY+musthitaddY)-camChange;camFollow.x = (baseX+musthitaddX);
					  case 'singDOWN': camFollow.y = (baseY+musthitaddY)+camChange;camFollow.x = (baseX+musthitaddX);
					}
				
				
	
	
	
	
					boyfriend.playAnim(animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				
					if(note.noteType == 'Hey!') {
						if(boyfriend.animOffsets.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = 0.6;
						}
		
					
	
	
	
					
					}
				}
	
				if(cpuControlled) {
					var time:Float = 0.15;
					if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}
					StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
				} else {
					playerStrums.forEach(function(spr:StrumNote)
					{
						if (Math.abs(note.noteData) == spr.ID)
						{
							spr.playAnim('confirm', true);
						}
					});
				}
				note.wasGoodHit = true;
				vocals.volume = 1;
	
				var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
				var leData:Int = Math.round(Math.abs(note.noteData));
				var leType:String = note.noteType;
				callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
	
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
			}
		}
	

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}


	
	




	


	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;

	var parryEvents:Array<Int> = [352, 740, 1016, 1264, 1864, 2064, 2384, 2640, 3160, 3408, 3696, 3760, 3824, 3888, 4076, 4592, 4960, 5152, 5505, 5632, 6192, 6304, 6684, 6944, 7136, 7648, 7968, 8352, 8608, 9008, 9344, 9408, 9472, 9648, 9984, 10368, 10688, 10816, 10960, 11568, 11984, 12256, 12528, 12880, 13008, 13744, 14128, 14408, 14792, 15040, 15328, 99999];


	override function stepHit()
		{
			super.stepHit();
			if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
	
			if(curStep == lastStepHit) {
				return;
			}
		



			for (item in parryEvents)
				{
					if(curStep == 352-16){
						FlxTween.tween(spacebar, {alpha: 1}, 0.25);
						spacebar.animation.play('press');
						spacebar.animation.finishCallback = function(fuck:String)
							{		
								FlxTween.tween(spacebar, {alpha: 0}, 0.25);
							} 
					}
					if(curStep == item - 32){
						FlxTween.tween(parrry, {alpha: 1}, 0.25);
						parrry.animation.play('parryanim', true, false, 0);}
					if(curStep == item- 11) 
						triggerEventNote("beyShowDown","","");
			
					
				}
         

	
			lastStepHit = curStep;
			setOnLuas('curStep', curStep);
			callOnLuas('onStepHit', []);

			if(finalshowdown)
				triggerQTE();
		}
	
	public function triggerQTE(){
		if(FlxG.keys.anyPressed([SPACE])){
			health+=0.15;
		}
		else{health-=0.1;}
	}
	
	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

	//	if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && )
	//	{
	//		moveCameraSection(Std.int(curStep / 16));
	//	}
		if (camZooming && FlxG.camera.zoom < 4 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
	
	

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		
		if(curBeat % 2 == 0) {
			
			
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
					dad.dance();
					
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null  && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
			dad.dance();
		}

		
		lastBeatHit = curBeat;

				setOnLuas('curBeat', curBeat);//DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
	
		
	
	
	
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		
		
		
	
		
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	


}
