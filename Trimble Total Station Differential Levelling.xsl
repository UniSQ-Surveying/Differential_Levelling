<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"    
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt">

<!-- (c) 2021, Trimble Inc. All rights reserved.                                               -->
<!-- Permission is hereby granted to use, copy, modify, or distribute this style sheet for any -->
<!-- purpose and without fee, provided that the above copyright notice appears in all copies   -->
<!-- and that both the copyright notice and the limited warranty and restricted rights notice  -->
<!-- below appear in all supporting documentation.                                             -->

<!-- TRIMBLE INC. PROVIDES THIS STYLE SHEET "AS IS" AND WITH ALL FAULTS.                       -->
<!-- TRIMBLE INC. SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTY OF MERCHANTABILITY               -->
<!-- OR FITNESS FOR A PARTICULAR USE. TRIMBLE INC. DOES NOT WARRANT THAT THE                   -->
<!-- OPERATION OF THIS STYLE SHEET WILL BE UNINTERRUPTED OR ERROR FREE.                        -->

<!-- Developed by Andrew Cleland 2023 -->
<!-- 230919 -->
<!-- Differential levelling data can be collected with a total station.

    See https://github.com/UniSQ-Surveying/Differential_Levelling for instructions
    on how to do this.

    This stylesheet has been developed to output data collected with a total station
    in standard level book format (BS, IS, FS, Rise, Fall).
  -->
<xsl:output method="html" omit-xml-declaration="no" encoding="utf-8"/>

<!-- Set the numeric display details i.e. decimal point, thousands separator etc -->
<xsl:variable name="DecPt" select="'.'"/>    <!-- Change as appropriate for US/European -->
<xsl:variable name="GroupSep" select="','"/> <!-- Change as appropriate for US/European -->
<!-- Also change decimal-separator & grouping-separator in decimal-format below 
     as appropriate for US/European output -->
<xsl:decimal-format name="Standard" 
                    decimal-separator="."
                    grouping-separator=","
                    infinity="Infinity"
                    minus-sign="-"
                    NaN="?"
                    percent="%"
                    per-mille="&#2030;"
                    zero-digit="0" 
                    digit="#" 
                    pattern-separator=";" />

<xsl:variable name="DecPl0" select="'#0'"/>
<xsl:variable name="DecPl1" select="concat('#0', $DecPt, '0')"/>
<xsl:variable name="DecPl2" select="concat('#0', $DecPt, '00')"/>
<xsl:variable name="DecPl3" select="concat('#0', $DecPt, '000')"/>
<xsl:variable name="DecPl4" select="concat('#0', $DecPt, '0000')"/>
<xsl:variable name="DecPl5" select="concat('#0', $DecPt, '00000')"/>
<xsl:variable name="DecPl6" select="concat('#0', $DecPt, '000000')"/>
<xsl:variable name="DecPl8" select="concat('#0', $DecPt, '00000000')"/>

<xsl:variable name="fileExt" select="'htm'"/>

<xsl:key name="atmosID-search" match="/JOBFile/FieldBook/AtmosphereRecord" use="@ID"/>
<xsl:key name="tgtHtID-search" match="/JOBFile/FieldBook/TargetRecord" use="@ID"/>
<xsl:key name="stnID-search" match="/JOBFile/FieldBook/StationRecord" use="@ID"/>
<xsl:key name="reducedPt-search" match="/JOBFile/Reductions/Point" use="Name"/>

<!-- User variable definitions - Appropriate fields are displayed on the       -->
<!-- Survey Controller screen to allow the user to enter specific values       -->
<!-- which can then be used within the style sheet definition to control the   -->
<!-- output data.                                                              -->
<!--                                                                           -->
<!-- All user variables must be identified by a variable element definition    -->
<!-- named starting with 'userField' (case sensitive) followed by one or more  -->
<!-- characters uniquely identifying the user variable definition.             -->
<!--                                                                           -->
<!-- The text within the 'select' field for the user variable description      -->
<!-- references the actual user variable and uses the '|' character to         -->
<!-- separate the definition details into separate fields as follows:          -->
<!-- For all user variables the first field must be the name of the user       -->
<!-- variable itself (this is case sensitive) and the second field is the      -->
<!-- prompt that will appear on the Survey Controller screen.                  -->
<!-- The third field defines the variable type - there are four possible       -->
<!-- variable types: Double, Integer, String and StringMenu.  These variable   -->
<!-- type references are not case sensitive.                                   -->
<!-- The fields that follow the variable type change according to the type of  -->
<!-- variable as follow:                                                       -->
<!-- Double and Integer: Fourth field = optional minimum value                 -->
<!--                     Fifth field = optional maximum value                  -->
<!--   These minimum and maximum values are used by the Survey Controller for  -->
<!--   entry validation.                                                       -->
<!-- String: No further fields are needed or used.                             -->
<!-- StringMenu: Fourth field = number of menu items                           -->
<!--             Remaining fields are the actual menu items - the number of    -->
<!--             items provided must equal the specified number of menu items. -->
<!--                                                                           -->
<!-- The style sheet must also define the variable itself, named according to  -->
<!-- the definition.  The value within the 'select' field will be displayed in -->
<!-- the Survey Controller as the default value for the item.                  -->
<xsl:variable name="userField1" select="'StartHeight|Starting benchmark height|double|'"/>
<xsl:variable name="StartHeight" select="100"/>
<xsl:variable name="userField2" select="'EndHeight|Ending benchmark height|double|'"/>
<xsl:variable name="EndHeight" select="100"/>

<!-- **************************************************************** -->
<!-- Set global variables from the Environment section of JobXML file -->
<!-- **************************************************************** -->
<xsl:variable name="DistUnit"   select="/JOBFile/Environment/DisplaySettings/DistanceUnits" />
<xsl:variable name="AngleUnit"  select="/JOBFile/Environment/DisplaySettings/AngleUnits" />
<xsl:variable name="CoordOrder" select="/JOBFile/Environment/DisplaySettings/CoordinateOrder" />
<xsl:variable name="TempUnit"   select="/JOBFile/Environment/DisplaySettings/TemperatureUnits" />
<xsl:variable name="PressUnit"  select="/JOBFile/Environment/DisplaySettings/PressureUnits" />

<!-- Setup conversion factor for coordinate and distance values -->
<!-- Dist/coord values in JobXML file are always in metres -->
<xsl:variable name="DistConvFactor">
  <xsl:choose>
    <xsl:when test="$DistUnit='Metres'">1.0</xsl:when>
    <xsl:when test="$DistUnit='InternationalFeet'">3.280839895</xsl:when>
    <xsl:when test="$DistUnit='USSurveyFeet'">3.2808333333357</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="DistUnitStr">
  <xsl:choose>
    <xsl:when test="$DistUnit='InternationalFeet'">ft</xsl:when>
    <xsl:when test="$DistUnit='USSurveyFeet'">sft</xsl:when>
    <xsl:otherwise>m</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup conversion factor for angular values -->
<!-- Angular values in JobXML file are always in decimal degrees -->
<xsl:variable name="AngleConvFactor">
  <xsl:choose>
    <xsl:when test="$AngleUnit='DMSDegrees'">1.0</xsl:when>
    <xsl:when test="$AngleUnit='Gons'">1.111111111111</xsl:when>
    <xsl:when test="$AngleUnit='Mils'">17.77777777777</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="AngleUnitStr">
  <xsl:choose>
    <xsl:when test="$AngleUnit='DMSDegrees'">dms</xsl:when>
    <xsl:when test="$AngleUnit='Gons'">gon</xsl:when>
    <xsl:when test="$AngleUnit='Mils'">mil</xsl:when>
    <xsl:otherwise>deg</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup boolean variable for coordinate order -->
<xsl:variable name="NECoords">
  <xsl:choose>
    <xsl:when test="$CoordOrder='North-East-Elevation'">true</xsl:when>
    <xsl:when test="$CoordOrder='X-Y-Z'">true</xsl:when>
    <xsl:otherwise>false</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup conversion factor for pressure values -->
<!-- Pressure values in JobXML file are always in millibars (hPa) -->
<xsl:variable name="PressConvFactor">
  <xsl:choose>
    <xsl:when test="$PressUnit='MilliBar'">1.0</xsl:when>
    <xsl:when test="$PressUnit='InchHg'">0.029529921</xsl:when>
    <xsl:when test="$PressUnit='mmHg'">0.75006</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="PressUnitStr">
  <xsl:choose>
    <xsl:when test="$PressUnit='InchHg'">inHg</xsl:when>
    <xsl:when test="$PressUnit='mmHg'">mmHg</xsl:when>
    <xsl:otherwise>hPa</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="TempUnitStr">
  <xsl:choose>
    <xsl:when test="$TempUnit='Celsius'"><xsl:text>&#0176;C</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>&#0176;F</xsl:text></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="product">
  <xsl:choose>
    <xsl:when test="JOBFile/@product"><xsl:value-of select="JOBFile/@product"/></xsl:when>
    <xsl:otherwise>Trimble Survey Controller</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="version">
  <xsl:choose>
    <xsl:when test="JOBFile/@productVersion"><xsl:value-of select="JOBFile/@productVersion"/></xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="format-number(JOBFile/@version div 100, $DecPl2, 'Standard')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="Pi" select="3.14159265358979323846264"/>
<xsl:variable name="halfPi" select="$Pi div 2.0"/>

<!-- **************************************************************** -->
<!-- ************************** Main Loop *************************** -->
<!-- **************************************************************** -->
<xsl:template match="/" >
  <html>

  <title>Total Station Differential Levelling</title>
  <h1>Total Station Differential Levelling</h1>

  

  <!-- Set the font size for use in tables -->
  <style type="text/css">
    html { font-family: Arial }
    body, table, td, th
    {
      font-size:small;
      padding: 5px;
    }
	
	table.border {border-style: solid; border-width: 1px; border-color: black; border-collapse: collapse;}
	table.noBorder {border-style: none; border-width: 0;}

  table {
    table-layout: fixed;
  }

  tr:nth-child(even) {
    background-color: #dfdfdf;
  }

  th {
    text-align: center;
    font-size: 20px;
    font-weight: bold;
  }

  td {
    text-align: center;
    font-size: 18px;
  }

  tr:nth-child(1) {
    font-weight: bold;
  }

  tr:nth-last-child(1) {
    font-weight: bold;
  }

  th:nth-child(8), td:nth-child(8) {
    display: none;
  }

  th:nth-child(10), td:nth-child(10) {
    display: none;
  }

  .footer {
    position: fixed;
    left: 0;
    bottom: 0;
    width: 100%;
    text-align: center;
  }

  </style>

  <head>
  </head>

  <body>
    <xsl:call-template name="ProjectDetails"/>
    <span id="startHeight" style="visibility: hidden;">
      <xsl:value-of select="$StartHeight"/>
    </span>
    <span id="endHeight" style="visibility: hidden;">
      <xsl:value-of select="$EndHeight"/>
    </span>
    <br />
    <br />
    <h2>Level Book</h2>
    <xsl:call-template name="StartTable">
      <xsl:with-param name="includeBorders">true</xsl:with-param>
      <xsl:with-param name="Id"><xsl:text>levelBook</xsl:text></xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="OutputTenElementTableLine">
        <xsl:with-param name="val1">
          <xsl:text>BS</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val2">
          <xsl:text>IS</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val3">
          <xsl:text>FS</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val4">
          <xsl:text>Rise</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val5">
          <xsl:text>Fall</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val6">
          <xsl:text>RL</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val7">
          <xsl:text>Point Name</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val8">
          <xsl:text>Delta Height</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val9">
          <xsl:text>Slope Distance</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="val10">
          <xsl:text>Obs Type</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="OutputLevelData"/>
    <tr>
      <td id="sumBS"></td>
      <td></td>
      <td id="sumFS"></td>
      <td id="sumRise"></td>
      <td id="sumFall"></td>
      <td id="delta"></td>
      <td></td>
      <td></td>
      <td id="sumSlopeDistance"></td>
      <td></td>
    </tr>
    <xsl:call-template name="EndTable"/>

    <br/>
    <br/>
    <h2>Allowable Misclose</h2>
    <h3 id="12rootk"></h3>
    <h3 id="6rootk"></h3>
    <h3 id="2rootk"></h3>

    <div class="footer">
      <p>See <a href="https://github.com/UniSQ-Surveying/Differential_Levelling">here</a> for a detailed guide by Damian Forknall, Jordan Williams, 
      Garry Cislowski and Chris McAlister about how to do differential levelling with a total station.</p>
      <p>This stylesheet was developed by Andrew Cleland.</p>
    </div>


  <script>
  function updateSums() {
    var table = document.getElementById("levelBook");
    let subTotalBS = Array.from(table.rows).slice(1).reduce((total, row) => {
      return total + parseFloat(row.cells[0].innerHTML || 0);
    }, 0);
    document.getElementById("sumBS").innerHTML = "Sum BS = " + subTotalBS.toFixed(4);

    let subTotalFS = Array.from(table.rows).slice(1).reduce((total, row) => {
      return total + parseFloat(row.cells[2].innerHTML || 0);
    }, 0);
    document.getElementById("sumFS").innerHTML = "Sum FS = " + subTotalFS.toFixed(4);

    let subTotalRise = Array.from(table.rows).slice(1).reduce((total, row) => {
      return total + parseFloat(row.cells[3].innerHTML || 0);
    }, 0);
    document.getElementById("sumRise").innerHTML = "Sum Rise = " + subTotalRise.toFixed(4);

    let subTotalFall = Array.from(table.rows).slice(1).reduce((total, row) => {
      return total + parseFloat(row.cells[4].innerHTML || 0);
    }, 0);
    document.getElementById("sumFall").innerHTML = "Sum Fall = " + subTotalRise.toFixed(4);

    let subTotalSlopeDistance = Array.from(table.rows).slice(1).reduce((total, row) => {
      let obsType = row.cells[9].innerHTML;
      let bsOrFS = ['BS', 'FS'].includes(obsType);
      return  bsOrFS ? (total + (parseFloat(row.cells[8].innerHTML || 0))) : total;
    }, 0);
    document.getElementById("sumSlopeDistance").innerHTML = "Sum BS and FS (k) = " + subTotalSlopeDistance.toFixed(3);

    // Update RL
    let rowCount = table.rows.length - 1;
    // Get the starting RL from the first level row
    const startHeight = parseFloat(document.getElementById("startHeight").innerHTML) || 0;
    const endHeight = parseFloat(document.getElementById("endHeight").innerHTML) || 0;
    let currentRL = startHeight;
    for (var r = 2; r &lt; rowCount; r++){
        const deltaHeight = parseFloat(table.rows[r].cells[7].innerHTML) || 0;
        currentRL += deltaHeight;

        let rlCell = table.rows[r].cells[5];
        rlCell.innerHTML = currentRL.toFixed(4);
    }

    // Calculate diff between starting and ending benchmark readings
    document.getElementById("delta").innerHTML = "Misclose = " + (currentRL - endHeight).toFixed(4);

    let k = subTotalSlopeDistance / 1000;
    document.getElementById("12rootk").innerHTML = "Third order (12√k) = " + (12 * Math.sqrt(k) / 1000).toFixed(4);
    document.getElementById("6rootk").innerHTML = "Second order (6√k) = " + (6 * Math.sqrt(k) / 1000).toFixed(4);
    document.getElementById("2rootk").innerHTML = "First order (2√k) = " + (2 * Math.sqrt(k) / 1000).toFixed(4);
  }
  updateSums();

  
  </script>
  </body>
  </html>
</xsl:template>


<xsl:template name="ProjectDetails">
  <h2>Job: <xsl:value-of select="JOBFile/@jobName" /></h2>
  <h2>Date: <xsl:value-of select="substring(JOBFile/@TimeStamp, 1, 10)" /></h2>
  <h2>Instrument Details</h2>
  <h3>&#160; &#160; Model: <xsl:value-of select="JOBFile/FieldBook/InstrumentRecord[last()]/Model" /></h3>
  <h3>&#160; &#160; Serial: <xsl:value-of select="JOBFile/FieldBook/InstrumentRecord[last()]/Serial" /></h3>

  <xsl:variable name="haPrecision">
    <xsl:call-template name="FormatAngle">
      <xsl:with-param name="theAngle" select="JOBFile/FieldBook/InstrumentRecord[last()]/HorizontalAnglePrecision"/>
      <xsl:with-param name="secDecPlaces">2</xsl:with-param>
      <xsl:with-param name="DMSOutput">true</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="vaPrecision">
    <xsl:call-template name="FormatAngle">
      <xsl:with-param name="theAngle" select="JOBFile/FieldBook/InstrumentRecord[last()]/VerticalAnglePrecision"/>
      <xsl:with-param name="secDecPlaces">2</xsl:with-param>
      <xsl:with-param name="DMSOutput">true</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="edmPrecision">
    <xsl:value-of select="format-number(JOBFile/FieldBook/InstrumentRecord[last()]/EDMPrecision, $DecPl3, 'Standard')" />
  </xsl:variable>
  <xsl:variable name="edmPPM">
    <xsl:value-of select="format-number(JOBFile/FieldBook/InstrumentRecord[last()]/EDMppm, $DecPl1, 'Standard')" />
  </xsl:variable>
  <h3>&#160; &#160; Horizontal Angle Precision: <xsl:value-of select="$haPrecision" /></h3>
  <h3>&#160; &#160; Vertical Angle Precision: <xsl:value-of select="$vaPrecision" /></h3>
  <h3>&#160; &#160; EDM Precision: <xsl:value-of select="$edmPrecision" /></h3>
  <h3>&#160; &#160; EDM ppm: <xsl:value-of select="$edmPPM" /></h3>
</xsl:template>



