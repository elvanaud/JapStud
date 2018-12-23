package;


import openfl.display.Sprite;
import sys.db.Types;

import noriko.str.JString;
import haxe.Utf8;

import haxe.ui.Toolkit;
import haxe.ui.HaxeUIApp;
import haxe.ui.core.Screen;
import haxe.ui.core.Component;
import haxe.ui.core.*;
import haxe.ui.components.*;
import haxe.ui.macros.ComponentMacros;

using hx.strings.Strings;
import hx.strings.*;

//class Reading;
//record-macros ORM --> see through ufront-orm (maybe it will work on js + it has ManyToMany relations)
//TODO:Make ufront-orm work
class Kanji extends sys.db.Object
{
	public var id : SId;
	public var literal : SString<1>; 
	public var jlpt : SNull<SInt>;
	public var strokes : SNull<SInt>;
	public var grade : SNull<SInt>;

	//not in the sql entity:
	@:skip public var readings : List<Reading>;
	public function load()
	{
		readings = Reading.manager.search($kid == id);
	}
}

class Reading extends sys.db.Object
{
	public var id : SId;
	public var text : SString<100>;
	@:relation(kid) public var kanji : Kanji;
	public var type : SNull<SString<3>>;
}

class Main extends Sprite {
	private var main:Component;

	public function search(e:MouseEvent)
	{
		//todo: more criteria
		var txt = main.findComponent("t1", TextField);
		var lbl = main.findComponent("label1", Label);
		trace(txt.text);
		var k = null;
		var q = txt.text;
		if(isKanji(q))
		{
			k = Kanji.manager.search($literal == q);
		}
		else
		{ //todo search with like
			k = Reading.manager.search($text == q).map(function (r) return r.kanji);

			trace(isRomaji(q));
			if(!isJapanese(q) && isRomaji(q))
			{
				//romajiToKana ne connait pas le tsu (tu), je l'ai donc rajouté dans le code de la library
				var kkana = JString.romajiToKana(q); //ne gère pas les acents: ca le fait planter
				var hkana = toHiragana(kkana); 

				trace(kkana);
				trace(hkana);

				for(r in Reading.manager.search($text == hkana || $text == kkana))
				{
					k.add(r.kanji);
				}
			}
		}

		//Displaying the kanji list:
		for(a in k)
		{
			if(a.jlpt == null)//maybe should place it in the sql request
			{
				//k.remove(a); continue;
			}
			a.load();
			var s = a.literal + " jlpt" + a.jlpt;
			for(r in a.readings)
			{
				s += "\n\t" + r.text;
				lbl.text = a.literal; //r.text;
			}
			trace(s);

		}

		//lbl.text = "シュツhhvh";
	}
	
	public function new () {
		
		super ();
		
		var connData = {
			host: "172.17.0.2",
			port: 3306,
			user: "foo",
			pass: "bar",
			database: "mydb"
		};

		var con = sys.db.Mysql.connect(connData);
		//con.request("SET NAMES 'utf8mb4';");

		sys.db.Manager.cnx = con;
		sys.db.Manager.initialize();

		if ( !sys.db.TableCreate.exists(Kanji.manager) )
		{
 		   sys.db.TableCreate.create(Kanji.manager);
		}
		if ( !sys.db.TableCreate.exists(Reading.manager) )
		{
 		   sys.db.TableCreate.create(Reading.manager);
		}

		//xml2Sql();

		Toolkit.init();
		
		//var app = new HaxeUIApp();
		
		//app.ready(function() {
			main = ComponentMacros.buildComponent("Assets/Xml/UI.xml");
		//	app.addComponent(main);
		//	app.start();
		//});
		var btn = main.findComponent("b1", Button);
		btn.text = "oraaaaaaaaaa";
		btn.registerEvent(MouseEvent.CLICK, search);
		Screen.instance.addComponent(main);
	}


	
	function isKanji(str) 
	{
    	var reg = ~/[\x{4E00}-\x{9FBF}]/u;
    	return reg.match(str);
	}

	function isHiragana(str) {
    	var reg = ~/$[\x{3040}-\x{309F}]*^/u;
    	return reg.match(str);
	}

	function isKatakana(str) {
	    var reg = ~/[\x{30A0}-\x{30FF}]/u; //need to make that work
	    return reg.match(str);
	}

