package;


import openfl.display.Sprite;
import sys.db.Types;

class User extends sys.db.Object {
    public var id : SId;
    public var name : SString<32>;
    public var birthday : SNull<SDate>;
    public var phoneNumber : SNull<SText>;
}

class Kanji extends sys.db.Object
{
	public var id : SId;
	public var literal : SString<1>; 
	//public var ja_on : SNull<SData<List<String>>>; // all the SData doesn't allow search
	//public var ja_kun : SNull<SData<List<String>>>;
	//public var trad_en : SData<List<String>>;
	//public var trad_fr : SNull<SData<List<String>>>;
	/*@relation(onid) var ja_on : Reading;
	@relation(kunid) var ja_kun : Reading;
	@relation(enid) var trad_en : Reading;
	@relation(frid) var trad_fr : Reading;*/
	public var jlpt : SNull<SInt>;
	public var strokes : SNull<SInt>;
	public var grade : SNull<SInt>;
}

//@:id(id, kid)
class Reading extends sys.db.Object
{
	public var id : SId;
	public var text : SString<50>;
	@:relation(kid) public var kanji : Kanji;
	public var type : SNull<SString<3>>;
}

class Main extends Sprite {
	
	
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
		con.request("SET NAMES 'utf8mb4';");
		//con.request("create table testapp(v varchar(30));");
		//con.request("insert into testapp values ('desvaleurs putain');");

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

		
		//var u = new User();
		
		//u.name = "tolilo亜";
		
		//u.birthday = Date.now();
		//u.insert();
		var xml:Xml = Xml.parse(sys.io.File.getContent("/home/crimson-hawk/kanjidic2.xml"));
		var i = 0;

		for(e in xml.firstElement().elementsNamed("character"))
		{
			//trace(xml.firstElement().elementsNamed("character").next().firstElement().nodeName);
			//var s = xml.firstElement().elementsNamed("character").next().firstElement().firstChild().nodeValue;
			//trace(s);
			trace(e.elementsNamed("literal").next().firstChild().nodeValue);
			var k = new Kanji();

			k.literal = e.elementsNamed("literal").next().firstChild().nodeValue;
			if(e.elementsNamed("misc").hasNext())
			{
				var misc = e.elementsNamed("misc").next();
				if(misc.elementsNamed("jlpt").hasNext())
				{
					trace(misc.elementsNamed("jlpt").next().firstChild().nodeValue);
					k.jlpt = Std.parseInt(misc.elementsNamed("jlpt").next().firstChild().nodeValue);
				}
				if(misc.elementsNamed("grade").hasNext())
				{
					trace(misc.elementsNamed("grade").next().firstChild().nodeValue);
					k.grade = Std.parseInt(misc.elementsNamed("grade").next().firstChild().nodeValue);
				}
				if(misc.elementsNamed("stroke_count").hasNext())
				{
					trace(misc.elementsNamed("stroke_count").next().firstChild().nodeValue);
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
							trace(line.firstChild().nodeValue);
							var r = new Reading();
							r.text = line.firstChild().nodeValue;
							//r.kanji = k.id;
							r.kanji = k;
							r.type = t.substr(3, 3);
							r.insert();
							//trace(k.ja_on.next());
							//k.ja_on.add(line.firstChild().nodeValue);
						}
						/*else if(line.get("r_type") == "ja_kun")
						{
							trace(line.firstChild().nodeValue);
							k.ja_kun.add(line.firstChild().nodeValue);
						}*/
					}

					var it = rdmean.elementsNamed("meaning");

					while(it.hasNext())
					{
						var line = it.next();
						var t = line.get("m_lang");

						if(t == null || t == "fr")
						{
							trace(line.firstChild().nodeValue);
							//k.trad_en.add(line.firstChild().nodeValue);
							var r = new Reading();
							r.text = line.firstChild().nodeValue;
							//r.kanji = k.id;
							r.kanji = k;
							r.type = if(t==null) "en" else t;
							r.insert();
						}
						/*else if(line.get("m_lang") == "fr")
						{
							trace(line.firstChild().nodeValue);
							//k.trad_fr.add(line.firstChild().nodeValue);
						}*/
					}
				}
			}

			i++;
			if(i > 10)
			{
				break;
			}
		}

		/*for(r in Reading.manager.search($text.like("%a%") && $type=="en"))
		{
			trace(r.kanji.literal);
			trace(r.text);
			trace("Readings :");
			for(r2 in Reading.manager.search($kanji == r.kanji && ($type=="kun" || $type=="on")))
			{
				trace(r2.text);
			}
		}*/

	}
	
	
}