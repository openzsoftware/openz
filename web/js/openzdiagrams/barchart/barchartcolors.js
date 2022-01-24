
 c = new Array();
 
 c[1] = new Array('#f5f5f5');
 c[2] = new Array('#223d51', '#74818b', '#8e804d', '#b7a26b');
 c[3] = new Array('#e65540', '#f8ecc2','#65a8a6','#79896d');  
 c[4] = new Array('#951f2b', '#f5f4d7','#e0dfb1','#a5a36c', '#535233');
 c[5] = new Array('#e8f3f8', '#dbe6ec','#c2cbce','#a4bcc2', '#81a8b8');
 c[6] = new Array('#d1e751', '#ffffff','#000000','#4dbce9', '#26ade4');
 c[7] = new Array('#55C3DC', '#8C6429', '#E7F3EF', '#73726D', '#E24B2C');

 c[8] = new Array('#e4e4e4','#e8e8e8','#ebebeb','#f0f0f0','#f4f4f4','#f8f8f8','#fbfbfb','#fffff'); 

 c[9] = new Array('#c0c0c0','#c7c7c7','#d0d0d0','#d7d7d7','#e0e0e0','#e7e7e7','#f0f0f0','#f7f7f7'); 
 
 function makeColors() {
    sb = document.getElementById('sb'); //swatch box wrapper
	
	for (var i=1; i < c.length; i++) {
		   csb = document.createElement('div'); // color swatch box		
		   
		   	var mousehandler = function (evt) {
		switch (evt.type) {
			case "mouseover":
				$(this).addClass("over");
				break;
			case "mouseout":
				$(this).removeClass("over");
				break;
		}
	}
	

           csb.setAttribute("class", "csb clearfix" );
		   csb.setAttribute("id", 'csb'+i );
		   csb.setAttribute("rel", c[i]);		   
					 
		for (var j=0; j < c[i].length; j++) {					 
               csb.innerHTML += "<div class='cs' style='background-color: "+c[i][j]+"' ></div>";
		}
		
        sb.appendChild(csb);	
	
	}
 }