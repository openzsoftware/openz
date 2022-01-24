/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
*************************************************************************************************************************************************** 
*/

function PointChartExample(){
                dojo.require('dojox.charting.Chart2D');
                dojo.require('dojox.charting.widget.Chart2D');
                dojo.require('dojox.charting.themes.ThreeD');
                
                /* JSON information */
            var json = {
                January: [12999,14487,19803,15965,17290],
                February: [14487,12999,15965,17290,19803],
                March: [15965,17290,19803,12999,14487]
            };

            /* build pie chart data */
            var chartData = [];
            dojo.forEach(json['January'],function(item,i) {
                chartData.push({ x: i, y: json['January'][i] });
            });

            /* resources are ready... */
            dojo.ready(function() {

                var pointchart = new dojox.charting.Chart2D('pointchart').
                    addPlot('default', {
                    type: 'Scatter',
                    markers: true,
                    tension: 'S',
                    lines: true,
                    areas: true,
                    labelOffset: -30,
                    shadows: { dx:2, dy:2, dw:2 }
                }).
                addAxis('x', { min:0, max:6 }).
                addAxis('y', { vertical:true, max:20000 }).
                setTheme(dojox.charting.themes.ThreeD).
                addSeries('January Visits',json['January']).
                addSeries('February Visits',json['February']).
                addSeries('March Visits',json['March']).
                render();
                var anim1a = new dojox.charting.action2d.Magnify(pointchart, 'default');
                var anim1b = new dojox.charting.action2d.Tooltip(pointchart, 'default');
                pointchart.render();

            });
}

function PieChartExample(){    
    dojo.require('dojox.charting.Chart2D');
    dojo.require('dojox.charting.widget.Chart2D');
    dojo.require('dojox.charting.themes.Tom');

    /* JSON information */
    var json = {
        January: [12999,14487,19803,15965,17290],
        February: [14487,12999,15965,17290,19803],
        March: [15965,17290,19803,12999,14487]
    };

    /* build pie chart data */
    var chartData = [];
    dojo.forEach(json['January'],function(item,i) {
        chartData.push({ x: i, y: json['January'][i] });
    });

    /* resources are ready... */
    dojo.ready(function() {

        var piechart = new dojox.charting.Chart2D('piechart').
                        setTheme(dojox.charting.themes.Tom).
                        addPlot('default', {type: 'Pie', radius: 70, fontColor: 'black'}).
                        addSeries('Visits', chartData).
                        render();
        var anim = new dojox.charting.action2d.MoveSlice(piechart, 'default');
        piechart.render();

    });
}

function BarChartExample(){    
    dojo.require('dojox.charting.Chart2D');
    dojo.require('dojox.charting.widget.Chart2D');
    dojo.require('dojox.charting.themes.PlotKit.blue');

    /* JSON information */
    var json = {
        January: [12999,14487,19803,15965,17290],
        February: [14487,12999,15965,17290,19803],
        March: [15965,17290,19803,12999,14487]
    };

    /* build pie chart data */
    var chartData = [];
    dojo.forEach(json['January'],function(item,i) {
        chartData.push({ x: i, y: json['January'][i] });
    });

    /* resources are ready... */
    dojo.ready(function() {

        //create / swap data
        var barData = [];
        dojo.forEach(chartData,function(item) { barData.push({ x: item['y'], y: item['x'] }); });
        var barchart = new dojox.charting.Chart2D('barchart').
                        setTheme(dojox.charting.themes.PlotKit.blue).
                        addAxis('x', { fixUpper: 'major', includeZero: false, min:0, max:6 }).
                        addAxis('y', { vertical: true, fixLower: 'major', fixUpper: 'major' }).
                        addPlot('default', {type: 'Columns', gap:5 }).
                        addSeries('Visits For February', chartData, {});
        var anim4b = new dojox.charting.action2d.Tooltip(barchart, 'default');
        var anim4c = new dojox.charting.action2d.Shake(barchart,'default');
        barchart.render();
        var legend4 = new dojox.charting.widget.Legend({ chart: barchart }, 'legend3');

    });
}