	//could be isASCII
	//returns false with accents
	function isRomaji(str:String8)
	{
		var romaji = true;
	    str.iterate(function(s)
	    {
	    	if(!(s.charCodeAt8(0) == "." || (s.charCodeAt8(0) >= "a".charCodeAt8(0) && s.charCodeAt8(0) <= "z".charCodeAt8(0)) 
	    		|| s.charCodeAt8(0) >= "A".charCodeAt8(0) && s.charCodeAt8(0) <= "Z".charCodeAt8(0)))
	    	{
	    		romaji=false;
	    	}
	    }, "");
	    return romaji;
	}

	function isJapanese(str) {
    	return isKanji(str) || isHiragana(str) || isKatakana(str);
	}

	/*function find(str:String, c:Int):Int
	{
		var i = 0;
		var found = false;
		Utf8.iter(str, function(a)
			{
				if(!found && a!=c)
				{
					i++;
				}
				else
				{
					found = true;
				}
			});
		return i;
	}*/

	function toHiragana(str:String):String
	{
		var hiragana:String = "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをん";
		var katakana:String = "ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶ";

		var hira = hiragana.split8("");
		var kata = katakana.split8("");

		for ( i in 0 ... hira.length ) {
			str = str.split8( kata[i] ).join( hira[i] );
		}

		return str;
		/*
		if(!isJapanese(str)) return "";
		Utf8.iter(str, function(c) 
			{
				var index = find(katakana, c); 
					var h = Utf8.charCodeAt(hiragana, index);
					r.addChar(h);
			});

		return r.toString();*/
	}

	function xml2Sql()
	{
		var xml:Xml = Xml.parse(sys.io.File.getContent("/home/crimson-hawk/kanjidic2.xml"));
		var i = 0;

		for(e in xml.firstElement().elementsNamed("character"))
		{
			/*if(i < 1875)
			{
				i++;
				continue;
			}*/
			trace(e.elementsNamed("literal").next().firstChild().nodeValue);
			var k = new Kanji();

			k.literal = e.elementsNamed("literal").next().firstChild().nodeValue;
			if(e.elementsNamed("misc").hasNext())
			{
				var misc = e.elementsNamed("misc").next();
				if(misc.elementsNamed("jlpt").hasNext())
				{
					//trace(misc.elementsNamed("jlpt").next().firstChild().nodeValue);
					k.jlpt = Std.parseInt(misc.elementsNamed("jlpt").next().firstChild().nodeValue);
				}
				if(misc.elementsNamed("grade").hasNext())
				{
					//trace(misc.elementsNamed("grade").next().firstChild().nodeValue);
					k.grade = Std.parseInt(misc.elementsNamed("grade").next().firstChild().nodeValue);
				}
				if(misc.elementsNamed("stroke_count").hasNext())
				{
					//trace(misc.elementsNamed("stroke_count").next().firstChild().nodeValue);
					k.strokes = Std.parseInt(misc.elementsNamed("stroke_count").next().firstChild().nodeValue);
				}
			}
			k.insert();

			if(e.elementsNamed("reading_meaning").hasNext())
			{
				var rdmeanParent = e.elementsNamed("reading_meaning").next();
				if(rdmeanParent.elementsNamed("rmgroup").hasNext())
				{
					var rdmean = rdmeanParent.elementsNamed("rmgroup").next();
					var it = rdmean.elementsNamed("reading");
					while(it.hasNext())
					{
						var line = it.next();
						var t = line.get("r_type");
						if(t == "ja_on" || t == "ja_kun")
						{
							//trace(line.firstChild().nodeValue);
							var r = new Reading();
							r.text = line.firstChild().nodeValue;
							r.kanji = k;
							r.type = t.substr(3, 3);
							r.insert();
						}
					}

					var it = rdmean.elementsNamed("meaning");

					while(it.hasNext())
					{
						var line = it.next();
						var t = line.get("m_lang");
						//trace("Meaning");

						if(t == null || t == "fr")
						{
							//trace(line.firstChild().nodeValue);
							var r = new Reading();
							r.text = line.firstChild().nodeValue;
							r.kanji = k;
							r.type = if(t==null) "en" else t;
							r.insert();
						}
					}
				}
			}

			i++;
			/*if(i > 10)
			{
				break;
			}*/
		}

		trace(i + " kanjis insérés dans la base de donnée");
	}
}

