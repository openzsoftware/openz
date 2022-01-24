// Starterscript

$(document).ready(function() {
	// erster animationsdurchlauf	
   bc.setup();	
   bc.init();
						   
	// mousehandler color swatches						   
   $("div.csb").click(function() {
		// set color values according to swatch 					   
		document.getElementById('colors').value = $(this).attr('rel');							   
		// set status css class
		$("div.csb").removeClass("active");							   
   		$(this).addClass("active");
		
		//reload
		bc.init();		
   });

   // mh reload für inputfelder
   $("#form1").find("input").blur(function() {
		bc.init();
   });   
});


    
    // Grundvariablen
    var yoffset = 30;
	var xoffset = 20;
	
    
    //Canvas - Balken
    var bc = {
       canvas   : null,  // Canvas Element
       ctx      : null,  // 2D-Grafikkontext vom Canvas
    
       barWidth : 80,        // Breite der Balken
       barFill  : null,      // Farbverlauf für Säulen
       backgroundFill: null, // Farbverlauf für Hintergrund
    
       scale    : 1,         // Skalierungsfaktor während der Animation
       duration : 2,       // Dauer der Animation in Sekunden
       fps      : 25,        // Anzahl der Bilder pro Sekunde
       startTime: 0,         // Startzeitpunkt der Animation
       timer    : null,      // JavaScript Timer
    
	   setup: function () {
		   
		   
	   },
    
      
       init: function() {

			bc.canvas = document.getElementById('canvas1');
			
			bc.canvas.width = document.getElementById('cwidth').value;
			bc.canvas.height = document.getElementById('cheight').value;	
			xoffset = parseInt(document.getElementById('xoffset').value);
			//document.getElementById('xoffset').value = xoffset;
			
	/*	   
		    document.getElementById('besch').width = bc.canvas.width;
			document.getElementById('besch').height = bc.canvas.height;
			document.getElementById('title').width = bc.canvas.width;
			document.getElementById('title').height = bc.canvas.height;
		   */
		   
		   // HTML Reset
		   		document.getElementById('data').innerHTML =""; document.getElementById('titel').innerHTML =""; document.getElementById('besch').innerHTML ="";
		   		$('#canvas1').css({width: bc.canvas.width})
		   
		   // Variablen aus user-input übernehmen
		        values = new Array();
				werty = document.getElementById('werty').value;
				values[1] = werty.split(",");   //			  values[1]   = [83, 79 , 68, 51], // 
				
 	         	besch = new Array();
				wertx = document.getElementById('wertx').value;
				besch = wertx.split(",");   
				
				einh = document.getElementById('einh').value;
				
				fontx = document.getElementById('fontx').value;
				fonty = document.getElementById('fonty').value;
				
				colors = new Array();
				colorstxt = document.getElementById('colors').value;
				colors = colorstxt.split(",");  
				bc.barWidth = (bc.canvas.width - (values[1].length * (xoffset + 2)  )) / values[1].length;



	  // Höchsten Wert bestimmen   	   
	          vmax = 0 ;		// zur Anpassung der values an die Canvashöhe
              for(var i = 0; i <= values[1].length; i++) {
                  if (parseInt(values[1][i]) > parseInt(vmax)) { 
                      vmax = values[1][i];
                  }
              }

		   
		   
           if(bc.canvas && bc.canvas.getContext) {
               bc.ctx = bc.canvas.getContext('2d');
               //bc.barFill = bc.ctx.fillStyle = colors[i];
                
               // Farbverläufe
              /* bc.barFill = bc.ctx.createLinearGradient( 100, 0, 0, 120);
               bc.barFill.addColorStop(0.7, 'lightcyan');
               bc.barFill.addColorStop(.71, 'white');
    */
               bc.backgroundFill = bc.ctx.createLinearGradient( 0, 0, 0, bc.canvas.height);
               bc.backgroundFill.addColorStop(0.0, '#AAAAAA');
               bc.backgroundFill.addColorStop(1.0, '#EEEEEE');
    
               // Start
               bc.animStart();
           }
       },
    
    
       draw: function() {
           // Hintergrund zeichnen
           bc.ctx.fillStyle = bc.backgroundFill;
           bc.ctx.fillRect(0, 0, bc.canvas.width, bc.canvas.height);
    
    
           // Status retten und Ursprung nach unten verschieben
           // sowie Koordinaten an der x-Achse spiegeln
           bc.ctx.save();
    
           bc.ctx.translate(xoffset, bc.canvas.height - yoffset);
           bc.ctx.scale(1, -1);
    
          // bc.ctx.fillStyle = "red";
    
    
    
       // Säulen zeichnen
                for(var i = 0; i < values[1].length; i++) {                  
                   bc.ctx.fillStyle = colors[i]; //bc.barFill;
                   bc.ctx.fillRect(i * (bc.barWidth + xoffset),0 , bc.barWidth, bc.scale * values[1][i] * (bc.canvas.height - yoffset*2) / vmax);
                   //					x1					   y1	x2				y2            Höhe des Canvas - Doppelter Rand / Höchstwert (zur Skalierung)   
               }
    
           // Alten Status wiederherstellen
           bc.ctx.restore();
       },
    
    
       animate: function() {
           var diffTime = new Date().getTime() - bc.startTime;
    
           // Skalierungsfaktor (0.0 bis 1.0) für Säulen berechnen
           bc.scale = diffTime / (1000 * bc.duration);
    
           // Ende?
           if(diffTime >= 1000 * bc.duration) {
               bc.scale = 1.0; // Auf 1.0 setzen, damit die Säulen am Schluss mit
                               // Sicherheit mit dem richtigen Wert gezeichnet werden
    
                showData();
                
                clearInterval(bc.timer);
               
               // Neustart nach 10 Sekunden
               //setTimeout(bc.animStart, 1000 * 10);
          }
    
          bc.draw();
       },
    
    
       animStart: function() {
           bc.startTime = new Date().getTime();
           bc.timer = setInterval(bc.animate, 1000 / bc.fps);
       },
       
    };
    
    
    
    function showData () {  
                // Balken in Datenmaske erstellen
                for(var i = 0; i < values[1].length; i++) {
    
                    // mouse over datenmaske
                       var x1 = i * (bc.barWidth + xoffset) + xoffset;
                       var y1 = bc.canvas.height - yoffset - bc.scale * values[1][i] * (bc.canvas.height-yoffset*2) / vmax;
                       var x2 = i * (bc.barWidth + xoffset) + xoffset + bc.barWidth;
                       var y2 = bc.canvas.height - yoffset;
                    
                    balken = document.createElement('area');
                        balken.setAttribute("title", besch[i] + ": " + values[1][i] + einh);
                        balken.setAttribute("shape", "rect");				
                        balken.setAttribute("coords", x1 + "," + y1 + "," + x2 + "," + y2);
                        balken.setAttribute("href", "#");
                    document.getElementById('data').appendChild(balken);
                
                // Werte einblenden
                    var yTitle = y1 + 10;
                    titel = document.createElement('div');
                        titel.setAttribute("style", "left:" + x1 + "px; top:" + yTitle + "px; font-size:"+fonty+"px;" );
                        titel.innerHTML = values[1][i]+einh ;				// +besch[i]
                    document.getElementById('titel').appendChild(titel);
                    
                // besch einblenden (y-Achse)
                    ybesch = bc.canvas.height - 22;
                    beschr = document.createElement('div');
                        beschr.setAttribute("style", "left:" + x1 + "px; top:" + ybesch + "px; font-size:"+fontx+"px; width: "+bc.barWidth+"px;" );
                        beschr.innerHTML = besch[i] ;				// +besch[i]
                    document.getElementById('besch').appendChild(beschr);
        
                    
                }
        }
    