<xsl:template name="OutputLevelData">
  <xsl:variable name="AllRounds">
    <xsl:call-template name="GetLevelObs"/>
  </xsl:variable>
  <xsl:variable name="LevelBookRows">
    <xsl:for-each select="msxsl:node-set($AllRounds)/StnPoint">
      <xsl:variable name="i" select="position()" />
      <xsl:variable name="stn" select="stnName" />
      <xsl:variable name="ptName" select="pointName" />
      <xsl:variable name="bsPoint" select="backsightPoint" />
      <!-- Look ahead to the next row so that we can pull out the BS value on a FS row -->
      <xsl:variable name="next" select="msxsl:node-set($AllRounds)/StnPoint[$i + 1]" />
      <xsl:variable name="prev" select="msxsl:node-set($AllRounds)/StnPoint[$i - 1]" />

      <xsl:variable name="firstBS">
        <xsl:choose>
          <xsl:when test="obsType = 'BS' and $i = 1">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="reducedVDiff">
          <xsl:value-of select="format-number(-1 * ($prev/VD - VD), $DecPl4, 'Standard')" />
      </xsl:variable>


      <xsl:if test="$firstBS = 1 or obsType != 'BS'">
        <xsl:element name="Row">
        <xsl:element name="Index">
          <xsl:value-of select="$i"/>
        </xsl:element>
        <xsl:element name="firstBS">
          <xsl:value-of select="$firstBS"/>
        </xsl:element>
        <xsl:element name="deltaHeight">
          <xsl:value-of select="$reducedVDiff"/>
        </xsl:element>
        <xsl:element name="SD">
          <xsl:value-of select="format-number(SD, $DecPl3, 'Standard')"/>
        </xsl:element>
        <xsl:element name="ObsType">
          <xsl:value-of select="obsType"/>
        </xsl:element>
        <xsl:choose>
          <xsl:when test="obsType = 'BS'">
            <xsl:element name="BS">
              <xsl:value-of select="VD"/>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="BS">
              <xsl:text />
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="obsType = 'IS'">
            <xsl:element name="ISRow">
              <xsl:element name="IS">
                <xsl:value-of select="VD"/>
              </xsl:element>
              <xsl:element name="Rise">
                <xsl:choose>
                  <xsl:when test="$reducedVDiff &gt;= 0">
                      <xsl:value-of select="$reducedVDiff"/>
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:text />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:element>
              <xsl:element name="Fall">
              <xsl:choose>
                <xsl:when test="$reducedVDiff  &lt; 0">
                    <xsl:value-of select="$reducedVDiff * -1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text />
                </xsl:otherwise>
                </xsl:choose>
              </xsl:element>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="ISRow">
              <xsl:text />
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="obsType = 'FS'">
            <xsl:element name="FSRow">
              <xsl:element name="FS">
                <xsl:value-of select="VD"/>
              </xsl:element>
              <xsl:element name="BS">
                <xsl:value-of select="$next/VD"/>
              </xsl:element>
              <xsl:element name="Rise">
                <xsl:choose>
                  <xsl:when test="$reducedVDiff &gt;= 0">
                      <xsl:value-of select="$reducedVDiff"/>
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:text />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:element>
              <xsl:element name="Fall">
                <xsl:choose>
                  <xsl:when test="$reducedVDiff  &lt; 0">
                      <xsl:value-of select="$reducedVDiff * -1"/>
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:text />
                  </xsl:otherwise>
                  </xsl:choose>
              </xsl:element>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="FSRow">
              <xsl:text />
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:element name="StnName">
          <xsl:value-of select="stnName"/>
        </xsl:element>
        <xsl:element name="PointName">
          <xsl:value-of select="pointName"/>
        </xsl:element>
      </xsl:element>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>


  <xsl:for-each select="msxsl:node-set($LevelBookRows)/Row">
    <xsl:variable name="j" select="position()" />
    <xsl:call-template name="OutputTenElementTableLine">
        <xsl:with-param name="val1">
          <!-- Only one of these variables shouild ever have a value.
            Using concat to just grab whatever is available -->
          <xsl:value-of select="concat(BS, FSRow/BS)"/>
        </xsl:with-param>
        <xsl:with-param name="val2">
          <xsl:value-of select="ISRow/IS"/>
        </xsl:with-param>
        <xsl:with-param name="val3">
          <xsl:value-of select="FSRow/FS"/>
        </xsl:with-param>
        <xsl:with-param name="val4">
          <xsl:value-of select="concat(FSRow/Rise, ISRow/Rise)"/>
        </xsl:with-param>
        <xsl:with-param name="val5">
          <xsl:value-of select="concat(FSRow/Fall, ISRow/Fall)"/>
        </xsl:with-param>
        <xsl:with-param name="val6">
          <xsl:value-of select="format-number($StartHeight, $DecPl4, 'Standard')"/>
        </xsl:with-param>
        <xsl:with-param name="val7">
          <xsl:value-of select="PointName"/>
        </xsl:with-param>
        <xsl:with-param name="val8">
          <xsl:value-of select="deltaHeight"/>
        </xsl:with-param>
        <xsl:with-param name="val9">
          <xsl:value-of select="SD"/>
        </xsl:with-param>
        <xsl:with-param name="val10">
          <xsl:value-of select="ObsType"/>
        </xsl:with-param>
      </xsl:call-template>
  </xsl:for-each>
</xsl:template>

<xsl:template name="GetLevelObs">
  <xsl:for-each select="/JOBFile/FieldBook/StationRecord">

    <xsl:variable name="stnName" select="StationName"/>
    <xsl:variable name="instHt" select="TheodoliteHeight"/>

    <!-- Now output any Rounds data collected at this Station -->
    <xsl:variable name="tempStationRecordPosn">
      <xsl:for-each select="following-sibling::*">
        <xsl:if test="name(.) = 'StationRecord'">
          <xsl:value-of select="concat(position(), ' ')"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="nextStationRecordPosn" select="substring-before($tempStationRecordPosn, ' ')"/>

    <xsl:for-each select="following-sibling::*">
      <xsl:if test="name(.) = 'StartRoundsRecord'">
        <xsl:if test="(position() &gt; 0) and
                      ((position() &lt; $nextStationRecordPosn) or
                       ($nextStationRecordPosn = ''))">

          <!-- The current context record is the next appropriate StartRoundsRecord -->
          <!-- Now output the rounds data for these rounds.                         -->
          <!-- <xsl:variable name="StnRounds"> -->
            <xsl:call-template name="OutputRoundsData">
              <xsl:with-param name="stnName" select="$stnName"/>
              <xsl:with-param name="instHt" select="$instHt"/>
            </xsl:call-template>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>

  </xsl:for-each>  <!-- /JOBFile/FieldBook/StationRecord -->
</xsl:template>




<!-- **************************************************************** -->
<!-- *************** Output Backsight Point Coordinates ************* -->
<!-- **************************************************************** -->
<xsl:template name="OutputBacksightPoints">
  <xsl:param name="stationID"/>

  <!-- Get a list of all the backsight point names into a node-set variable -->
  <xsl:variable name="BSPtNames">
    <xsl:for-each select="/JOBFile/FieldBook/PointRecord[(StationID = $stationID) and (Classification = 'BackSight')]">
      <xsl:element name="PtName">
        <xsl:element name="Name">
          <xsl:value-of select="Name"/>
        </xsl:element>
        <xsl:variable name="ptName" select="Name"/>

        <xsl:element name="North">
          <xsl:variable name="north">
            <xsl:for-each select="/JOBFile/Reductions/Point[Name = $ptName]">
              <xsl:value-of select="Grid/North"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="$north"/>
        </xsl:element>

        <xsl:element name="East">
          <xsl:variable name="east">
            <xsl:for-each select="/JOBFile/Reductions/Point[Name = $ptName]">
              <xsl:value-of select="Grid/East"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="$east"/>
        </xsl:element>

        <xsl:element name="Elevation">
          <xsl:variable name="elev">
            <xsl:for-each select="/JOBFile/Reductions/Point[Name = $ptName]">
              <xsl:value-of select="Grid/Elevation"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="$elev"/>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>
  </xsl:variable>
  
  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>
    <xsl:call-template name="OutputFourElementTableLine">
      <xsl:with-param name="val1">Point Name</xsl:with-param>
      <xsl:with-param name="val2">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">Northing</xsl:when>
          <xsl:otherwise>Easting</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val3">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">Easting</xsl:when>
          <xsl:otherwise>Northing</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val4">Elevation</xsl:with-param>
      <xsl:with-param name="bold">true</xsl:with-param>
    </xsl:call-template>

    <xsl:for-each select="msxsl:node-set($BSPtNames)/PtName">
      <xsl:variable name="currPos" select="position()"/>
      <xsl:variable name="currName" select="Name"/>
      <xsl:variable name="prevPts">
        <xsl:value-of select="count(msxsl:node-set($BSPtNames)/PtName[(position() &lt; $currPos) and ($currName = Name)])"/>
      </xsl:variable>
      <xsl:if test="$prevPts = 0">   <!-- Only want to output each point once -->
        <xsl:call-template name="OutputFourElementTableLine">
          <xsl:with-param name="val1" select="Name"/>
          <xsl:with-param name="val2">
            <xsl:choose>
              <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number(North * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="format-number(East * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="val3">
            <xsl:choose>
              <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number(East * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="format-number(North * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="val4" select="format-number(Elevation * $DistConvFactor, $DecPl4, 'Standard')"/>
        </xsl:call-template>
     </xsl:if>
   </xsl:for-each>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Output Backsight Measurements **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputBacksightMeasurements">
  <xsl:param name="stationID"/>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val1">Point Name</xsl:with-param>
      <xsl:with-param name="val2">Code</xsl:with-param>
      <xsl:with-param name="val3">SD [<xsl:value-of select="$DistUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val4">HA [<xsl:value-of select="$AngleUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val5">VA [<xsl:value-of select="$AngleUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val6">th [<xsl:value-of select="$DistUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val7">PC [mm]</xsl:with-param>
      <xsl:with-param name="bold">true</xsl:with-param>
    </xsl:call-template>

    <xsl:for-each select="/JOBFile/FieldBook/PointRecord[(StationID = $stationID) and (Classification = 'BackSight')]">
      <xsl:variable name="prismConst" select="key('tgtHtID-search', TargetID)[1]/PrismConstant"/>

      <xsl:variable name="ppm">
        <xsl:for-each select="key('stnID-search', StationID)">
          <xsl:value-of select="key('atmosID-search', AtmosphereID)/PPM"/>
        </xsl:for-each>
      </xsl:variable>

      <xsl:variable name="slopeDist">
        <xsl:call-template name="CorrectedDistance">
          <xsl:with-param name="slopeDist" select="Circle/EDMDistance"/>
          <xsl:with-param name="prismConst" select="$prismConst"/>
          <xsl:with-param name="atmosPPM" select="$ppm"/>
          <xsl:with-param name="applyStationSF">false</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:call-template name="OutputEightElementTableLine">
        <xsl:with-param name="val1" select="Name"/>
        <xsl:with-param name="val2" select="Code"/>
        <xsl:with-param name="val3" select="format-number($slopeDist * $DistConvFactor, $DecPl4, 'Standard')"/>
        <xsl:with-param name="val4">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="Circle/HorizontalCircle"/>
          </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="val5">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="Circle/VerticalCircle"/>
          </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="val6">
          <xsl:for-each select="key('tgtHtID-search', TargetID)[1]">
            <xsl:value-of select="format-number(TargetHeight * $DistConvFactor, $DecPl4, 'Standard')"/>
          </xsl:for-each>
        </xsl:with-param>
        <xsl:with-param name="val7">
          <xsl:value-of select="format-number($prismConst * 1000, $DecPl0, 'Standard')"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Output Station Residuals ******************* -->
<!-- **************************************************************** -->
<xsl:template name="OutputStationResiduals">

  <xsl:variable name="stnName" select="StationName"/>
  
  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val1">Point Name</xsl:with-param>
      <xsl:with-param name="val2">Code</xsl:with-param>
      <xsl:with-param name="val3">Station [<xsl:value-of select="$DistUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val4">Offset [<xsl:value-of select="$DistUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val5">delta Hz [<xsl:value-of select="$AngleUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="val6">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">delta N</xsl:when>
          <xsl:otherwise>delta E</xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="concat(' [', $DistUnitStr, ']')"/>
      </xsl:with-param>
      <xsl:with-param name="val7">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">delta E</xsl:when>
          <xsl:otherwise>delta N</xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="concat(' [', $DistUnitStr, ']')"/>
      </xsl:with-param>
      <xsl:with-param name="val8">delta El [<xsl:value-of select="$DistUnitStr"/>]</xsl:with-param>
      <xsl:with-param name="bold">true</xsl:with-param>
    </xsl:call-template>

    <!-- First locate the first StationResiduals record following the current StationRecord -->
    <xsl:for-each select="following-sibling::StationResiduals[1]">
      <!-- Now work through each ResidualsRecord under the StationResiduals -->
      <xsl:for-each select="ResidualsRecord">
        <xsl:variable name="ptName" select="PointName"/>
        <xsl:call-template name="OutputEightElementTableLine">
          <!-- Point name -->
          <xsl:with-param name="val1" select="PointName"/>
          <!-- Point code -->
          <xsl:with-param name="val2">   <!-- Get point code from Reductions section -->
            <xsl:for-each select="/JOBFile/Reductions/Point[Name = $ptName]">
              <xsl:value-of select="Code"/>
            </xsl:for-each>
          </xsl:with-param>
          <!-- Residual expressed along observed line -->
          <xsl:with-param name="val3">
            <xsl:variable name="station">
              <xsl:call-template name="ResidualAlongObsLine">
                <xsl:with-param name="stnName" select="$stnName"/>
                <xsl:with-param name="ptName" select="$ptName"/>
                <xsl:with-param name="resDeltaN" select="GridResidual/DeltaNorth"/>
                <xsl:with-param name="resDeltaE" select="GridResidual/DeltaEast"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="format-number($station * $DistConvFactor, $DecPl4, 'Standard')"/>
          </xsl:with-param>
          <!-- Residual expressed as offset to observed line -->
          <xsl:with-param name="val4">
            <xsl:variable name="offset">
              <xsl:call-template name="ResidualOrthogonalToObsLine">
                <xsl:with-param name="stnName" select="$stnName"/>
                <xsl:with-param name="ptName" select="$ptName"/>
                <xsl:with-param name="resDeltaN" select="GridResidual/DeltaNorth"/>
                <xsl:with-param name="resDeltaE" select="GridResidual/DeltaEast"/>
              </xsl:call-template>
            </xsl:variable>
            <!-- Output offset with switched sign to match example -->
            <xsl:value-of select="format-number($offset * -1.0 * $DistConvFactor, $DecPl4, 'Standard')"/>
          </xsl:with-param>
          <!-- Delta horizontal angle -->
          <xsl:with-param name="val5">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="AngleResidual/HorizontalCircle"/>
            </xsl:call-template>
          </xsl:with-param>
          <!-- Residual delta north/east -->
          <xsl:with-param name="val6">
            <xsl:choose>
              <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number(GridResidual/DeltaNorth * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="format-number(GridResidual/DeltaEast * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <!-- Residual delta east/north -->
          <xsl:with-param name="val7">
            <xsl:choose>
              <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number(GridResidual/DeltaEast * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="format-number(GridResidual/DeltaNorth * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <!-- Residual delta elevation -->
          <xsl:with-param name="val8" select="format-number(GridResidual/DeltaElevation * $DistConvFactor, $DecPl4, 'Standard')"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:for-each>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Output Station Position ******************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputStationPosition">
  <xsl:param name="stnName"/>
  <xsl:param name="scale"/>
  <xsl:param name="scaleSE"/>
  <xsl:param name="resectedStn"/>

  <xsl:variable name="stnNorth">
    <xsl:choose>
      <xsl:when test="$resectedStn = 'true'">
        <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
          <xsl:value-of select="Grid/North"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="key('reducedPt-search', $stnName)">
          <xsl:value-of select="Grid/North"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="stdDevN">
    <xsl:if test="$resectedStn = 'true'">
      <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
        <xsl:value-of select="ResectionStandardErrors/NorthStandardError"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="stnEast">
    <xsl:choose>
      <xsl:when test="$resectedStn = 'true'">
        <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
          <xsl:value-of select="Grid/East"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="key('reducedPt-search', $stnName)">
          <xsl:value-of select="Grid/East"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="stdDevE">
    <xsl:if test="$resectedStn = 'true'">
      <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
        <xsl:value-of select="ResectionStandardErrors/EastStandardError"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="stnElev">
    <xsl:choose>
      <xsl:when test="$resectedStn = 'true'">
        <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
          <xsl:value-of select="Grid/Elevation"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="key('reducedPt-search', $stnName)">
          <xsl:value-of select="Grid/Elevation"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="stdDevElev">
    <xsl:if test="$resectedStn = 'true'">
      <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
        <xsl:value-of select="ResectionStandardErrors/ElevationStandardError"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="orientation">
    <xsl:choose>
      <xsl:when test="$resectedStn = 'true'">
        <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
          <xsl:for-each select="preceding-sibling::BackBearingRecord[Station = $stnName][1]">
            <xsl:value-of select="OrientationCorrection"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="following-sibling::BackBearingRecord[1]">
          <xsl:value-of select="OrientationCorrection"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="orientationStdErr">
    <xsl:choose>
      <xsl:when test="$resectedStn = 'true'">
        <xsl:for-each select="following-sibling::PointRecord[(Name = $stnName) and (Method = 'Resection')][1]">
          <xsl:for-each select="preceding-sibling::BackBearingRecord[Station = $stnName][1]">
            <xsl:value-of select="OrientationCorrectionStandardError"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="following-sibling::BackBearingRecord[1]">
          <xsl:value-of select="OrientationCorrectionStandardError"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val2">Coordinates</xsl:with-param>
      <xsl:with-param name="val3">Std.Dev.</xsl:with-param>
      <xsl:with-param name="val8">Std.Dev.</xsl:with-param>
      <xsl:with-param name="bold">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val1">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">Northing</xsl:when>
          <xsl:otherwise>Easting</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val2">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number($stnNorth * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="format-number($stnEast * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val3">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'"><xsl:value-of select="concat(format-number($stdDevN * $DistConvFactor, $DecPl3, 'Standard'), $DistUnitStr)"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="concat(format-number($stdDevE * $DistConvFactor, $DecPl3, 'Standard'), $DistUnitStr)"/></xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val6">Orientation</xsl:with-param>
      <xsl:with-param name="val7">
        <!-- Output the orientation angle -->
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$orientation"/>
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="val8">
        <!-- Output the orientation angle standard error -->
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$orientationStdErr"/>
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="boldVal1">true</xsl:with-param>
      <xsl:with-param name="boldVal6">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val1">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'">Easting</xsl:when>
          <xsl:otherwise>Northing</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val2">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'"><xsl:value-of select="format-number($stnEast * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="format-number($stnNorth * $DistConvFactor, $DecPl4, 'Standard')"/></xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val3">
        <xsl:choose>
          <xsl:when test="$NECoords = 'true'"><xsl:value-of select="concat(format-number($stdDevE * $DistConvFactor, $DecPl3, 'Standard'), $DistUnitStr)"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="concat(format-number($stdDevN * $DistConvFactor, $DecPl3, 'Standard'), $DistUnitStr)"/></xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val6">Scale</xsl:with-param>
      <xsl:with-param name="val7" select="format-number($scale, $DecPl6, 'Standard')"/>
      <xsl:with-param name="val8" select="format-number($scaleSE, $DecPl6, 'Standard')"/>
      <xsl:with-param name="boldVal1">true</xsl:with-param>
      <xsl:with-param name="boldVal6">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputEightElementTableLine">
      <xsl:with-param name="val1">Elevation</xsl:with-param>
      <xsl:with-param name="val2" select="format-number($stnElev * $DistConvFactor, $DecPl4, 'Standard')"/>
      <xsl:with-param name="val3" select="concat(format-number($stdDevElev * $DistConvFactor, $DecPl3, 'Standard'), $DistUnitStr)"/>
      <xsl:with-param name="boldVal1">true</xsl:with-param>
    </xsl:call-template>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- *************** Output the Data from the Rounds **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputRoundsData">
  <xsl:param name="stnName"/>
  <xsl:param name="instHt"/>
  
  <!-- The current context is the current StartRoundsRecord for the rounds -->
  <!-- data that we want to output.                                        -->
  <xsl:variable name="obsData">
    <!-- Work from this StartRoundsRecord -->
    <!-- First find out how many records until the end of this set of    -->
    <!-- rounds - in case there are multiple sets of rounds in this file -->
    <xsl:variable name="temp">
      <xsl:for-each select="following-sibling::*">
        <xsl:if test="name(.) = 'EndRoundsRecord'">
          <xsl:value-of select="concat(position(), ' ')"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="lastRecord" select="substring-before($temp, ' ')"/>

    <xsl:for-each select="following-sibling::*">
      <xsl:if test="(position() &lt; $lastRecord) and (name(.) = 'StartRoundRecord')">
        <xsl:element name="Round">      <!-- We have a new Round - create a Round element -->
          <xsl:element name="roundNbr">
            <xsl:value-of select="Round"/>
          </xsl:element>
          <xsl:variable name="round" select="Round"/>
          <xsl:variable name="tempCount">
            <xsl:for-each select="following-sibling::*">
              <xsl:if test="name(.) = 'EndRoundRecord'">
                <xsl:value-of select="concat(position(), ' ')"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <xsl:variable name="endRoundCount" select="substring-before($tempCount, ' ')"/>
          <!-- Get each point in this Round and record both Face 1 and Face 2 hz angles -->
          <xsl:variable name="dataInRound">
            <xsl:for-each select="following-sibling::*[position() &lt; $endRoundCount]"> <!-- Is an observation record in the round -->
              <xsl:if test="Circle and (preceding-sibling::StartRoundRecord[1]/Round = $round)">
                <xsl:element name="Point">
                  <xsl:element name="Name">
                    <xsl:value-of select="Name"/>
                  </xsl:element>
                  <xsl:element name="Code">
                    <xsl:value-of select="Code"/>
                  </xsl:element>
                  <xsl:element name="Face">
                    <xsl:value-of select="Circle/Face"/>
                  </xsl:element>
                  <xsl:element name="hzAngle">
                    <xsl:value-of select="Circle/HorizontalCircle"/>
                  </xsl:element>
                  <xsl:element name="vtAngle">
                    <xsl:value-of select="Circle/VerticalCircle"/>
                  </xsl:element>
                  <xsl:variable name="prismConst" select="key('tgtHtID-search', TargetID)[1]/PrismConstant"/>
                  <xsl:variable name="ppm">
                    <xsl:for-each select="key('stnID-search', StationID)">
                      <xsl:value-of select="key('atmosID-search', AtmosphereID)/PPM"/>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:element name="rawDistance">
                    <xsl:value-of select="Circle/EDMDistance"/>
                  </xsl:element>
                  <xsl:element name="corrDistance">
                    <xsl:call-template name="CorrectedDistance">
                      <xsl:with-param name="slopeDist" select="Circle/EDMDistance"/>
                      <xsl:with-param name="prismConst" select="$prismConst"/>
                      <xsl:with-param name="atmosPPM" select="$ppm"/>
                      <xsl:with-param name="applyStationSF">false</xsl:with-param>
                    </xsl:call-template>
                  </xsl:element>
                  <xsl:element name="tgtHt">
                    <xsl:for-each select="key('tgtHtID-search', TargetID)[1]">
                      <xsl:value-of select="TargetHeight"/>
                    </xsl:for-each>
                  </xsl:element>
                  <xsl:element name="prismConst">
                    <xsl:value-of select="$prismConst"/>
                  </xsl:element>
                  <xsl:element name="Temperature">
                    <xsl:value-of select="Temperature"/>
                  </xsl:element>
                  <xsl:element name="Pressure">
                    <xsl:value-of select="Pressure"/>
                  </xsl:element>
                </xsl:element>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>

          <xsl:variable name="ptsInRound">
            <xsl:for-each select="following-sibling::*[position() &lt; $endRoundCount]">
              <xsl:if test="Circle and (preceding-sibling::StartRoundRecord[1]/Round = $round)">  <!-- Is in the round -->
                <xsl:element name="Point">
                  <xsl:element name="Name">
                    <xsl:value-of select="Name"/>
                  </xsl:element>
                </xsl:element>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>

          <xsl:variable name="uniquePtsInRound">
            <xsl:for-each select="msxsl:node-set($ptsInRound)/Point">
              <xsl:variable name="currPos" select="position()"/>
              <xsl:variable name="currName" select="Name"/>
              <xsl:variable name="prevPts">
                <xsl:value-of select="count(msxsl:node-set($ptsInRound)/Point[(position() &lt; $currPos) and ($currName = Name)])"/>
              </xsl:variable>
              <xsl:if test="$prevPts = 0">
                <xsl:element name="Point">
                  <xsl:element name="Name">
                    <xsl:value-of select="Name"/>
                  </xsl:element>
                </xsl:element>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>

          <xsl:for-each select="msxsl:node-set($uniquePtsInRound)/Point">
            <xsl:variable name="ptName" select="Name"/>
            <xsl:element name="Point">
              <xsl:element name="Name">
                <xsl:value-of select="Name"/>
              </xsl:element>

              <!-- Get the horizontal obs data for each point in the round with the current name -->
              <xsl:variable name="F1HzObs">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="hzAngle"/>
                </xsl:for-each>
              </xsl:variable>
              <xsl:variable name="F2HzObs">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face2')][1]">
                  <xsl:value-of select="hzAngle"/>
                </xsl:for-each>
              </xsl:variable>
              <!-- Add the F1 and F2 Hz obs elements -->
              <xsl:element name="F1Hz">
                <xsl:value-of select="$F1HzObs"/>
              </xsl:element>
              <xsl:element name="F2Hz">
                <xsl:value-of select="$F2HzObs"/>
              </xsl:element>
              <!-- Compute the mean observation -->
              <xsl:variable name="meanHzObs">
                <xsl:variable name="F1Hz" select="$F1HzObs"/>
                <xsl:variable name="corrF2Hz">
                  <xsl:call-template name="HzConvertToF1Obs">
                    <xsl:with-param name="F2Obs" select="$F2HzObs"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="string(number($corrF2Hz)) != 'NaN'">
                    <xsl:choose>
                      <!-- Watch out for the case where the F1 and corrected F2 obs can be effectively 360° apart - -->
                      <!-- occurs if the F1 obs is effectvely 0° and the corrected F2 obs ends up as 359°59'...     -->
                      <xsl:when test="(concat(substring('-',2 - (($F1Hz - $corrF2Hz) &lt; 0)), '1') * ($F1Hz - $corrF2Hz)) > 350.0">
                        <xsl:value-of select="($F1Hz + $corrF2Hz - 360.0) div 2"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="($F1Hz + $corrF2Hz) div 2"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$F1Hz"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <!-- Add the mean observation as an element -->
              <xsl:element name="meanHzObs">
                <xsl:value-of select="$meanHzObs"/>
              </xsl:element>

              <!-- Get the vertical obs data for each point in the round with the current name -->
              <xsl:variable name="F1VtObs">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="vtAngle"/>
                </xsl:for-each>
              </xsl:variable>
              <xsl:variable name="F2VtObs">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face2')][1]">
                  <xsl:value-of select="vtAngle"/>
                </xsl:for-each>
              </xsl:variable>
              <!-- Add the F1 and F2 Hz obs elements -->
              <xsl:element name="F1Vt">
                <xsl:value-of select="$F1VtObs"/>
              </xsl:element>
              <xsl:element name="F2Vt">
                <xsl:value-of select="$F2VtObs"/>
              </xsl:element>
              <!-- Add the V-Index (vertical error between faces) as an element -->
              <xsl:element name="VIndex">
                <xsl:value-of select="($F1VtObs + $F2VtObs - 360.0) div 2.0"/>
              </xsl:element>
              <!-- Add the mean vertical angle as an element -->
              <xsl:element name="meanVA">
                <xsl:choose>
                  <xsl:when test="(string(number($F1VtObs)) != 'NaN') and (string(number($F2VtObs)) = 'NaN')">  <!-- Null F2 vertical obs -->
                    <xsl:value-of select="$F1VtObs"/>  <!-- Just return F1 vertical obs -->
                  </xsl:when>
                  <xsl:when test="(string(number($F1VtObs)) = 'NaN') and (string(number($F2VtObs)) != 'NaN')">  <!-- Null F1 vertical obs -->
                    <xsl:value-of select="360.0 - $F2VtObs"/>  <!-- Just return F2 vertical obs presented as a F1 obs -->
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="($F1VtObs - $F2VtObs + 360.0) div 2.0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:element>

              <!-- Get the slope distance obs data for each point in the round with the current name -->
              <xsl:variable name="F1Dist">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="corrDistance"/>
                </xsl:for-each>
              </xsl:variable>
              <xsl:variable name="F2Dist">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face2')][1]">
                  <xsl:value-of select="corrDistance"/>
                </xsl:for-each>
              </xsl:variable>
              <!-- Add the F1 and F2 Hz dist elements -->
              <xsl:element name="F1Dist">
                <xsl:value-of select="$F1Dist"/>
              </xsl:element>
              <xsl:element name="F2Dist">
                <xsl:value-of select="$F2Dist"/>
              </xsl:element>
              <xsl:variable name="meanDist">
                <xsl:choose>
                  <xsl:when test="(string(number($F1Dist)) != 'NaN') and (string(number($F2Dist)) = 'NaN')">  <!-- Valid F1 dist, null F2 dist - return F1 dist  -->
                    <xsl:value-of select="$F1Dist"/>
                  </xsl:when>
                  <xsl:when test="(string(number($F1Dist)) = 'NaN') and (string(number($F2Dist)) != 'NaN')">  <!-- Null F1 dist, valid F2 dist - return F2 dist  -->
                    <xsl:value-of select="$F2Dist"/>
                  </xsl:when>
                  <xsl:otherwise> <!-- Both valid distances or both null (will return null in this case) -->
                    <xsl:value-of select="($F1Dist + $F2Dist) div 2.0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <!-- Add the mean distance as an element -->
              <xsl:element name="meanDist">
                <xsl:value-of select="$meanDist"/>
              </xsl:element>

              <!-- Add other data elements that will be needed for the Averaged Data Sets output -->
              <xsl:element name="Code">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="Code"/>
                </xsl:for-each>
              </xsl:element>
              <xsl:element name="tgtHt">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="tgtHt"/>
                </xsl:for-each>
              </xsl:element>
              <xsl:element name="prismConst">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="prismConst"/>
                </xsl:for-each>
              </xsl:element>
              <xsl:element name="Temperature">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="Temperature"/>
                </xsl:for-each>
              </xsl:element>
              <xsl:element name="Pressure">
                <xsl:for-each select="msxsl:node-set($dataInRound)/Point[(Name = $ptName) and (Face = 'Face1')][1]">
                  <xsl:value-of select="Pressure"/>
                </xsl:for-each>
              </xsl:element>

            </xsl:element>  <!-- Point element -->
          </xsl:for-each>
        </xsl:element>   <!-- Round element -->
      </xsl:if>
    </xsl:for-each>  <!-- following-sibling::* -->

  </xsl:variable>

  <!-- Create a node-set variable containing the means of all the rounds. -->
  <!-- Use all the round data to compute the mean obs to each point from  -->
  <!-- the mean obs in each round                                         -->
  <xsl:variable name="HorizMeanOfRounds">
    <xsl:variable name="firstPtName" select="msxsl:node-set($obsData)/Round[1]/Point[1]/Name"/>
    <xsl:variable name="corrnToZero" select="sum(msxsl:node-set($obsData)/Round/Point[Name = $firstPtName]/meanHzObs) div count(msxsl:node-set($obsData)/Round/Point[Name = $firstPtName])"/>
    <xsl:for-each select="msxsl:node-set($obsData)/Round[1]/Point">
      <xsl:variable name="ptName" select="Name"/>
      <xsl:element name="Point">
        <xsl:element name="Name">
          <xsl:value-of select="Name"/>
        </xsl:element>
        <xsl:variable name="roundsMeanHz">  <!-- Compute average of all rounds oriented zero to first point -->
          <xsl:variable name="tempMeanHz">
            <xsl:value-of select="sum(msxsl:node-set($obsData)/Round/Point[Name = $ptName]/meanHzObs) div count(msxsl:node-set($obsData)/Round/Point[Name = $ptName]) - $corrnToZero"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$tempMeanHz &lt; 0.0">
              <xsl:value-of select="$tempMeanHz + 360.0"/>
            </xsl:when>
            <xsl:when test="$tempMeanHz &gt; 360.0">
              <xsl:value-of select="$tempMeanHz - 360.0"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$tempMeanHz"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="roundsMeanHz">
          <xsl:value-of select="$roundsMeanHz"/>
        </xsl:element>
      </xsl:element>  <!-- Point element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Create a node-set variable containing all the differences between each oriented obs and the mean for all the rounds -->
  <xsl:variable name="HorizDiffsFromMeanPerRound">
    <xsl:variable name="firstPtName" select="msxsl:node-set($obsData)/Round[1]/Point[1]/Name"/>
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:variable name="corrnToZero" select="Point[Name = $firstPtName]/meanHzObs"/>
      <xsl:element name="Round">
        <xsl:for-each select="Point">
          <xsl:variable name="ptName" select="Name"/>
          <xsl:element name="Point">
            <xsl:element name="Name">
              <xsl:value-of select="Name"/>
            </xsl:element>
            <xsl:variable name="orientedHz">
              <xsl:variable name="tempHz">
                <xsl:value-of select="meanHzObs - $corrnToZero"/>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$tempHz &lt; 0.0">
                  <xsl:value-of select="$tempHz + 360.0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$tempHz"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:element name="orientedHz">
              <xsl:value-of select="$orientedHz"/>
            </xsl:element>
            <xsl:element name="hzDiff">
              <xsl:variable name="meanObs" select="msxsl:node-set($HorizMeanOfRounds)/Point[Name = $ptName]/roundsMeanHz"/>
              <xsl:choose>
                <!-- Watch out for the case where the roundsMeanHz and orientedHz obs can be effectively -->
                <!--  360° apart - occurs if one is effectvely 0° and the other ends up as 359°59'...    -->
                <xsl:when test="(concat(substring('-',2 - (($meanObs - $orientedHz) &lt; 0)), '1') * ($meanObs - $orientedHz)) > 350.0">
                  <xsl:value-of select="(concat(substring('-',2 - (($meanObs - $orientedHz) &lt; 0)), '1') * ($meanObs - $orientedHz)) - 360.0"/>
                </xsl:when>
                <xsl:when test="(string(number($meanObs)) = 'NaN') or (string(number($orientedHz)) = 'NaN')">
                  <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$meanObs - $orientedHz"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:element>
          </xsl:element>  <!-- Point element -->
        </xsl:for-each>
      </xsl:element>  <!-- Round element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Create a node set variable with all the residuals of the obs differences from the round mean difference -->
  <xsl:variable name="HorizResiduals">
    <xsl:for-each select="msxsl:node-set($HorizDiffsFromMeanPerRound)/Round">
      <xsl:variable name="meanDiffsForRound" select="sum(Point/hzDiff) div count(Point/hzDiff)"/>
      <xsl:element name="Round">
        <xsl:element name="meanDiffsForRound">
          <xsl:value-of select="$meanDiffsForRound"/>
        </xsl:element>
        <xsl:for-each select="Point">
          <xsl:variable name="ptName" select="Name"/>
          <xsl:element name="Point">
            <xsl:element name="Name">
              <xsl:value-of select="Name"/>
            </xsl:element>
            <xsl:element name="Residual">
              <xsl:value-of select="hzDiff - $meanDiffsForRound"/>
            </xsl:element>
            <xsl:element name="ResidualSquared">
              <xsl:value-of select="(hzDiff - $meanDiffsForRound) * (hzDiff - $meanDiffsForRound)"/>
            </xsl:element>
          </xsl:element>  <!-- Point element -->
        </xsl:for-each>
      </xsl:element>  <!-- Round element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Build up the special node-set variables required for the vertical angle output data -->

  <!-- Create a node-set variable containing the sums of the V-Indices per round -->
  <xsl:variable name="VIndexSums">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:element name="Round">
        <xsl:element name="VIndexSum">
          <xsl:value-of select="sum(Point/VIndex)"/>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>
  </xsl:variable>
    
  <!-- Create a node-set variable containing the means of all the rounds. -->
  <!-- Use all the round data to compute the mean obs to each point from  -->
  <!-- the mean obs in each round                                         -->
  <xsl:variable name="VertMeanOfRounds">
    <xsl:for-each select="msxsl:node-set($obsData)/Round[1]/Point">
      <xsl:variable name="ptName" select="Name"/>
      <xsl:element name="Point">
        <xsl:element name="Name">
          <xsl:value-of select="Name"/>
        </xsl:element>
        <xsl:element name="roundsMeanVt">  <!-- Compute average of all rounds -->
          <xsl:value-of select="sum(msxsl:node-set($obsData)/Round/Point[Name = $ptName]/meanVA) div count(msxsl:node-set($obsData)/Round/Point[Name = $ptName])"/>
        </xsl:element>
      </xsl:element>  <!-- Point element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Create a node-set variable containing all the residuals between each mean obs and the mean for all the rounds -->
  <xsl:variable name="VertResiduals">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:element name="Round">
        <xsl:for-each select="Point">
          <xsl:variable name="ptName" select="Name"/>
          <xsl:element name="Point">
            <xsl:element name="Name">
              <xsl:value-of select="Name"/>
            </xsl:element>
            <xsl:variable name="residual" select="msxsl:node-set($VertMeanOfRounds)/Point[Name = $ptName]/roundsMeanVt - meanVA"/>
            <xsl:element name="Residual">
              <xsl:value-of select="$residual"/>
            </xsl:element>
            <xsl:element name="ResidualSquared">
              <xsl:value-of select="$residual * $residual"/>
            </xsl:element>
          </xsl:element>  <!-- Point element -->
        </xsl:for-each>
      </xsl:element>  <!-- Round element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Now write the assembled vertical angle data out to the output tables -->
  <!-- <xsl:call-template name="OutputVertAngleTableData">
    <xsl:with-param name="stnName" select="$stnName"/>
    <xsl:with-param name="obsData" select="$obsData"/>
    <xsl:with-param name="VIndexSums" select="$VIndexSums"/>
    <xsl:with-param name="VertMeanOfRounds" select="$VertMeanOfRounds"/>
    <xsl:with-param name="VertResiduals" select="$VertResiduals"/>
  </xsl:call-template> -->

  <!-- Build up the special node-set variables required for the vertical angle output data -->

  <!-- Create a node-set variable containing the means of all the rounds. -->
  <!-- Use all the round data to compute the mean obs to each point from  -->
  <!-- the mean obs in each round                                         -->
  <xsl:variable name="DistMeanOfRounds">
    <xsl:for-each select="msxsl:node-set($obsData)/Round[1]/Point">
      <xsl:variable name="ptName" select="Name"/>
      <xsl:element name="Point">
        <xsl:element name="Name">
          <xsl:value-of select="Name"/>
        </xsl:element>
        <xsl:element name="roundsMeanDist">  <!-- Compute average of all rounds -->
          <xsl:value-of select="sum(msxsl:node-set($obsData)/Round/Point[Name = $ptName]/meanDist) div count(msxsl:node-set($obsData)/Round/Point[Name = $ptName])"/>
        </xsl:element>
      </xsl:element>  <!-- Point element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Create a node-set variable containing all the residuals between each mean obs and the mean for all the rounds -->
  <xsl:variable name="DistResiduals">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:element name="Round">
        <xsl:for-each select="Point">
          <xsl:variable name="ptName" select="Name"/>
          <xsl:element name="Point">
            <xsl:element name="Name">
              <xsl:value-of select="Name"/>
            </xsl:element>
            <xsl:variable name="F1Residual" select="msxsl:node-set($DistMeanOfRounds)/Point[Name = $ptName]/roundsMeanDist - F1Dist"/>
            <xsl:variable name="F2Residual" select="msxsl:node-set($DistMeanOfRounds)/Point[Name = $ptName]/roundsMeanDist - F2Dist"/>
            <xsl:element name="F1Residual">
              <xsl:value-of select="$F1Residual"/>
            </xsl:element>
            <xsl:element name="F2Residual">
              <xsl:value-of select="$F2Residual"/>
            </xsl:element>
            <xsl:element name="ResidualSquared">
              <xsl:choose>
                <xsl:when test="(string(number($F1Residual)) != 'NaN') and (string(number($F2Residual)) != 'NaN')">
                  <xsl:value-of select="$F1Residual * $F1Residual + $F2Residual * $F2Residual"/>
                </xsl:when>
                <xsl:when test="(string(number($F1Residual)) != 'NaN') and (string(number($F2Residual)) = 'NaN')">
                  <xsl:value-of select="$F1Residual * $F1Residual"/>
                </xsl:when>
                <xsl:when test="(string(number($F1Residual)) = 'NaN') and (string(number($F2Residual)) != 'NaN')">
                  <xsl:value-of select="$F2Residual * $F2Residual"/>
                </xsl:when>
              </xsl:choose>
            </xsl:element>
          </xsl:element>  <!-- Point element -->
        </xsl:for-each>
      </xsl:element>  <!-- Round element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- Create a node-set variable containing the standard deviations of the residuals for each point -->
  <xsl:variable name="DistStdDeviations">
    <xsl:for-each select="msxsl:node-set($obsData)/Round[1]/Point">
      <xsl:variable name="ptName" select="Name"/>
      <xsl:element name="Point">
        <xsl:element name="Name">
          <xsl:value-of select="Name"/>
        </xsl:element>
        <xsl:variable name="nbrRounds" select="count(msxsl:node-set($obsData)/Round)"/>
        <xsl:variable name="sqrtNbrRounds">
          <xsl:call-template name="Sqrt">
            <xsl:with-param name="num" select="$nbrRounds"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="sumPointSrqdResiduals" select="sum(msxsl:node-set($DistResiduals)/Round/Point[Name = $ptName]/ResidualSquared)"/>
        <!-- Set up a variable so that the standard deviation of a distance is computed    -->
        <!-- appropriately depending on whether or not it is single face only measurement. -->
        <xsl:variable name="singleFaceDists">
          <xsl:choose>
            <xsl:when test="(string(number(sum(msxsl:node-set($DistResiduals)/Round/Point[Name = $ptName]/F1Residual))) = 'NaN') or
                            (string(number(sum(msxsl:node-set($DistResiduals)/Round/Point[Name = $ptName]/F2Residual))) = 'NaN')">
              <xsl:value-of select="1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="2"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stdDeviation">
          <xsl:call-template name="Sqrt">
            <xsl:with-param name="num" select="$sumPointSrqdResiduals div ($singleFaceDists * $nbrRounds - 1)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:element name="stdDeviation">
          <xsl:value-of select="$stdDeviation"/>
        </xsl:element>
        <xsl:element name="stdDeviationMean">
          <xsl:value-of select="$stdDeviation div $sqrtNbrRounds"/>
        </xsl:element>
      </xsl:element>  <!-- Point element -->
    </xsl:for-each>
  </xsl:variable>

  <!-- <xsl:call-template name="OutputDistanceTableData">
    <xsl:with-param name="stnName" select="$stnName"/>
    <xsl:with-param name="obsData" select="$obsData"/>
    <xsl:with-param name="DistMeanOfRounds" select="$DistMeanOfRounds"/>
    <xsl:with-param name="DistResiduals" select="$DistResiduals"/>
    <xsl:with-param name="DistStdDeviations" select="$DistStdDeviations"/>
  </xsl:call-template> -->

  <!-- Compute the azimuth to the first observed point in the first round -->
    <xsl:variable name="firstObsPt" select="msxsl:node-set($DistMeanOfRounds)/Point[1]/Name"/>
    <xsl:variable name="azToFirstPt">
      <xsl:call-template name="AzimuthBetweenPoints">
        <xsl:with-param name="fromPt" select="$stnName"/>
        <xsl:with-param name="toPt" select="$firstObsPt"/>
      </xsl:call-template>
    </xsl:variable>


    <xsl:variable name="numPoints" select="count(msxsl:node-set($HorizMeanOfRounds)/Point)"/>

    <xsl:variable name="BacksightPoint" select="msxsl:node-set($DistMeanOfRounds)/Point[1]/Name"/>

    <xsl:for-each select="msxsl:node-set($HorizMeanOfRounds)/Point">
      <xsl:variable name="i" select="position()"/>
      <!--BS is first obs, last obs is FS and everything in between is an IS-->
      <xsl:variable name="obsType">
        <xsl:choose>
          <xsl:when test="$i = 1">
            <xsl:value-of select="'BS'"/>
          </xsl:when>
          <xsl:when test="$i = $numPoints">
            <xsl:value-of select="'FS'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'IS'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="ptName" select="Name"/>

      <xsl:element name="StnPoint">
        <xsl:element name="stnPoint">
          <xsl:copy-of select="concat($stnName, '-', $ptName)"/>
        </xsl:element>

        <xsl:element name="stnName">
          <xsl:copy-of select="$stnName"/>
        </xsl:element>

        <xsl:element name="backsightPoint">
          <xsl:copy-of select="$BacksightPoint"/>
        </xsl:element>

        <xsl:element name="pointName">
          <xsl:copy-of select="$ptName"/>
        </xsl:element>
    
        <xsl:element name="obsType">
          <xsl:copy-of select="$obsType"/>
        </xsl:element>
        
        <xsl:element name="VD">
          <xsl:variable name="cosVA">
            <xsl:call-template name="Cosine">
              <xsl:with-param name="theAngle" select="msxsl:node-set($VertMeanOfRounds)/Point[Name = $ptName]/roundsMeanVt * $Pi div 180.0"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="rawVD" select="$cosVA * msxsl:node-set($DistMeanOfRounds)/Point[Name = $ptName]/roundsMeanDist"/>
          <xsl:variable name="tgtHt" select="msxsl:node-set($obsData)/Round[1]/Point[Name = $ptName]/tgtHt"/>
          <xsl:copy-of select="format-number(($rawVD + $instHt - $tgtHt) * $DistConvFactor, $DecPl4, 'Standard')"/>
        </xsl:element>

        <xsl:element name="SD">
          <xsl:value-of select="format-number(msxsl:node-set($DistMeanOfRounds)/Point[Name = $ptName]/roundsMeanDist * $DistConvFactor, $DecPl4, 'Standard')"/>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>


</xsl:template>


<!-- **************************************************************** -->
<!-- ************** Output Horizontal Angle Table Data ************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputHorizAngleTableData">
  <xsl:param name="stnName"/>
  <xsl:param name="obsData"/>
  <xsl:param name="HorizMeanOfRounds"/>
  <xsl:param name="HorizDiffsFromMeanPerRound"/>
  <xsl:param name="HorizResiduals"/>

  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">1. Horizontal Angles</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">true</xsl:with-param>
  </xsl:call-template>

    <!-- Write out the horizontal angle table headings -->
    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val1">1</xsl:with-param>
      <xsl:with-param name="val2">2</xsl:with-param>
      <xsl:with-param name="val3">3</xsl:with-param>
      <xsl:with-param name="val4">4</xsl:with-param>
      <xsl:with-param name="val5">5</xsl:with-param>
      <xsl:with-param name="val6">6</xsl:with-param>
      <xsl:with-param name="val7">7</xsl:with-param>
      <xsl:with-param name="val8">8</xsl:with-param>
      <xsl:with-param name="val9">9</xsl:with-param>
      <xsl:with-param name="val10">10</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val1">Station</xsl:with-param>
      <xsl:with-param name="val2">Target</xsl:with-param>
      <xsl:with-param name="val3">Face 1</xsl:with-param>
      <xsl:with-param name="val4">Face 2</xsl:with-param>
      <xsl:with-param name="val5">Mean L1+L2</xsl:with-param>
      <xsl:with-param name="val6">Mean Reduced</xsl:with-param>
      <xsl:with-param name="val7">Mean out of all sets</xsl:with-param>
      <xsl:with-param name="val8">Diff.(D)</xsl:with-param>
      <xsl:with-param name="val9">Res.(R)</xsl:with-param>
      <xsl:with-param name="val10">R&#0178;</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val3"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val4"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val5"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val6"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val7"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val8">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil</xsl:when>
          <xsl:otherwise>sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val9">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil</xsl:when>
          <xsl:otherwise>sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val10">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon&#0178;</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil&#0178;</xsl:when>
          <xsl:otherwise>sec&#0178;</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <!-- Output all the passed in round horizontal angle data (in node-set variables) -->
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:variable name="thisRound" select="position()"/>
      <xsl:variable name="corrnToZero" select="Point[1]/meanHzObs"/>

      <xsl:for-each select="Point">
        <xsl:variable name="ptName" select="Name"/>
        <xsl:call-template name="OutputTenElementTableLine">
          <xsl:with-param name="val1">  <!-- Station point name - only output on first line of table -->
            <xsl:choose>
              <xsl:when test="(position() = 1) and ($thisRound = 1)">
                <xsl:value-of select="$stnName"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val2" select="Name"/>  <!-- Observed point name -->

          <xsl:with-param name="val3">  <!-- Face 1 horizontal angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="F1Hz"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val4">  <!-- Face 2 horizontal angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="F2Hz"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val5">  <!-- Unoriented Face 1/Face 2 mean horizontal angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="meanHzObs"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val6">  <!-- Face 1/Face 2 mean horizontal angle oriented 0 to first point observed -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle">
                <xsl:call-template name="NormalisedAngle">
                  <xsl:with-param name="angle" select="msxsl:node-set($HorizDiffsFromMeanPerRound)/Round[$thisRound]/Point[Name = $ptName]/orientedHz"/>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val7">  <!-- Mean of all rounds - only output for first round -->
            <xsl:choose>
              <xsl:when test="$thisRound = 1">
                <xsl:call-template name="FormatAngle">
                  <xsl:with-param name="theAngle" select="msxsl:node-set($HorizMeanOfRounds)/Point[Name = $ptName]/roundsMeanHz"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val8">  <!-- Difference between the oriented mean observation and the mean of all the rounds -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="msxsl:node-set($HorizDiffsFromMeanPerRound)/Round[$thisRound]/Point[Name = $ptName]/hzDiff"/>
              <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val9">  <!-- Observation residual from the mean of the round differences from the mean of all the roundss -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="msxsl:node-set($HorizResiduals)/Round[$thisRound]/Point[Name = $ptName]/Residual"/>
              <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val10">  <!-- Square of observation residual from the mean of the round differences from the mean of all the roundss -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="msxsl:node-set($HorizResiduals)/Round[$thisRound]/Point[Name = $ptName]/ResidualSquared"/>
              <xsl:with-param name="outputAsMilligonsOrSecsSqrd">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:for-each>  <!-- Point element -->

      <xsl:call-template name="OutputTenElementTableLine">  <!-- Output the mean diffs for the round at the end of the round output -->
        <xsl:with-param name="val8">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="msxsl:node-set($HorizResiduals)/Round[$thisRound]/meanDiffsForRound"/>
            <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>

      <xsl:choose>
        <xsl:when test="position() != last()">
          <xsl:call-template name="OutputTenElementTableLine"/>  <!-- Output an empty line to separate rounds -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="OutputTenElementTableLine">
            <xsl:with-param name="val1">Sum</xsl:with-param>
            <xsl:with-param name="val9">
              <xsl:call-template name="FormatAngle">
                <xsl:with-param name="theAngle" select="sum(msxsl:node-set($HorizResiduals)/Round/Point/Residual)"/>
                <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
              </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="val10">
              <xsl:call-template name="FormatAngle">
                <xsl:with-param name="theAngle" select="sum(msxsl:node-set($HorizResiduals)/Round/Point/ResidualSquared)"/>
                <xsl:with-param name="outputAsMilligonsOrSecsSqrd">true</xsl:with-param>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:for-each>  <!-- Round element -->

  <xsl:call-template name="EndTable"/>

  <xsl:call-template name="BlankLine"/>

  <!-- Carry out a check to ensure that F1/F2 obs have been made to all the points -->
  <xsl:variable name="completeF1F2HzObs">
    <xsl:call-template name="HasCompleteF1F2HzObs">
      <xsl:with-param name="obsData" select="$obsData"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- Carry out a check to ensure that observations have been made to all the points in all the rounds -->
  <xsl:variable name="matchingHzRounds">
    <xsl:call-template name="HasMatchingRounds">
      <xsl:with-param name="obsData" select="$obsData"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="($completeF1F2HzObs != 'true') or ($matchingHzRounds != 'true')">
    <!-- Write out a warning message indicating that a complete set of observations was not available -->
    <xsl:call-template name="Heading2">
      <xsl:with-param name="text">Note: The measuring procedure did not follow the rules of the DIN/ISO standards:</xsl:with-param>
    </xsl:call-template>

    <ul><b>
      <xsl:if test="$completeF1F2HzObs != 'true'">
        <li>All points have not been observed on both faces.</li>
      </xsl:if>
      <xsl:if test="$matchingHzRounds != 'true'">
        <li>All points have not been observed in all rounds.</li>
      </xsl:if>
    </b></ul>

    <xsl:call-template name="Heading2">
      <xsl:with-param name="text">The error calculation may not give the correct results</xsl:with-param>
    </xsl:call-template>
  </xsl:if>

  <!-- Now output the stats values following the main table -->
  <xsl:variable name="nbrOfSets" select="count(msxsl:node-set($obsData)/Round)"/>
  <xsl:variable name="nbrOfDegOfFreedom" select="($nbrOfSets - 1) * (count(msxsl:node-set($obsData)/Round[1]/Point) - 1)"/>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="65"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of sets</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfSets"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of targets</xsl:with-param>
      <xsl:with-param name="val" select="count(msxsl:node-set($obsData)/Round[1]/Point)"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of degrees of freedom</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfDegOfFreedom"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <!-- Include blank line in table -->
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'&#0160;'"/>
    </xsl:call-template>

    <xsl:variable name="stdDeviationOfDirn">
      <xsl:call-template name="Sqrt">
        <xsl:with-param name="num" select="sum(msxsl:node-set($HorizResiduals)/Round/Point/ResidualSquared) div $nbrOfDegOfFreedom"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Std.Dev. of a direction measured in both faces</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$stdDeviationOfDirn"/>
          <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'"> mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'"> mils</xsl:when>
          <xsl:otherwise> sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">
        <xsl:text>Std.Dev. of a direction averaged over </xsl:text>
        <xsl:value-of select="$nbrOfSets"/>
        <xsl:text> sets</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="val">
        <xsl:variable name="sqrtNbrSets">
          <xsl:call-template name="Sqrt">
            <xsl:with-param name="num" select="$nbrOfSets"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$stdDeviationOfDirn div $sqrtNbrSets"/>
          <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'"> mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'"> mils</xsl:when>
          <xsl:otherwise> sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- *************** Output Vertical Angle Table Data *************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputVertAngleTableData">
  <xsl:param name="stnName"/>
  <xsl:param name="obsData"/>
  <xsl:param name="VIndexSums"/>
  <xsl:param name="VertMeanOfRounds"/>
  <xsl:param name="VertResiduals"/>

  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">2. Vertical Angles</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">true</xsl:with-param>
  </xsl:call-template>

    <!-- Write out the vertical angle table headings -->
    <xsl:call-template name="OutputNineElementTableLine">
      <xsl:with-param name="val1">1</xsl:with-param>
      <xsl:with-param name="val2">2</xsl:with-param>
      <xsl:with-param name="val3">3</xsl:with-param>
      <xsl:with-param name="val4">4</xsl:with-param>
      <xsl:with-param name="val5">5</xsl:with-param>
      <xsl:with-param name="val6">6</xsl:with-param>
      <xsl:with-param name="val7">7</xsl:with-param>
      <xsl:with-param name="val8">8</xsl:with-param>
      <xsl:with-param name="val9">9</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputNineElementTableLine">
      <xsl:with-param name="val1">Station</xsl:with-param>
      <xsl:with-param name="val2">Target</xsl:with-param>
      <xsl:with-param name="val3">Face 1</xsl:with-param>
      <xsl:with-param name="val4">Face 2</xsl:with-param>
      <xsl:with-param name="val5">V-Index</xsl:with-param>
      <xsl:with-param name="val6">Mean L1+L2</xsl:with-param>
      <xsl:with-param name="val7">Mean out of all sets</xsl:with-param>
      <xsl:with-param name="val8">Res.(R)</xsl:with-param>
      <xsl:with-param name="val9">R&#0178;</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputNineElementTableLine">
      <xsl:with-param name="val3"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val4"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val5">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil</xsl:when>
          <xsl:otherwise>sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val6"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val7"><xsl:value-of select="$AngleUnitStr"/></xsl:with-param>
      <xsl:with-param name="val8">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil</xsl:when>
          <xsl:otherwise>sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="val9">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'">mgon&#0178;</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">mil&#0178;</xsl:when>
          <xsl:otherwise>sec&#0178;</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <!-- Output all the passed in round vertical angle data (in node-set variables) -->
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:variable name="thisRound" select="position()"/>

      <xsl:for-each select="Point">
        <xsl:variable name="ptName" select="Name"/>
        <xsl:call-template name="OutputNineElementTableLine">
          <xsl:with-param name="val1">  <!-- Station point name - only output on first line of table -->
            <xsl:choose>
              <xsl:when test="(position() = 1) and ($thisRound = 1)">
                <xsl:value-of select="$stnName"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val2" select="Name"/>  <!-- Observed point name -->

          <xsl:with-param name="val3">  <!-- Face 1 vertical angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="F1Vt"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val4">  <!-- Face 2 vertical angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="F2Vt"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val5">  <!-- V-Index value -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="VIndex"/>
              <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val6">  <!-- Mean vertical angle -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="meanVA"/>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val7">  <!-- Mean of all rounds - only output for first round -->
            <xsl:choose>
              <xsl:when test="$thisRound = 1">
                <xsl:call-template name="FormatAngle">
                  <xsl:with-param name="theAngle" select="msxsl:node-set($VertMeanOfRounds)/Point[Name = $ptName]/roundsMeanVt"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val8">  <!-- Residual between the mean observation and the mean of all the rounds -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="msxsl:node-set($VertResiduals)/Round[$thisRound]/Point[Name = $ptName]/Residual"/>
              <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

          <xsl:with-param name="val9">  <!-- The square of the residual between the mean observation and the mean of all the rounds -->
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="msxsl:node-set($VertResiduals)/Round[$thisRound]/Point[Name = $ptName]/ResidualSquared"/>
              <xsl:with-param name="outputAsMilligonsOrSecsSqrd">true</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>

        </xsl:call-template>

      </xsl:for-each>  <!-- Point element -->

      <xsl:call-template name="OutputNineElementTableLine">  <!-- Output the sum of the V_Indices for the round at the end of the round output -->

        <xsl:with-param name="val5">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="msxsl:node-set($VIndexSums)/Round[$thisRound]/VIndexSum"/>
            <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
          </xsl:call-template>
        </xsl:with-param>

      </xsl:call-template>

      <xsl:choose>
        <xsl:when test="position() != last()">
          <xsl:call-template name="OutputNineElementTableLine"/>  <!-- Output an empty line to separate rounds -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="OutputNineElementTableLine">
            <xsl:with-param name="val1">Sum</xsl:with-param>

            <xsl:with-param name="val8">
              <xsl:call-template name="FormatAngle">
                <xsl:with-param name="theAngle" select="sum(msxsl:node-set($VertResiduals)/Round/Point/Residual)"/>
                <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
              </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="val9">
              <xsl:call-template name="FormatAngle">
                <xsl:with-param name="theAngle" select="sum(msxsl:node-set($VertResiduals)/Round/Point/ResidualSquared)"/>
                <xsl:with-param name="outputAsMilligonsOrSecsSqrd">true</xsl:with-param>
              </xsl:call-template>
            </xsl:with-param>

          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:for-each>  <!-- Round element -->

  <xsl:call-template name="EndTable"/>

  <xsl:call-template name="BlankLine"/>

  <!-- Carry out a check to ensure that F1/F2 obs have been made to all the points -->
  <xsl:variable name="completeF1F2VtObs">
    <xsl:call-template name="HasCompleteF1F2VtObs">
      <xsl:with-param name="obsData" select="$obsData"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- Carry out a check to ensure that observations have been made to all the points in all the rounds -->
  <xsl:variable name="matchingVtRounds">
    <xsl:call-template name="HasMatchingRounds">
      <xsl:with-param name="obsData" select="$obsData"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="($completeF1F2VtObs != 'true') or ($matchingVtRounds != 'true')">
    <!-- Write out a warning message indicating that a complete set of observations was not available -->
    <xsl:call-template name="Heading2">
      <xsl:with-param name="text">Note: The measuring procedure did not follow the rules of the DIN/ISO standards:</xsl:with-param>
    </xsl:call-template>

    <ul><b>
      <xsl:if test="$completeF1F2VtObs != 'true'">
        <li>All points have not been observed on both faces.</li>
      </xsl:if>
      <xsl:if test="$matchingVtRounds != 'true'">
        <li>All points have not been observed in all rounds.</li>
      </xsl:if>
    </b></ul>

    <xsl:call-template name="Heading2">
      <xsl:with-param name="text">The error calculation may not give the correct results</xsl:with-param>
    </xsl:call-template>
  </xsl:if>

  <!-- Now output the stats values following the main table -->
  <xsl:variable name="nbrOfSets" select="count(msxsl:node-set($obsData)/Round)"/>
  <xsl:variable name="nbrOfDegOfFreedom" select="($nbrOfSets - 1) * count(msxsl:node-set($obsData)/Round[1]/Point)"/>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="65"/>
  </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Mean Index Correction</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="sum(msxsl:node-set($VIndexSums)/Round/VIndexSum) div count(msxsl:node-set($obsData)/Round/Point)"/>
          <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'"> mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'"> mils</xsl:when>
          <xsl:otherwise> sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <!-- Include blank line in table -->
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'&#0160;'"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of sets</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfSets"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of targets</xsl:with-param>
      <xsl:with-param name="val" select="count(msxsl:node-set($obsData)/Round[1]/Point)"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of degrees of freedom</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfDegOfFreedom"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <!-- Include blank line in table -->
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'&#0160;'"/>
    </xsl:call-template>

    <xsl:variable name="stdDeviationOfVA">
      <xsl:call-template name="Sqrt">
        <xsl:with-param name="num" select="sum(msxsl:node-set($VertResiduals)/Round/Point/ResidualSquared) div $nbrOfDegOfFreedom"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Std.Dev. of a vertical angle measured in both faces</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$stdDeviationOfVA"/>
          <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'"> mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'"> mils</xsl:when>
          <xsl:otherwise> sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">
        <xsl:text>Std.Dev. of a vertical angle averaged over </xsl:text>
        <xsl:value-of select="$nbrOfSets"/>
        <xsl:text> sets</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="val">
        <xsl:variable name="sqrtNbrSets">
          <xsl:call-template name="Sqrt">
            <xsl:with-param name="num" select="$nbrOfSets"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="FormatAngle">
          <xsl:with-param name="theAngle" select="$stdDeviationOfVA div $sqrtNbrSets"/>
          <xsl:with-param name="outputAsMilligonsOrSecs">true</xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'Gons'"> mgon</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'"> mils</xsl:when>
          <xsl:otherwise> sec</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>
  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ****************** Output Distance Table Data ****************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputDistanceTableData">
  <xsl:param name="stnName"/>
  <xsl:param name="obsData"/>
  <xsl:param name="DistMeanOfRounds"/>
  <xsl:param name="DistResiduals"/>
  <xsl:param name="DistStdDeviations"/>

  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">3. Distances</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">true</xsl:with-param>
  </xsl:call-template>

    <!-- Write out the distance table headings -->
    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val1">1</xsl:with-param>
      <xsl:with-param name="val2">2</xsl:with-param>
      <xsl:with-param name="val3">3</xsl:with-param>
      <xsl:with-param name="val4">4</xsl:with-param>
      <xsl:with-param name="val5">5</xsl:with-param>
      <xsl:with-param name="val6">6</xsl:with-param>
      <xsl:with-param name="val7">7</xsl:with-param>
      <xsl:with-param name="val8">8</xsl:with-param>
      <xsl:with-param name="val9">9</xsl:with-param>
      <xsl:with-param name="val10">10</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val1">Station</xsl:with-param>
      <xsl:with-param name="val2">Target</xsl:with-param>
      <xsl:with-param name="val3">Face 1</xsl:with-param>
      <xsl:with-param name="val4">Face 2</xsl:with-param>
      <xsl:with-param name="val5">Mean out of all sets</xsl:with-param>
      <xsl:with-param name="val6">Res.(R1)</xsl:with-param>
      <xsl:with-param name="val7">Res.(R2)</xsl:with-param>
      <xsl:with-param name="val8">Sum (R&#0178;)</xsl:with-param>
      <xsl:with-param name="val9">Std.Dev</xsl:with-param>
      <xsl:with-param name="val10">Std.Dev. Mean</xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <xsl:variable name="fracDistStr">
      <xsl:choose>
        <xsl:when test="$DistUnit = 'Metres'">mm</xsl:when>
        <xsl:otherwise>ft/1000</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="OutputTenElementTableLine">
      <xsl:with-param name="val3"><xsl:value-of select="$DistUnitStr"/></xsl:with-param>
      <xsl:with-param name="val4"><xsl:value-of select="$DistUnitStr"/></xsl:with-param>
      <xsl:with-param name="val5"><xsl:value-of select="$DistUnitStr"/></xsl:with-param>
      <xsl:with-param name="val6"><xsl:value-of select="$fracDistStr"/></xsl:with-param>
      <xsl:with-param name="val7"><xsl:value-of select="$fracDistStr"/></xsl:with-param>
      <xsl:with-param name="val8"><xsl:value-of select="concat($fracDistStr, '&#0178;')"/></xsl:with-param>
      <xsl:with-param name="val9"><xsl:value-of select="$fracDistStr"/></xsl:with-param>
      <xsl:with-param name="val10"><xsl:value-of select="$fracDistStr"/></xsl:with-param>
      <xsl:with-param name="centre">true</xsl:with-param>
    </xsl:call-template>

    <!-- Output all the passed in round horizontal angle data (in node-set variables) -->
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:variable name="thisRound" select="position()"/>

      <xsl:for-each select="Point">
        <xsl:variable name="ptName" select="Name"/>
        <xsl:call-template name="OutputTenElementTableLine">
          <xsl:with-param name="val1">  <!-- Station point name - only output on first line of table -->
            <xsl:choose>
              <xsl:when test="(position() = 1) and ($thisRound = 1)">
                <xsl:value-of select="$stnName"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val2" select="Name"/>  <!-- Observed point name -->

          <!-- Face 1 distance -->
          <xsl:with-param name="val3" select="format-number(F1Dist * $DistConvFactor, $DecPl4, 'Standard')"/>

          <!-- Face 2 distance -->
          <xsl:with-param name="val4" select="format-number(F2Dist * $DistConvFactor, $DecPl4, 'Standard')"/>

          <xsl:with-param name="val5">  <!-- Mean of all rounds - only output for first round -->
            <xsl:choose>
              <xsl:when test="$thisRound = 1">
                <xsl:value-of select="format-number(msxsl:node-set($DistMeanOfRounds)/Point[Name = $ptName]/roundsMeanDist * $DistConvFactor, $DecPl4, 'Standard')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val6">  <!-- F1 Distance residual from the mean of all the roundss -->
            <xsl:value-of select="format-number(msxsl:node-set($DistResiduals)/Round[$thisRound]/Point[Name = $ptName]/F1Residual * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
          </xsl:with-param>

          <xsl:with-param name="val7">  <!-- F2 Distance residual from the mean of all the roundss -->
            <xsl:value-of select="format-number(msxsl:node-set($DistResiduals)/Round[$thisRound]/Point[Name = $ptName]/F2Residual * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
          </xsl:with-param>

          <xsl:with-param name="val8">  <!-- Distance residual squared -->
            <xsl:value-of select="format-number(msxsl:node-set($DistResiduals)/Round[$thisRound]/Point[Name = $ptName]/ResidualSquared * $DistConvFactor * $DistConvFactor * 1000.0 * 1000.0, $DecPl2, 'Standard')"/>
          </xsl:with-param>

          <xsl:with-param name="val9">  <!-- Standard deviations - only output for first round -->
            <xsl:choose>
              <xsl:when test="$thisRound = 1">
                <xsl:value-of select="format-number(msxsl:node-set($DistStdDeviations)/Point[Name = $ptName]/stdDeviation * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

          <xsl:with-param name="val10">  <!-- Standard deviations mean - only output for first round -->
            <xsl:choose>
              <xsl:when test="$thisRound = 1">
                <xsl:value-of select="format-number(msxsl:node-set($DistStdDeviations)/Point[Name = $ptName]/stdDeviationMean * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'&#0160;'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
        
      </xsl:for-each>  <!-- Point element -->

      <xsl:choose>
        <xsl:when test="position() != last()">
          <xsl:call-template name="OutputTenElementTableLine"/>  <!-- Output an empty line to separate rounds -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="OutputTenElementTableLine">
            <xsl:with-param name="val1">Sum</xsl:with-param>
            <xsl:with-param name="val6" select="format-number(sum(msxsl:node-set($DistResiduals)/Round/Point/F1Residual) * $DistConvFactor * 1000.0, $DecPl2, 'Standard')"/>
            <xsl:with-param name="val7" select="format-number(sum(msxsl:node-set($DistResiduals)/Round/Point/F2Residual) * $DistConvFactor * 1000.0, $DecPl2, 'Standard')"/>
            <xsl:with-param name="val8" select="format-number(sum(msxsl:node-set($DistResiduals)/Round/Point/ResidualSquared) * $DistConvFactor * $DistConvFactor * 1000.0 * 1000.0, $DecPl2, 'Standard')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:for-each>  <!-- Round element -->

  <xsl:call-template name="EndTable"/>

  <xsl:call-template name="BlankLine"/>

  <!-- Now output the stats values following the main table -->
  <xsl:variable name="nbrOfSets" select="count(msxsl:node-set($obsData)/Round)"/>
  <xsl:variable name="nbrOfTargets" select="count(msxsl:node-set($obsData)/Round[1]/Point)"/>
  <xsl:variable name="nbrOfDegOfFreedom" select="$nbrOfSets * 2 - 1"/>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="65"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of sets</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfSets"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of targets</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfTargets"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Number of degrees of freedom</xsl:with-param>
      <xsl:with-param name="val" select="$nbrOfDegOfFreedom"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <!-- Include blank line in table -->
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'&#0160;'"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'Std. Dev. of a distance measured in 1 face - see column 9 above'"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'Std. Dev. of the mean of all sets - see column 10 above'"/>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <!-- Include blank line in table -->
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'&#0160;'"/>
    </xsl:call-template>

    <xsl:variable name="checkForNonNullF1Residuals">
      <xsl:value-of select="count(msxsl:node-set($DistResiduals)/Round/Point[string(number(F1Residual)) != 'NaN'])"/>
    </xsl:variable>

    <xsl:variable name="checkForNonNullF2Residuals">
      <xsl:value-of select="count(msxsl:node-set($DistResiduals)/Round/Point[string(number(F2Residual)) != 'NaN'])"/>
    </xsl:variable>

    <xsl:variable name="singleFaceWarning">
      <xsl:if test="($checkForNonNullF1Residuals = 0) or ($checkForNonNullF2Residuals = 0)">
        <xsl:text> (Single face only)</xsl:text>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="denominator">
      <xsl:choose>
        <xsl:when test="$singleFaceWarning = ''">  <!-- Distances measured on both faces -->
          <xsl:value-of select="2.0 * $nbrOfSets * $nbrOfTargets - $nbrOfTargets"/>
        </xsl:when>
        <xsl:otherwise>                            <!-- Distances measured on single face -->
          <xsl:value-of select="$nbrOfSets * $nbrOfTargets - 1.0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="stdDeviationAllDists">
      <xsl:call-template name="Sqrt">
        <xsl:with-param name="num" select="sum(msxsl:node-set($DistResiduals)/Round/Point/ResidualSquared) div $denominator"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">
        <xsl:text>Std. Dev. for all distances (1 obs only)</xsl:text>
        <xsl:value-of select="$singleFaceWarning"/>
      </xsl:with-param>
      <xsl:with-param name="val">
        <xsl:value-of select="format-number($stdDeviationAllDists * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
        <xsl:choose>
          <xsl:when test="$DistUnit = 'Metres'"> mm</xsl:when>
          <xsl:otherwise> ft/1000</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">
        <xsl:text>Std. Dev. for all distances (mean)</xsl:text>
        <xsl:value-of select="$singleFaceWarning"/>
      </xsl:with-param>
      <xsl:with-param name="val">
        <xsl:variable name="sqrtNbrSets">
          <xsl:call-template name="Sqrt">
            <xsl:with-param name="num" select="$nbrOfSets"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="format-number($stdDeviationAllDists div $sqrtNbrSets * $DistConvFactor * 1000.0, $DecPl1, 'Standard')"/>
        <xsl:choose>
          <xsl:when test="$DistUnit = 'Metres'"> mm</xsl:when>
          <xsl:otherwise> ft/1000</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="largePrompt">true</xsl:with-param>
    </xsl:call-template>

  <xsl:call-template name="EndTable"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************** Output the Averaged Data Set Tables ************* -->
<!-- **************************************************************** -->
<xsl:template name="OutputAveragedDataSets">
  <xsl:param name="stnName"/>
  <xsl:param name="instHt"/>
  <xsl:param name="obsData"/>
  <xsl:param name="HorizMeanOfRounds"/>
  <xsl:param name="VertMeanOfRounds"/>
  <xsl:param name="DistMeanOfRounds"/>



    
</xsl:template>



<!-- **************************************************************** -->
<!-- ********** Check for Complete Set of F1 & F2 Horiz Obs ********* -->
<!-- **************************************************************** -->
<xsl:template name="HasCompleteF1F2HzObs">
  <xsl:param name="obsData"/>
  
  <xsl:variable name="flag">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:for-each select="Point">
        <xsl:if test="(string(number(F1Hz)) = 'NaN') or (string(number(F2Hz)) = 'NaN')">1</xsl:if>  <!-- One of the values is null -->
      </xsl:for-each>
    </xsl:for-each>
  </xsl:variable>

  <xsl:value-of select="$flag = ''"/>  <!-- The $flag variable will be empty if there are no null obs -->
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Check for Matching Points in Each Round *********** -->
<!-- **************************************************************** -->
<xsl:template name="HasMatchingRounds">
  <xsl:param name="obsData"/>

  <xsl:variable name="flag">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:variable name="roundNameMatch">
        <xsl:for-each select="Point">  <!-- Select each point in the round -->
          <xsl:variable name="name" select="Name"/>
            <xsl:for-each select="msxsl:node-set($obsData)/Round[1]/Point">
              <xsl:if test="$name = Name">1</xsl:if>  <!-- If point name compares with a point name in the first round add a 1 -->
            </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="(string-length($roundNameMatch) != count(Point)) or
                    (string-length($roundNameMatch) != count(msxsl:node-set($obsData)/Round[1]/Point))">1</xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <xsl:value-of select="$flag = ''"/>  <!-- The $flag variable will be empty if there are no mismatched rounds -->
</xsl:template>


<!-- **************************************************************** -->
<!-- ********* Check for Complete Set of F1 & F2 Vertical Obs ******* -->
<!-- **************************************************************** -->
<xsl:template name="HasCompleteF1F2VtObs">
  <xsl:param name="obsData"/>

  <xsl:variable name="flag">
    <xsl:for-each select="msxsl:node-set($obsData)/Round">
      <xsl:for-each select="Point">
        <xsl:if test="(string(number(F1Vt)) = 'NaN') or (string(number(F2Vt)) = 'NaN')">1</xsl:if>  <!-- One of the values is null -->
      </xsl:for-each>
    </xsl:for-each>
  </xsl:variable>

  <xsl:value-of select="$flag = ''"/>  <!-- The $flag variable will be empty if there are no null obs -->
</xsl:template>


<!-- **************************************************************** -->
<!-- ******** Return the Azimuth Between Two Specified Points ******* -->
<!-- **************************************************************** -->
<xsl:template name="AzimuthBetweenPoints">
  <xsl:param name="fromPt"/>
  <xsl:param name="toPt"/>

  <!-- Get the coordinates of the specified points from the Reductions section -->
  <xsl:variable name="fromPtN">
    <xsl:for-each select="key('reducedPt-search', $fromPt)">
      <xsl:value-of select="Grid/North"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="fromPtE">
    <xsl:for-each select="key('reducedPt-search', $fromPt)">
      <xsl:value-of select="Grid/East"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="toPtN">
    <xsl:for-each select="key('reducedPt-search', $toPt)">
      <xsl:value-of select="Grid/North"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="toPtE">
    <xsl:for-each select="key('reducedPt-search', $toPt)">
      <xsl:value-of select="Grid/East"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:call-template name="InverseAzimuth">
    <xsl:with-param name="deltaN" select="$toPtN - $fromPtN"/>
    <xsl:with-param name="deltaE" select="$toPtE - $fromPtE"/>
  </xsl:call-template>
</xsl:template>


<!-- **************************************************************** -->
<!-- ****** Get the Instrument Make from First InstrumentRecord ***** -->
<!-- **************************************************************** -->
<xsl:template name="GetInstMake">
  <xsl:variable name="instType" select="/JOBFile/FieldBook/InstrumentRecord[1]/Type"/>

  <xsl:choose>
    <xsl:when test="contains($instType, 'Trimble')">
      <xsl:value-of select="'Trimble'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'SET')">
      <xsl:value-of select="'Sokkia'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Geodimeter')">
      <xsl:value-of select="'Geodimeter'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Leica')">
      <xsl:value-of select="'Leica'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Nikon')">
      <xsl:value-of select="'Nikon'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Pentax')">
      <xsl:value-of select="'Pentax'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Topcon')">
      <xsl:value-of select="'Topcon'"/>
    </xsl:when>
    <xsl:when test="contains($instType, 'Zeiss')">
      <xsl:value-of select="'Zeiss'"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="'Unknown'"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******** Return Computed Residual Along Observation Line ******* -->
<!-- **************************************************************** -->
<xsl:template name="ResidualAlongObsLine">
  <xsl:param name="stnName"/>
  <xsl:param name="ptName"/>
  <xsl:param name="resDeltaN"/>
  <xsl:param name="resDeltaE"/>

  <xsl:variable name="obsAzimuth">
    <xsl:call-template name="AzimuthBetweenPoints">
      <xsl:with-param name="fromPt" select="$stnName"/>
      <xsl:with-param name="toPt" select="$ptName"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="resAzimuth">
    <xsl:call-template name="InverseAzimuth">
      <xsl:with-param name="deltaN" select="$resDeltaN"/>
      <xsl:with-param name="deltaE" select="$resDeltaE"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="resDist">
    <xsl:call-template name="Sqrt">
      <xsl:with-param name="num" select="$resDeltaN * $resDeltaN + $resDeltaE * $resDeltaE"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="cosDeltaAngle">
    <xsl:call-template name="Cosine">
      <xsl:with-param name="theAngle" select="($obsAzimuth - $resAzimuth) * $Pi div 180.0"/>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:value-of select="$resDist * $cosDeltaAngle"/>
  
</xsl:template>


<!-- **************************************************************** -->
<!-- *** Return Computed Residual Orthogonal to Observation Line **** -->
<!-- **************************************************************** -->
<xsl:template name="ResidualOrthogonalToObsLine">
  <xsl:param name="stnName"/>
  <xsl:param name="ptName"/>
  <xsl:param name="resDeltaN"/>
  <xsl:param name="resDeltaE"/>

  <xsl:variable name="obsAzimuth">
    <xsl:call-template name="AzimuthBetweenPoints">
      <xsl:with-param name="fromPt" select="$stnName"/>
      <xsl:with-param name="toPt" select="$ptName"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="resAzimuth">
    <xsl:call-template name="InverseAzimuth">
      <xsl:with-param name="deltaN" select="$resDeltaN"/>
      <xsl:with-param name="deltaE" select="$resDeltaE"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="resDist">
    <xsl:call-template name="Sqrt">
      <xsl:with-param name="num" select="$resDeltaN * $resDeltaN + $resDeltaE * $resDeltaE"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="sinDeltaAngle">
    <xsl:call-template name="Sine">
      <xsl:with-param name="theAngle" select="($obsAzimuth - $resAzimuth) * $Pi div 180.0"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:value-of select="$resDist * $sinDeltaAngle"/>

</xsl:template>


<!-- **************************************************************** -->
<!-- *********** Return Temperature Value in Correct Units ********** -->
<!-- **************************************************************** -->
<xsl:template name="TemperatureValue">
  <xsl:param name="temperature"/>

  <xsl:choose>
    <xsl:when test="$TempUnit = 'Celsius'">
      <xsl:value-of select="$temperature"/>  <!-- Simply return the passed in value -->
    </xsl:when>
    <xsl:otherwise>  <!-- Must need output in Fahrenheit units -->
      <xsl:value-of select="$temperature * 1.8 + 32"/>  <!-- Convert to Fahrenheit -->
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ****************** Separating Line Output ********************** -->
<!-- **************************************************************** -->
<xsl:template name="SeparatingLine">
  <hr/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********************* Blank Line Output ************************ -->
<!-- **************************************************************** -->
<xsl:template name="BlankLine">
  <xsl:value-of select="' '"/>
  <BR/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************************* Start Table ************************** -->
<!-- **************************************************************** -->
<xsl:template name="StartTable">
  <xsl:param name="includeBorders" select="'true'"/>
  <xsl:param name="tableWidth" select="100"/>
  <xsl:param name="Id" select="'id'"/>

  <xsl:choose>
    <xsl:when test="$includeBorders = 'true'">
      <xsl:value-of disable-output-escaping="yes" select="concat('&lt;table id=&quot;', $Id, '&quot; class=&quot;border&quot; width=&quot;', $tableWidth, '%&quot; cellpadding=&quot;2&quot; rules=&quot;all&quot;&gt;')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of disable-output-escaping="yes" select="concat('&lt;table id=&quot;', $Id, '&quot; class=&quot;noBorder&quot; width=&quot;', $tableWidth, '%&quot; cellpadding=&quot;2&quot; rules=&quot;none&quot;&gt;')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************************** End Table *************************** -->
<!-- **************************************************************** -->
<xsl:template name="EndTable">
  <xsl:value-of disable-output-escaping="yes" select="'&lt;/table&gt;'"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Output One Element Table Line **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputOneElementTableLine">
  <xsl:param name="hdr" select="''"/>
  <xsl:param name="val" select="''"/>
  <xsl:param name="largePrompt" select="'false'"/>

  <xsl:choose>
    <xsl:when test="$largePrompt = 'true'">  <!-- Change prompt/value proportions -->
      <tr>
        <th width="70%" align="left"><xsl:value-of select="$hdr"/></th>
        <td width="30%" align="right"><xsl:value-of select="$val"/></td>
      </tr>
    </xsl:when>
    <xsl:otherwise>
      <tr>
        <th width="50%" align="left"><xsl:value-of select="$hdr"/></th>
        <td width="50%" align="right"><xsl:value-of select="$val"/></td>
      </tr>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Output Two Element Table Line **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputTwoElementTableLine">
  <xsl:param name="hdr1" select="''"/>
  <xsl:param name="val1" select="''"/>
  <xsl:param name="hdr2" select="''"/>
  <xsl:param name="val2" select="''"/>

  <tr>
    <th width="20%" align="left"><xsl:value-of select="$hdr1"/></th>
    <td width="30%" align="left"><xsl:value-of select="$val1"/></td>
    <th width="20%" align="left"><xsl:value-of select="$hdr2"/></th>
    <td width="30%" align="left"><xsl:value-of select="$val2"/></td>
  </tr>

</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Output Four Element Table Line *************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputFourElementTableLine">
  <xsl:param name="val1" select="''"/>
  <xsl:param name="val2" select="''"/>
  <xsl:param name="val3" select="''"/>
  <xsl:param name="val4" select="''"/>
  <xsl:param name="bold" select="'false'"/>

  <tr>
    <xsl:choose>
      <xsl:when test="$bold = 'true'">
        <th width="25%" align="right"><xsl:value-of select="$val1"/></th>
        <th width="25%" align="right"><xsl:value-of select="$val2"/></th>
        <th width="25%" align="right"><xsl:value-of select="$val3"/></th>
        <th width="25%" align="right"><xsl:value-of select="$val4"/></th>
      </xsl:when>
      <xsl:otherwise>
        <td width="25%" align="right"><xsl:value-of select="$val1"/></td>
        <td width="25%" align="right"><xsl:value-of select="$val2"/></td>
        <td width="25%" align="right"><xsl:value-of select="$val3"/></td>
        <td width="25%" align="right"><xsl:value-of select="$val4"/></td>
      </xsl:otherwise>
    </xsl:choose>
  </tr>

</xsl:template>

<!-- **************************************************************** -->
<!-- **************** Output Seven Element Table Line *************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputSevenElementTableLine">
  <xsl:param name="val1" select="''"/>
  <xsl:param name="val2" select="''"/>
  <xsl:param name="val3" select="''"/>
  <xsl:param name="val4" select="''"/>
  <xsl:param name="val5" select="''"/>
  <xsl:param name="val6" select="''"/>
  <xsl:param name="val7" select="''"/>
  <xsl:param name="bold" select="'false'"/>
  <xsl:param name="boldVal1" select="'false'"/>
  <xsl:param name="boldVal6" select="'false'"/>

  <tr>
    <xsl:choose>
      <xsl:when test="$bold = 'true'">
        <th width="14%" align="right"><xsl:value-of select="$val1"/></th>
        <th width="14%" align="right"><xsl:value-of select="$val2"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val3"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val4"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val5"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val6"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val7"/></th>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$boldVal1 = 'true'">
            <th width="14%" align="right"><xsl:value-of select="$val1"/></th>
          </xsl:when>
          <xsl:otherwise>
            <td width="14%" align="right"><xsl:value-of select="$val1"/></td>
          </xsl:otherwise>
        </xsl:choose>
        <td width="14%" align="right"><xsl:value-of select="$val2"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val3"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val4"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val5"/></td>
        <xsl:choose>
          <xsl:when test="$boldVal6 = 'true'">
            <th width="12%" align="right"><xsl:value-of select="$val6"/></th>
          </xsl:when>
          <xsl:otherwise>
            <td width="12%" align="right"><xsl:value-of select="$val6"/></td>
          </xsl:otherwise>
        </xsl:choose>
        <td width="12%" align="right"><xsl:value-of select="$val7"/></td>
      </xsl:otherwise>
    </xsl:choose>
  </tr>

</xsl:template>


<!-- **************************************************************** -->
<!-- **************** Output Eight Element Table Line *************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputEightElementTableLine">
  <xsl:param name="val1" select="''"/>
  <xsl:param name="val2" select="''"/>
  <xsl:param name="val3" select="''"/>
  <xsl:param name="val4" select="''"/>
  <xsl:param name="val5" select="''"/>
  <xsl:param name="val6" select="''"/>
  <xsl:param name="val7" select="''"/>
  <xsl:param name="val8" select="''"/>
  <xsl:param name="bold" select="'false'"/>
  <xsl:param name="boldVal1" select="'false'"/>
  <xsl:param name="boldVal6" select="'false'"/>

  <tr>
    <xsl:choose>
      <xsl:when test="$bold = 'true'">
        <th width="14%" align="right"><xsl:value-of select="$val1"/></th>
        <th width="14%" align="right"><xsl:value-of select="$val2"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val3"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val4"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val5"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val6"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val7"/></th>
        <th width="12%" align="right"><xsl:value-of select="$val8"/></th>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$boldVal1 = 'true'">
            <th width="14%" align="right"><xsl:value-of select="$val1"/></th>
          </xsl:when>
          <xsl:otherwise>
            <td width="14%" align="right"><xsl:value-of select="$val1"/></td>
          </xsl:otherwise>
        </xsl:choose>
        <td width="14%" align="right"><xsl:value-of select="$val2"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val3"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val4"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val5"/></td>
        <xsl:choose>
          <xsl:when test="$boldVal6 = 'true'">
            <th width="12%" align="right"><xsl:value-of select="$val6"/></th>
          </xsl:when>
          <xsl:otherwise>
            <td width="12%" align="right"><xsl:value-of select="$val6"/></td>
          </xsl:otherwise>
        </xsl:choose>
        <td width="12%" align="right"><xsl:value-of select="$val7"/></td>
        <td width="12%" align="right"><xsl:value-of select="$val8"/></td>
      </xsl:otherwise>
    </xsl:choose>
  </tr>

</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Output Ten Element Table Line **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputTenElementTableLine">
  <xsl:param name="val1" select="'&#0160;'"/> <!-- Default to non-breaking space to force border lines to show in all cases -->
  <xsl:param name="val2" select="'&#0160;'"/>
  <xsl:param name="val3" select="'&#0160;'"/>
  <xsl:param name="val4" select="'&#0160;'"/>
  <xsl:param name="val5" select="'&#0160;'"/>
  <xsl:param name="val6" select="'&#0160;'"/>
  <xsl:param name="val7" select="'&#0160;'"/>
  <xsl:param name="val8" select="'&#0160;'"/>
  <xsl:param name="val9" select="'&#0160;'"/>
  <xsl:param name="val10" select="'&#0160;'"/>
  <xsl:param name="centre" select="'false'"/>

  <xsl:choose>
    <xsl:when test="$centre = 'true'">
      <tr>
        <td width="11%" align="center"><xsl:value-of select="$val1"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val2"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val3"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val4"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val5"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val6"/></td>
        <td width="11%" align="center"><xsl:value-of select="$val7"/></td>
        <td width="7%" align="center"><xsl:value-of select="$val8"/></td>
        <td width="7%" align="center"><xsl:value-of select="$val9"/></td>
        <td width="9%" align="center"><xsl:value-of select="$val10"/></td>
      </tr>
    </xsl:when>
    <xsl:otherwise>
      <tr>
        <td width="11%" align="right"><xsl:value-of select="$val1"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val2"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val3"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val4"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val5"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val6"/></td>
        <td width="11%" align="right"><xsl:value-of select="$val7"/></td>
        <td width="7%" align="right"><xsl:value-of select="$val8"/></td>
        <td width="7%" align="right"><xsl:value-of select="$val9"/></td>
        <td width="9%" align="right"><xsl:value-of select="$val10"/></td>
      </tr>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<!-- **************************************************************** -->
<!-- **************** Output Nine Element Table Line **************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputNineElementTableLine">
  <xsl:param name="val1" select="'&#0160;'"/> <!-- Default to non-breaking space to force border lines to show in all cases -->
  <xsl:param name="val2" select="'&#0160;'"/>
  <xsl:param name="val3" select="'&#0160;'"/>
  <xsl:param name="val4" select="'&#0160;'"/>
  <xsl:param name="val5" select="'&#0160;'"/>
  <xsl:param name="val6" select="'&#0160;'"/>
  <xsl:param name="val7" select="'&#0160;'"/>
  <xsl:param name="val8" select="'&#0160;'"/>
  <xsl:param name="val9" select="'&#0160;'"/>
  <xsl:param name="centre" select="'false'"/>
  <xsl:param name="bold" select="'false'"/>

  <xsl:variable name="justify">
    <xsl:choose>
      <xsl:when test="$centre = 'true'">center</xsl:when>
      <xsl:otherwise>right</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="cellType">
    <xsl:choose>
      <xsl:when test="$bold = 'true'">th</xsl:when>
      <xsl:otherwise>td</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">11%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val1"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">11%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val2"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">12%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val3"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">12%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val4"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">9%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val5"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">12%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val6"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">12%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val7"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">9%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val8"/>
    </xsl:element>
    <xsl:element name="{$cellType}">  <!-- <th> or <td> -->
      <xsl:attribute name="width">12%</xsl:attribute>
      <xsl:attribute name="align"><xsl:value-of select="$justify"/></xsl:attribute>
      <xsl:value-of select="$val9"/>
    </xsl:element>
  </tr>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Output a Level 1 Heading ******************* -->
<!-- **************************************************************** -->
<xsl:template name="Heading1">
  <xsl:param name="text" select="''"/>

  <p><font size="+1"><b><xsl:value-of select="$text"/></b></font></p>

</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Output a Level 1 Heading ******************* -->
<!-- **************************************************************** -->
<xsl:template name="Heading2">
  <xsl:param name="text" select="''"/>

  <p><b><xsl:value-of select="$text"/></b></p>

</xsl:template>


<!-- **************************************************************** -->
<!-- ************** Convert a F2 Horiz Obs to a F1 Obs ************** -->
<!-- **************************************************************** -->
<xsl:template name="HzConvertToF1Obs">
  <xsl:param name="F2Obs"/>
  
  <xsl:if test="string(number($F2Obs)) != 'NaN'">
    <xsl:variable name="rawF1" select="$F2Obs - 180.0"/>

    <xsl:choose>
      <xsl:when test="$rawF1 &lt; 0">
        <xsl:value-of select="$rawF1 + 360.0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$rawF1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>

</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Output Angle in Appropriate Format **************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatAngle">
  <xsl:param name="theAngle"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="DMSOutput" select="'false'"/>  <!-- Can be used to force DMS output -->
  <xsl:param name="useSymbols" select="'true'"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="gonsDecPlaces" select="5"/>    <!-- Decimal places for gons output -->
  <xsl:param name="decDegDecPlaces" select="5"/>  <!-- Decimal places for decimal degrees output -->
  <xsl:param name="outputAsMilligonsOrSecs" select="'false'"/>
  <xsl:param name="outputAsMilligonsOrSecsSqrd" select="'false'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:variable name="gonsDecPl">
    <xsl:choose>
      <xsl:when test="$gonsDecPlaces = 1"><xsl:value-of select="$DecPl1"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 2"><xsl:value-of select="$DecPl2"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 3"><xsl:value-of select="$DecPl3"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 4"><xsl:value-of select="$DecPl4"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 5"><xsl:value-of select="$DecPl5"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 6"><xsl:value-of select="$DecPl6"/></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="decDegDecPl">
    <xsl:choose>
      <xsl:when test="$decDegDecPlaces = 1"><xsl:value-of select="$DecPl1"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 2"><xsl:value-of select="$DecPl2"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 3"><xsl:value-of select="$DecPl3"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 4"><xsl:value-of select="$DecPl4"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 5"><xsl:value-of select="$DecPl5"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 6"><xsl:value-of select="$DecPl6"/></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <!-- Null angle value -->
    <xsl:when test="string(number($theAngle))='NaN'">
      <xsl:value-of select="format-number($theAngle, $DecPl3, 'Standard')"/> <!-- Use the defined null format output -->
    </xsl:when>
    <!-- There is an angle value -->
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="($AngleUnit = 'DMSDegrees') or not($DMSOutput = 'false')">
          <xsl:choose>
            <xsl:when test="$outputAsMilligonsOrSecs != 'false'">
              <xsl:variable name="decPlFmt">
                <xsl:choose>
                  <xsl:when test="$secDecPlaces = 1"><xsl:value-of select="'00.0'"/></xsl:when>
                  <xsl:when test="$secDecPlaces = 2"><xsl:value-of select="'00.00'"/></xsl:when>
                  <xsl:when test="$secDecPlaces = 3"><xsl:value-of select="'00.000'"/></xsl:when>
                  <xsl:when test="$secDecPlaces = 4"><xsl:value-of select="'00.0000'"/></xsl:when>
                  <xsl:when test="$secDecPlaces = 5"><xsl:value-of select="'00.00000'"/></xsl:when>
                  <xsl:when test="$secDecPlaces = 6"><xsl:value-of select="'00.000000'"/></xsl:when>
                  <xsl:otherwise><xsl:value-of select="'00.0'"/></xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 3600.0, $decPlFmt, 'Standard')"/>
            </xsl:when>            
            <xsl:when test="$outputAsMilligonsOrSecsSqrd != 'false'">
              <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 3600.0 * 3600.0, '00.000', 'Standard')"/>
            </xsl:when>            
            <xsl:otherwise>
              <xsl:call-template name="FormatDMSAngle">
                <xsl:with-param name="decimalAngle" select="$theAngle"/>
                <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
                <xsl:with-param name="useSymbols" select="$useSymbols"/>
                <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
                <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>  
        </xsl:when>

        <xsl:otherwise>
          <xsl:variable name="fmtAngle">
            <xsl:choose>
              <xsl:when test="($AngleUnit = 'Gons') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$outputAsMilligonsOrSecs != 'false'">
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 1000.0, $DecPl2, 'Standard')"/>
                  </xsl:when>
                  <xsl:when test="$outputAsMilligonsOrSecsSqrd != 'false'">
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 1000.0 * 1000.0, $DecPl4, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                        <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl8, 'Standard')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $gonsDecPl, 'Standard')"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <xsl:when test="($AngleUnit = 'Mils') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl6, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl4, 'Standard')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <xsl:when test="($AngleUnit = 'DecimalDegrees') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl8, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $decDegDecPl, 'Standard')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          
          <xsl:choose>
            <xsl:when test="$impliedDecimalPt != 'true'">
              <xsl:value-of select="$fmtAngle"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="translate($fmtAngle, '.', '')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Output Azimuth in Appropriate Format ************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatAzimuth">
  <xsl:param name="theAzimuth"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="DMSOutput" select="'false'"/>  <!-- Can be used to force DMS output -->
  <xsl:param name="useSymbols" select="'true'"/>
  <xsl:param name="quadrantBearings" select="'false'"/>  <!-- Can be used to force quadrant bearing output -->
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="northLbl" select="'N'"/>
  <xsl:param name="eastLbl" select="'E'"/>
  <xsl:param name="southLbl" select="'S'"/>
  <xsl:param name="westLbl" select="'W'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:choose>
    <xsl:when test="(/JOBFile/Environment/DisplaySettings/AzimuthFormat = 'QuadrantBearings') or ($quadrantBearings != 'false')">
      <xsl:call-template name="FormatQuadrantBearing">
        <xsl:with-param name="decimalAngle" select="$theAzimuth"/>
        <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
        <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
        <xsl:with-param name="northLbl" select="$northLbl"/>
        <xsl:with-param name="eastLbl" select="$eastLbl"/>
        <xsl:with-param name="southLbl" select="$southLbl"/>
        <xsl:with-param name="westLbl" select="$westLbl"/>
        <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="FormatAngle">
        <xsl:with-param name="theAngle" select="$theAzimuth"/>
        <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
        <xsl:with-param name="DMSOutput" select="$DMSOutput"/>
        <xsl:with-param name="useSymbols" select="$useSymbols"/>
        <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
        <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********* Format latitude or Longitude in DMS Format *********** -->
<!-- **************************************************************** -->
<xsl:template name="FormatLatLong">
  <xsl:param name="theAngle"/>
  <xsl:param name="isLat" select="'true'"/>
  <xsl:param name="secDecPlaces" select="5"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="northLbl" select="'N'"/>
  <xsl:param name="eastLbl" select="'E'"/>
  <xsl:param name="southLbl" select="'S'"/>
  <xsl:param name="westLbl" select="'W'"/>
  <xsl:param name="leadingLabel" select="'false'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>
  <xsl:param name="decimalDegrees" select="'false'"/>

  <xsl:choose>
    <!-- Null angle value -->
    <xsl:when test="string(number($theAngle)) = 'NaN'">
      <xsl:value-of select="format-number($theAngle, $DecPl3, 'Standard')"/> <!-- Use the defined null format output -->
    </xsl:when>
    <!-- There is a lat or long value -->
    <xsl:otherwise>
      <xsl:variable name="sign">
        <xsl:choose>
          <xsl:when test="$theAngle &lt; '0.0'">
            <xsl:choose>  <!-- Negative value -->
              <xsl:when test="$isLat = 'true'"><xsl:value-of select="$southLbl"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="$westLbl"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise> <!-- Positive value -->
            <xsl:choose>
              <xsl:when test="$isLat = 'true'"><xsl:value-of select="$northLbl"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="$eastLbl"/></xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Convert to a positive angle before changing to DMS format -->
      <xsl:variable name="posAngle" select="concat(substring('-',2 - ($theAngle &lt; 0)), '1') * $theAngle"/>

      <xsl:variable name="latLongAngle">
        <xsl:choose>
          <xsl:when test="$decimalDegrees = 'false'">
            <xsl:call-template name="FormatDMSAngle">
              <xsl:with-param name="decimalAngle" select="$posAngle"/>
              <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
              <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
              <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>  <!-- Output as decimal degrees to 8 decimal places -->
            <xsl:value-of select="format-number($posAngle, $DecPl8, 'Standard')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="$leadingLabel = 'false'">
          <xsl:value-of select="concat($latLongAngle, $sign)"/>
        </xsl:when>
        <xsl:otherwise>  <!-- Trailing label -->
          <xsl:value-of select="concat($sign, $latLongAngle)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- *************** Return the square root of a value ************** -->
<!-- **************************************************************** -->
<xsl:template name="Sqrt">
  <xsl:param name="num" select="0"/>       <!-- The number you want to find the square root of -->
  <xsl:param name="try" select="1"/>       <!-- The current 'try'.  This is used internally. -->
  <xsl:param name="iter" select="1"/>      <!-- The current iteration, checked against maxiter to limit loop count - used internally -->
  <xsl:param name="maxiter" select="40"/>  <!-- Set this up to insure against infinite loops - used internally -->

  <!-- This template uses Sir Isaac Newton's method of finding roots -->

  <xsl:choose>
    <xsl:when test="$num &lt; 0"></xsl:when>  <!-- Invalid input - no square root of a negative number so return null -->
    <xsl:when test="$try * $try = $num or $iter &gt; $maxiter">
      <xsl:value-of select="$try"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="Sqrt">
        <xsl:with-param name="num" select="$num"/>
        <xsl:with-param name="try" select="$try - (($try * $try - $num) div (2 * $try))"/>
        <xsl:with-param name="iter" select="$iter + 1"/>
        <xsl:with-param name="maxiter" select="$maxiter"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ***** Return Angle between 0 and 360 or -180 to 180 degrees **** -->
<!-- **************************************************************** -->
<xsl:template name="NormalisedAngle">
  <xsl:param name="angle"/>
  <xsl:param name="plusMinus180" select="'false'"/>

  <xsl:variable name="fullCircleAngle">
    <xsl:choose>
      <xsl:when test="$angle &lt; 0">
        <xsl:variable name="newAngle">
          <xsl:value-of select="$angle + 360.0"/>
        </xsl:variable>
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="$newAngle"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="$angle &gt;= 360.0">
        <xsl:variable name="newAngle">
          <xsl:value-of select="$angle - 360.0"/>
        </xsl:variable>
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="$newAngle"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="$angle"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$plusMinus180 = 'false'">
      <xsl:value-of select="$fullCircleAngle"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$fullCircleAngle &lt;= 180.0">
          <xsl:value-of select="$fullCircleAngle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$fullCircleAngle - 360.0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Compute Inverse Azimuth ******************** -->
<!-- **************************************************************** -->
<xsl:template name="InverseAzimuth">
  <xsl:param name="deltaN"/>
  <xsl:param name="deltaE"/>
  <xsl:param name="returnInRadians" select="'false'"/>

  <!-- Compute the inverse azimuth from the deltas -->
  <xsl:variable name="absDeltaN" select="concat(substring('-',2 - ($deltaN &lt; 0)), '1') * $deltaN"/>
  <xsl:variable name="absDeltaE" select="concat(substring('-',2 - ($deltaE &lt; 0)), '1') * $deltaE"/>

  <xsl:variable name="flag">
    <xsl:choose>
      <xsl:when test="$absDeltaE &gt; $absDeltaN">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="adjDeltaN">
    <xsl:choose>
      <xsl:when test="$flag"><xsl:value-of select="$absDeltaE"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$absDeltaN"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="adjDeltaE">
    <xsl:choose>
      <xsl:when test="$flag"><xsl:value-of select="$absDeltaN"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$absDeltaE"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Compute the raw angle value -->
  <xsl:variable name="angle">
    <xsl:choose>
      <xsl:when test="$adjDeltaN &lt; 0.000001">
        <xsl:value-of select="0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="arcTanAngle">
          <xsl:call-template name="ArcTanSeries">
            <xsl:with-param name="tanVal" select="$adjDeltaE div $adjDeltaN"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$flag">
            <xsl:value-of select="$halfPi - $arcTanAngle"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$arcTanAngle"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Assemble the raw angle value into an azimuth -->
  <xsl:variable name="azimuth">
    <xsl:choose>
      <xsl:when test="$deltaE &lt; 0">
        <xsl:choose>
          <xsl:when test="$deltaN &lt; 0">
            <xsl:value-of select="$Pi + $angle"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$Pi * 2 - $angle"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$deltaN &lt; 0">
            <xsl:value-of select="$Pi - $angle"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$angle"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Return the azimuth value in radians or decimal degrees as requested -->
  <xsl:choose>
    <xsl:when test="$returnInRadians = 'true'">
      <xsl:value-of select="$azimuth"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$azimuth * 180 div $Pi"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Return the sine of an angle in radians ************ -->
<!-- **************************************************************** -->
<xsl:template name="Sine">
  <xsl:param name="theAngle"/>
  <xsl:variable name="normalisedAngle">
    <xsl:call-template name="RadianAngleBetweenLimits">
      <xsl:with-param name="anAngle" select="$theAngle"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="theSine">
    <xsl:call-template name="sineIter">
      <xsl:with-param name="pX2" select="$normalisedAngle * $normalisedAngle"/>
      <xsl:with-param name="pRslt" select="$normalisedAngle"/>
      <xsl:with-param name="pElem" select="$normalisedAngle"/>
      <xsl:with-param name="pN" select="1"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:value-of select="number($theSine)"/>
</xsl:template>

<xsl:template name="sineIter">
  <xsl:param name="pX2"/>
  <xsl:param name="pRslt"/>
  <xsl:param name="pElem"/>
  <xsl:param name="pN"/>
  <xsl:param name="pEps" select="0.00000001"/>
  <xsl:variable name="vnextN" select="$pN+2"/>
  <xsl:variable name="vnewElem"  select="-$pElem*$pX2 div ($vnextN*($vnextN - 1))"/>
  <xsl:variable name="vnewResult" select="$pRslt + $vnewElem"/>
  <xsl:variable name="vdiffResult" select="$vnewResult - $pRslt"/>
  <xsl:choose>
    <xsl:when test="$vdiffResult > $pEps or $vdiffResult &lt; -$pEps">
      <xsl:call-template name="sineIter">
        <xsl:with-param name="pX2" select="$pX2"/>
        <xsl:with-param name="pRslt" select="$vnewResult"/>
        <xsl:with-param name="pElem" select="$vnewElem"/>
        <xsl:with-param name="pN" select="$vnextN"/>
        <xsl:with-param name="pEps" select="$pEps"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$vnewResult"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- *********** Return the Cosine of an angle in radians *********** -->
<!-- **************************************************************** -->
<xsl:template name="Cosine">
  <xsl:param name="theAngle"/>

  <!-- Use the sine function after subtracting the angle from halfPi -->
  <xsl:call-template name="Sine">
    <xsl:with-param name="theAngle" select="$halfPi - $theAngle"/>
  </xsl:call-template>
</xsl:template>


<!-- **************************************************************** -->
<!-- ***************** Apply Corrections To Distance **************** -->
<!-- **************************************************************** -->
<xsl:template name="CorrectedDistance">
  <xsl:param name="slopeDist"/>
  <xsl:param name="prismConst" select="0"/>
  <xsl:param name="atmosPPM" select="0"/>
  <xsl:param name="stationScaleFactor" select="1.0"/>
  <xsl:param name="vertAngle" select="90.0"/>
  <xsl:param name="applyPrismConst" select="'true'"/>
  <xsl:param name="applyPPM" select="'true'"/>
  <xsl:param name="applyStationSF" select="'true'"/>

  <!-- All the distances in the JobXML file are raw distances so apply the current     -->
  <!-- prism constant atmospheric correction and station scale factor to the distance. -->
  <xsl:variable name="currPrismConst">
    <xsl:choose>
      <xsl:when test="($applyPrismConst = 'true') and (string(number($prismConst)) != 'NaN')">
        <xsl:value-of select="$prismConst"/>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="currAtmosPPM">
    <xsl:choose>
      <xsl:when test="($applyPPM = 'true') and (string(number($atmosPPM)) != 'NaN')">
        <xsl:value-of select="$atmosPPM"/>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Apply the atmospheric ppm and prism constant distance corrections -->
  <xsl:variable name="atmosAndPrismConstCorrSlopeDist" select="$slopeDist + $currPrismConst + ($currAtmosPPM div 1000000.0 * $slopeDist)"/>
  
  <xsl:choose>
    <xsl:when test="($applyStationSF = 'true') and (string(number($stationScaleFactor)) != 'NaN') and
                    (string(number($vertAngle)) != 'NaN')">
      <!-- The station scale factor should only be applied to the horizontal component -->
      <!-- of the distance so compute the correction based on the horizontal distance  -->
      <!-- so it can be applied later.                                                 -->
      <xsl:variable name="sinVA">
        <xsl:call-template name="Sine">
          <xsl:with-param name="theAngle" select="$vertAngle * $Pi div 180.0"/>
        </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="cosVA">
        <xsl:call-template name="Cosine">
          <xsl:with-param name="theAngle" select="$vertAngle * $Pi div 180.0"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="hzDist" select="$slopeDist * $sinVA * $stationScaleFactor"/> <!-- Apply station scale factor to horizontal component -->
      <xsl:variable name="vtDist" select="$slopeDist * $cosVA"/>
      <!-- Now recombine the horizontal and vertical components into the resultant slope distance using Pythagoras -->
      <xsl:variable name="newSD">
        <xsl:call-template name="Sqrt">
          <xsl:with-param name="num" select="($hzDist * $hzDist) + ($vtDist * $vtDist)"/>
        </xsl:call-template>
      </xsl:variable>

      <!-- Apply the atmospheric ppm and prism constant corrections to the scale corrected slope distance -->
      <xsl:value-of select="$newSD + $currPrismConst + ($currAtmosPPM div 1000000.0 * $newSD)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$atmosAndPrismConstCorrSlopeDist"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********************** Format a DMS Angle ********************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatDMSAngle">
  <xsl:param name="decimalAngle"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="useSymbols" select="'true'"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:variable name="degreesSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 1, 1)"/></xsl:when>  <!-- Degrees symbol ° -->
      <xsl:otherwise>
        <xsl:if test="$impliedDecimalPt != 'true'">.</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="minutesSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 2, 1)"/></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="secondsSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 3, 1)"/></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="sign">
    <xsl:if test="$decimalAngle &lt; '0.0'">-1</xsl:if>
    <xsl:if test="$decimalAngle &gt;= '0.0'">1</xsl:if>
  </xsl:variable>

  <xsl:variable name="posDecimalDegrees" select="number($decimalAngle * $sign)"/>

  <xsl:variable name="positiveDecimalDegrees">  <!-- Ensure an angle very close to 360° is treated as 0° -->
    <xsl:choose>
      <xsl:when test="(360.0 - $posDecimalDegrees) &lt; 0.00001">
        <xsl:value-of select="0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$posDecimalDegrees"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="decPlFmt">
    <xsl:choose>
      <xsl:when test="$secDecPlaces = 0"><xsl:value-of select="''"/></xsl:when>
      <xsl:when test="$secDecPlaces = 1"><xsl:value-of select="'.0'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 2"><xsl:value-of select="'.00'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 3"><xsl:value-of select="'.000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 4"><xsl:value-of select="'.0000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 5"><xsl:value-of select="'.00000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 6"><xsl:value-of select="'.000000'"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="degrees" select="floor($positiveDecimalDegrees)"/>
  <xsl:variable name="decimalMinutes" select="number(number($positiveDecimalDegrees - $degrees) * 60 )"/>
  <xsl:variable name="minutes" select="floor($decimalMinutes)"/>
  <xsl:variable name="seconds" select="number(number($decimalMinutes - $minutes)*60)"/>

  <xsl:variable name="partiallyNormalisedMinutes">
    <xsl:if test="number(format-number($seconds, concat('00', $decPlFmt))) = 60"><xsl:value-of select="number($minutes + 1)"/></xsl:if>
    <xsl:if test="not(number(format-number($seconds, concat('00', $decPlFmt))) = 60)"><xsl:value-of select="$minutes"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedSeconds">
    <xsl:if test="number(format-number($seconds, concat('00', $decPlFmt))) = 60"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(number(format-number($seconds, concat('00', $decPlFmt))) = 60)"><xsl:value-of select="$seconds"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="partiallyNormalisedDegrees">
    <xsl:if test="format-number($partiallyNormalisedMinutes, '0') = '60'"><xsl:value-of select="number($degrees + 1)"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedMinutes, '0') = '60')"><xsl:value-of select="$degrees"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedDegrees">
    <xsl:if test="format-number($partiallyNormalisedDegrees, '0') = '360'"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedDegrees, '0') = '360')"><xsl:value-of select="$partiallyNormalisedDegrees"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedMinutes">
    <xsl:if test="format-number($partiallyNormalisedMinutes, '00') = '60'"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedMinutes, '00') = '60')"><xsl:value-of select="$partiallyNormalisedMinutes"/></xsl:if>
  </xsl:variable>

  <xsl:if test="$sign = -1">-</xsl:if>
  <xsl:value-of select="format-number($normalisedDegrees, '0')"/>
  <xsl:value-of select="$degreesSymbol"/>
  <xsl:value-of select="format-number($normalisedMinutes, '00')"/>
  <xsl:value-of select="$minutesSymbol"/>
  <xsl:choose>
    <xsl:when test="$useSymbols = 'true'">
      <xsl:value-of select="format-number($normalisedSeconds, concat('00', $decPlFmt))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="translate(format-number($normalisedSeconds, concat('00', $decPlFmt)), '.', '')"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select="$secondsSymbol"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Format a Quadrant Bearing ****************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatQuadrantBearing">
  <xsl:param name="decimalAngle"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="northLbl" select="'N'"/>
  <xsl:param name="eastLbl" select="'E'"/>
  <xsl:param name="southLbl" select="'S'"/>
  <xsl:param name="westLbl" select="'W'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:choose>
    <!-- Null azimuth value -->
    <xsl:when test="string(number($decimalAngle)) = 'NaN'">
      <xsl:value-of select="format-number($decimalAngle, $DecPl3, 'Standard')"/>  <!-- Use the defined null format output -->
    </xsl:when>
    <!-- There is an azimuth value -->
    <xsl:otherwise>
      <xsl:variable name="quadrantAngle">
        <xsl:if test="($decimalAngle &lt;= 90.0)">
          <xsl:value-of select="number ( $decimalAngle )"/>
        </xsl:if>
        <xsl:if test="($decimalAngle &gt; 90.0) and ($decimalAngle &lt;= 180.0)">
          <xsl:value-of select="number( 180.0 - $decimalAngle )"/>
        </xsl:if>
        <xsl:if test="($decimalAngle &gt; 180.0) and ($decimalAngle &lt; 270.0)">
          <xsl:value-of select="number( $decimalAngle - 180.0 )"/>
        </xsl:if>
        <xsl:if test="($decimalAngle &gt;= 270.0) and ($decimalAngle &lt;= 360.0)">
          <xsl:value-of select="number( 360.0 - $decimalAngle )"/>
        </xsl:if>
      </xsl:variable>

      <xsl:variable name="quadrantPrefix">
        <xsl:if test="($decimalAngle &lt;= 90.0) or ($decimalAngle &gt;= 270.0)"><xsl:value-of select="$northLbl"/></xsl:if>
        <xsl:if test="($decimalAngle &gt; 90.0) and ($decimalAngle &lt; 270.0)"><xsl:value-of select="$southLbl"/></xsl:if>
      </xsl:variable>

      <xsl:variable name="quadrantSuffix">
        <xsl:if test="($decimalAngle &lt;= 180.0)"><xsl:value-of select="$eastLbl"/></xsl:if>
        <xsl:if test="($decimalAngle &gt; 180.0)"><xsl:value-of select="$westLbl"/></xsl:if>
      </xsl:variable>

      <xsl:value-of select="$quadrantPrefix"/>
      <xsl:choose>
        <xsl:when test="$AngleUnit = 'DMSDegrees'">
          <xsl:call-template name="FormatDMSAngle">
            <xsl:with-param name="decimalAngle" select="$quadrantAngle"/>
            <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
            <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
            <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="$quadrantAngle"/>
            <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
            <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
            <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$quadrantSuffix"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********* Return radians angle between Specified Limits ******** -->
<!-- **************************************************************** -->
<xsl:template name="RadianAngleBetweenLimits">
  <xsl:param name="anAngle"/>
  <xsl:param name="minVal" select="0.0"/>
  <xsl:param name="maxVal" select="$Pi * 2.0"/>
  <xsl:param name="incVal" select="$Pi * 2.0"/>

  <xsl:variable name="angle1">
    <xsl:call-template name="AngleValueLessThanMax">
      <xsl:with-param name="inAngle" select="$anAngle"/>
      <xsl:with-param name="maxVal" select="$maxVal"/>
      <xsl:with-param name="incVal" select="$incVal"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="angle2">
    <xsl:call-template name="AngleValueGreaterThanMin">
      <xsl:with-param name="inAngle" select="$angle1"/>
      <xsl:with-param name="minVal" select="$minVal"/>
      <xsl:with-param name="incVal" select="$incVal"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:value-of select="$angle2"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******* Return the arcTan value using a series expansion ******* -->
<!-- **************************************************************** -->
<xsl:template name="ArcTanSeries">
  <xsl:param name="tanVal"/>

  <!-- If the absolute value of tanVal is greater than 1 the work with the -->
  <!-- reciprocal value and return the resultant angle subtracted from Pi. -->
  <xsl:variable name="absTanVal" select="concat(substring('-',2 - ($tanVal &lt; 0)), '1') * $tanVal"/>
  <xsl:variable name="tanVal2">
    <xsl:choose>
      <xsl:when test="$absTanVal &gt; 1.0">
        <xsl:value-of select="1.0 div $tanVal"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$tanVal"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="valSq" select="$tanVal2 * $tanVal2"/>

  <xsl:variable name="angVal">
    <xsl:value-of select="$tanVal2 div (1 + ($valSq
                                   div (3 + (4 * $valSq
                                   div (5 + (9 * $valSq
                                   div (7 + (16 * $valSq
                                   div (9 + (25 * $valSq
                                   div (11 + (36 * $valSq
                                   div (13 + (49 * $valSq
                                   div (15 + (64 * $valSq
                                   div (17 + (81 * $valSq
                                   div (19 + (100 * $valSq
                                   div (21 + (121 * $valSq
                                   div (23 + (144 * $valSq
                                   div (25 + (169 * $valSq
                                   div (27 + (196 * $valSq
                                   div (29 + (225 * $valSq))))))))))))))))))))))))))))))"/>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$absTanVal &gt; 1.0">
      <xsl:choose>
        <xsl:when test="$tanVal &lt; 0">
          <xsl:value-of select="-$halfPi - $angVal"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$halfPi - $angVal"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$angVal"/>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<!-- **************************************************************** -->
<!-- ******* Return radians angle less than Specificed Maximum ****** -->
<!-- **************************************************************** -->
<xsl:template name="AngleValueLessThanMax">
  <xsl:param name="inAngle"/>
  <xsl:param name="maxVal"/>
  <xsl:param name="incVal"/>

  <xsl:choose>
    <xsl:when test="$inAngle &gt; $maxVal">
      <xsl:variable name="newAngle">
        <xsl:value-of select="$inAngle - $incVal"/>
      </xsl:variable>
      <xsl:call-template name="AngleValueLessThanMax">
        <xsl:with-param name="inAngle" select="$newAngle"/>
      </xsl:call-template>
    </xsl:when>

    <xsl:otherwise>
      <xsl:value-of select="$inAngle"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************* Return radians angle greater than Zero *********** -->
<!-- **************************************************************** -->
<xsl:template name="AngleValueGreaterThanMin">
  <xsl:param name="inAngle"/>
  <xsl:param name="minVal"/>
  <xsl:param name="incVal"/>

  <xsl:choose>
    <xsl:when test="$inAngle &lt; $minVal">
      <xsl:variable name="newAngle">
        <xsl:value-of select="$inAngle + $incVal"/>
      </xsl:variable>
      <xsl:call-template name="AngleValueGreaterThanMin">
        <xsl:with-param name="inAngle" select="$newAngle"/>
      </xsl:call-template>
    </xsl:when>

    <xsl:otherwise>
      <xsl:value-of select="$inAngle"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- **************************************************************** -->
<!-- **************** Output the Headings Data ********************** -->
<!-- **************************************************************** -->
<xsl:template name="OutputHeadings">
  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>
    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr1">Project</xsl:with-param>
      <xsl:with-param name="val1" select="JOBFile/@jobName"/>
      <xsl:with-param name="hdr2">Date</xsl:with-param>
      <xsl:with-param name="val2" select="concat(substring(JOBFile/@TimeStamp, 9, 2), '.',
                                                 substring(JOBFile/@TimeStamp, 6, 2), '.',
                                                 substring(JOBFile/@TimeStamp, 1, 4))"/>
    </xsl:call-template>
  <xsl:call-template name="EndTable"/>

  <xsl:call-template name="SeparatingLine"/>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
  </xsl:call-template>
    <xsl:variable name="instMake">
      <xsl:call-template name="GetInstMake"/>
    </xsl:variable>
    <xsl:variable name="instModel" select="/JOBFile/FieldBook/InstrumentRecord[1]/Model"/>
    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr1">Instrument</xsl:with-param>
      <xsl:with-param name="val1" select="concat($instMake, ' ', $instModel)"/>
      <xsl:with-param name="hdr2">Distance unit</xsl:with-param>
      <xsl:with-param name="val2">
        <xsl:choose>
          <xsl:when test="$DistUnit = 'Metres'">Metres</xsl:when>
          <xsl:when test="$DistUnit = 'InternationalFeet'">Feet</xsl:when>
          <xsl:when test="$DistUnit = 'USSurveyFeet'">Survey Feet</xsl:when>
          <xsl:otherwise>Metres</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr1">Serial Number</xsl:with-param>
      <xsl:with-param name="val1" select="/JOBFile/FieldBook/InstrumentRecord[1]/Serial"/>
      <xsl:with-param name="hdr2">Angle unit</xsl:with-param>
      <xsl:with-param name="val2">
        <xsl:choose>
          <xsl:when test="$AngleUnit = 'DMSDegrees'">DMS Degrees</xsl:when>
          <xsl:when test="$AngleUnit = 'DecimalDegrees'">Decimal Degrees</xsl:when>
          <xsl:when test="$AngleUnit = 'Gons'">Gons</xsl:when>
          <xsl:when test="$AngleUnit = 'Mils'">Mils</xsl:when>
          <xsl:otherwise>DMS Degrees</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr1">Firmware Version</xsl:with-param>
      <xsl:with-param name="val1" select="/JOBFile/FieldBook/InstrumentRecord[1]/FirmwareVersion"/>
      <xsl:with-param name="hdr2">Temperature unit</xsl:with-param>
      <xsl:with-param name="val2" select="$TempUnit"/>
    </xsl:call-template>

    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr2">Pressure unit</xsl:with-param>
      <xsl:with-param name="val2" select="$PressUnitStr"/>
    </xsl:call-template>

    <xsl:call-template name="OutputTwoElementTableLine">
      <xsl:with-param name="hdr1"><xsl:value-of select="$product"/></xsl:with-param>
      <xsl:with-param name="val1" select="concat('v', $version)"/>
    </xsl:call-template>

    <!-- Output any job Reference details if present -->
    <xsl:if test="/JOBFile/FieldBook/JobPropertiesRecord[last()]/Reference != ''">
      <xsl:call-template name="OutputTwoElementTableLine">
        <xsl:with-param name="hdr1">Reference</xsl:with-param>
        <xsl:with-param name="val1" select="/JOBFile/FieldBook/JobPropertiesRecord[last()]/Reference"/>
      </xsl:call-template>
    </xsl:if>

    <!-- Output any Operator (Surveyor) details if present -->
    <xsl:if test="/JOBFile/FieldBook/JobPropertiesRecord[last()]/Operator != ''">
      <xsl:call-template name="OutputTwoElementTableLine">
        <xsl:with-param name="hdr1">Operator</xsl:with-param>
        <xsl:with-param name="val1" select="/JOBFile/FieldBook/JobPropertiesRecord[last()]/Operator"/>
      </xsl:call-template>
    </xsl:if>

  <xsl:call-template name="EndTable"/>

  <br/>
  <xsl:call-template name="SeparatingLine"/>

  <xsl:call-template name="Heading1">
    <xsl:with-param name="text">Project Properties</xsl:with-param>
  </xsl:call-template>

  <!-- Output coordinate system name details -->
  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">Coordinate System</xsl:with-param>
  </xsl:call-template>
  
  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="50"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">System Name</xsl:with-param>
      <xsl:with-param name="val" select="/JOBFile/Environment/CoordinateSystem/SystemName"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Zone</xsl:with-param>
      <xsl:with-param name="val" select="/JOBFile/Environment/CoordinateSystem/ZoneName"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Datum</xsl:with-param>
      <xsl:with-param name="val" select="/JOBFile/Environment/CoordinateSystem/DatumName"/>
    </xsl:call-template>
  <xsl:call-template name="EndTable"/>

  <!-- Output projection definition details -->
  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">Projection</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="50"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Projection</xsl:with-param>
      <xsl:with-param name="val" select="/JOBFile/Environment/CoordinateSystem/Projection/Type"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Latitude Origin</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:call-template name="FormatLatLong">
          <xsl:with-param name="theAngle" select="/JOBFile/Environment/CoordinateSystem/Projection/CentralLatitude"/>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Longitude Origin</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:call-template name="FormatLatLong">
          <xsl:with-param name="theAngle" select="/JOBFile/Environment/CoordinateSystem/Projection/CentralLongitude"/>
          <xsl:with-param name="isLat" select="'false'"/>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">False Easting</xsl:with-param>
      <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Projection/FalseEasting * $DistConvFactor, $DecPl3, 'Standard')"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">False Northing</xsl:with-param>
      <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Projection/FalseNorthing * $DistConvFactor, $DecPl3, 'Standard')"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Scale</xsl:with-param>
      <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Projection/Scale, $DecPl6, 'Standard')"/>
    </xsl:call-template>
  <xsl:call-template name="EndTable"/>

  <!-- Output datum transformation details -->
  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">Datum Transformation</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="50"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Type</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='NoDatum']">No Datum</xsl:if>
        <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter']">Seven Parameter</xsl:if>
        <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='ThreeParameter']">Three Parameter</xsl:if>
        <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='GridDatum']">Grid Datum</xsl:if>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Earth radius</xsl:with-param>
      <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Datum/EarthRadius * $DistConvFactor, $DecPl3, 'Standard')"/>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Flattening</xsl:with-param>
      <xsl:with-param name="val" select="format-number(1.0 div /JOBFile/Environment/CoordinateSystem/Datum/Flattening, $DecPl6, 'Standard')"/>
    </xsl:call-template>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">X axis rotation</xsl:with-param>
        <xsl:with-param name="val">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="/JOBFile/Environment/CoordinateSystem/Datum/RotationX"/>
            <xsl:with-param name="secDecPlaces">4</xsl:with-param>
            <xsl:with-param name="DMSOutput">true</xsl:with-param>
          </xsl:call-template>
          <xsl:text> DMS</xsl:text>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Y axis rotation</xsl:with-param>
        <xsl:with-param name="val">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="/JOBFile/Environment/CoordinateSystem/Datum/RotationY"/>
            <xsl:with-param name="secDecPlaces">4</xsl:with-param>
            <xsl:with-param name="DMSOutput">true</xsl:with-param>
          </xsl:call-template>
          <xsl:text> DMS</xsl:text>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Z axis rotation</xsl:with-param>
        <xsl:with-param name="val">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="/JOBFile/Environment/CoordinateSystem/Datum/RotationZ"/>
            <xsl:with-param name="secDecPlaces">4</xsl:with-param>
            <xsl:with-param name="DMSOutput">true</xsl:with-param>
          </xsl:call-template>
          <xsl:text> DMS</xsl:text>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter'] or
                  /JOBFile/Environment/CoordinateSystem/Datum/Type[.='ThreeParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">X translation</xsl:with-param>
        <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Datum/TranslationX * $DistConvFactor, $DecPl3, 'Standard')"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter'] or
                  /JOBFile/Environment/CoordinateSystem/Datum/Type[.='ThreeParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Y translation</xsl:with-param>
        <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Datum/TranslationY * $DistConvFactor, $DecPl3, 'Standard')"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='SevenParameter'] or
                  /JOBFile/Environment/CoordinateSystem/Datum/Type[.='ThreeParameter']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Z translation</xsl:with-param>
        <xsl:with-param name="val" select="format-number(/JOBFile/Environment/CoordinateSystem/Datum/TranslationZ * $DistConvFactor, $DecPl3, 'Standard')"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr" select="'Scale'"/>
      <xsl:with-param name="val" select="concat(format-number((1.0 - /JOBFile/Environment/CoordinateSystem/Datum/Scale) * 1000000.0, $DecPl5, 'Standard'), ' ppm')"/>
    </xsl:call-template>

    <xsl:if test="/JOBFile/Environment/CoordinateSystem/Datum/Type[.='GridDatum']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Datum grid file</xsl:with-param>
        <xsl:with-param name="val" select="/JOBFile/Environment/CoordinateSystem/Datum/GridName"/>
      </xsl:call-template>
    </xsl:if>
  <xsl:call-template name="EndTable"/>

  <!-- Output datum transformation details -->
  <xsl:call-template name="Heading2">
    <xsl:with-param name="text">Corrections</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="StartTable">
    <xsl:with-param name="includeBorders">false</xsl:with-param>
    <xsl:with-param name="tableWidth" select="50"/>
  </xsl:call-template>
    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Distances as</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/Distances[.='GroundDistance']">Ground</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/Distances[.='GridDistance']">Grid</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/Distances[.='EllipsoidDistance']">Ellipsoid</xsl:if>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">South azimuth</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/SouthAzimuth[.='false']">No</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/SouthAzimuth[.!='false']">Yes</xsl:if>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Grid Orientation</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/GridOrientation[.='IncreasingNorthEast']">Increasing NE</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/GridOrientation[.='IncreasingSouthWest']">Increasing SW</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/GridOrientation[.='IncreasingNorthWest']">Increasing NW</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/GridOrientation[.='IncreasingSouthEast']">Increasing SE</xsl:if>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Magnetic Declination</xsl:with-param>
        <xsl:with-param name="val">
          <xsl:call-template name="FormatAngle">
            <xsl:with-param name="theAngle" select="/JOBFile/FieldBook/CorrectionsRecord[last()]/MagneticDeclination"/>
          </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="OutputOneElementTableLine">
      <xsl:with-param name="hdr">Neighborhood Adjustment</xsl:with-param>
      <xsl:with-param name="val">
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/NeighbourhoodAdjustment/Applied[.='true']">On</xsl:if>
        <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/NeighbourhoodAdjustment/Applied[.!='true']">Off</xsl:if>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:if test="/JOBFile/FieldBook/CorrectionsRecord[last()]/NeighbourhoodAdjustment/Applied[.='true']">
      <xsl:call-template name="OutputOneElementTableLine">
        <xsl:with-param name="hdr">Weight Exponent</xsl:with-param>
        <xsl:with-param name="val" select="format-number(/JOBFile/FieldBook/CorrectionsRecord[last()]/NeighbourhoodAdjustment/WeightExponent, $DecPl1, 'Standard')"/>
      </xsl:call-template>
    </xsl:if>
  <xsl:call-template name="EndTable"/>
</xsl:template>


</xsl:stylesheet>
