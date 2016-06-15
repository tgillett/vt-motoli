#! /bin/bash

USAGE1="Usage:   ./EditScript.sh   ./<input-file.txt>   ./<output-file.html>"

if (( $# < 2 ))
then
	echo " "
	echo "Error. Not enough arguments."
	echo $USAGE1
	echo " "
	exit 1
elif (( $# > 2 ))
then
	echo " "
	echo "Error. Too many arguments."
	echo $USAGE1
        echo " "
	exit 2
elif [ $1 == "--help" ]
then
	echo " "
	echo $USAGE1
        echo " "
	exit 3
fi


StoryFile=$1
OutputFile=$2

# Find the line containing the required field, cut the field value, strip leading and trailing whitespace
StoryName=`cat $StoryFile  | grep "#StoryName#" | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
MaxPages=`cat $StoryFile   | grep "#MaxPages#"  | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
MaxLines=`cat $StoryFile   | grep "#MaxLines#"  | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
MaxCont=`cat $StoryFile    | grep "#MaxCont#"   | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
Format=`cat $StoryFile     | grep "#Format#"    | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
ScaleSide=`cat $StoryFile  | grep "#ScaleSide#" | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
ScaleTop=`cat $StoryFile   | grep "#ScaleTop#"  | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
Pause=`cat $StoryFile      | grep "#Pause#"     | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
Backcolour=`cat $StoryFile | grep "#Backcolour#"| cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
Debug=`cat $StoryFile      | grep "#Debug#"     | cut -d "#" -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`

# Supported colour names are here:  http://www.w3schools.com/colors/colors_names.asp

# Check for valid param values
if [ -z "$MaxPages" ] || [ $MaxPages -gt 50 ] || [ $MaxPages -lt 2 ]; then
	MaxPages=20
fi
if [ -z "$MaxLines" ] || [ $MaxLines -gt 20 ] || [ $MaxLines -lt 1 ]; then
	MaxLines=10
fi
if [ -z "$MaxCont" ] || [ $MaxCont -gt 10 ] || [ $MaxCont -lt 1 ]; then
	MaxCont=5
fi
if [ -z "$Format" ] || [ "$Format" != "under" ]; then
	Format="side"
fi
if [ -z "$ScaleSide" ] || [ $ScaleSide -gt 80 ] || [ $ScaleSide -lt 20 ]; then
	ScaleSide=40
fi
if [ -z "$ScaleTop" ] || [ $ScaleTop -gt 80 ] || [ $ScaleTop -lt 20 ]; then
	ScaleTop=60
fi
if [ -z "$Pause" ] || [ $Pause -gt 2000 ] || [ $Pause -lt 50 ]; then
	Pause=300
fi
if [ -z "$Backcolour" ]; then
	Backcolour="white"
fi
if [ -z "$Debug" ] || [ "$Debug" != "on" ]; then
	Debug="off"
fi

# Output the param values
echo "Story Name: "$StoryName
echo "Max Pages: "$MaxPages
echo "Max Lines: "$MaxLines
echo "Max Cont: "$MaxCont
echo "Format: "$Format
echo "ScaleSide: "$ScaleSide
echo "ScaleTop: "$ScaleTop
echo "Pause: "$Pause
echo "Backcolour: "$Backcolour
echo "Debug: "$Debug


# HTML generation functions
# Set up header
function do_header() {
cat > ./$OutputFile << EOF
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>
	$StoryName
	</title>
	<link rel="stylesheet" href="../../common/storyStyles.css">
	<script src="../../common/storyScripts.js"></script>
</head>
<body onload="initialise()" onresize="limitPictureSize()">
<p id="loadmsg">Loading the story...</p>
<div class="$Format" id="story">

<!-- Data for this story -->
<p class="data">
<span id="platform"></span>
<span id="onloads">0</span>
<span id="pScaleSide">$ScaleSide</span>
<span id="pScaleTop">$ScaleTop</span>
<span id="barPause">$Pause</span>
<span id="backColor">$Backcolour</span>
<span id="diagnostic">$Debug</span>
</p>
EOF
}


#Set up the pages
function do_pages() {
for (( i=0; i<=$MaxPages; i++ ))
do
	PAGEID="p"$i

	# Get common image
	PICNAME=`grep "#Page"$i"Pic#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`
	if [ -n "$PICNAME" ]; then
		PIC="../../common/"$PICNAME".jpg"
	else
		PIC="p"$i"pic.jpg"
	fi

	# Insert the page leader
	cat >> ./$OutputFile << EOF

<!-- PAGE $i -->
<div class="page" id="$PAGEID">

<div class="pict">
<div class="underpic"> <!-- Format for a vertically oriented page -->
	<table><tr>
	<td><img src="../../common/back.png" class="btnback" onclick="pageBack()"></img></td>
	<td><img src="$PIC" class="mainpic"></img></td>
	<td><img src="../../common/fwd.png" class="btnfwd" onclick="pageFwd()"></img></td>
	</tr></table>
</div>

<div class="sidepic"> <!-- Format for a horizontally oriented page -->
	<img src="$PIC" class="mainpic"></img>
	<table><tr>
	<td><img src="../../common/back.png" class="btnback" onclick="pageBack()"></img></td>
	<td><span class="title">$StoryName</span><br />
	<span class="pgnum">page #</span></td>
	<td><img src="../../common/fwd.png" class="btnfwd" onclick="pageFwd()"></img></td>
	</tr></table>
</div>
</div>

<div class="text">
<table class="texttab">
EOF

	# Insert the text lines into the page
	do_lines

	# Insert the page trailer
	cat >> ./$OutputFile << EOF
</table>
</div>
</div>
<!-- END PAGE $i -->

EOF
done
}


# Set up the lines
function do_lines() {

	PAUSE="|"
	HTMLPAUSE="<\/span><span class=\"pause\">|<\/span><span>"

	for (( j=1; j<=$MaxLines; j++ ))
	do
		# Do the single lines
		LINE=`grep "#Page"$i"Line"$j"#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s/"$PAUSE"/"$HTMLPAUSE"/g`
		TIME=`cat $StoryFile | grep "#Page"$i"Time"$j"#" | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`

		PAGENO="'p"$i"'"
		SOUND="'p"$i"sound"$j".mp3'"
		VALIDLINE=FALSE

		# Substitute for blank lines
		if [ "$LINE" = "&nil" ]; then
			LINE="<br />"
		fi

		if [ -n "$LINE" ]; then
			VALIDLINE=TRUE
			cat >> ./$OutputFile << EOF

<!-- Text line $j -->
<tr><td class="textLine">
<span class="line"><span>$LINE</span></span><br /><progress value="0" max="100"></progress></td>
<!-- Audio file, time in secs, page ID, line No. -->
<td class="button"><img src="../../common/play.png" onclick="playAudio($SOUND, '$TIME', $PAGENO, '$j' )"></img></td>
</tr>
EOF

		fi

		# Do first continuation line
		CONTLINE=FALSE
		# Look for the first continuation line
		LINE=`grep "#Page"$i"Line"$j"-0#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s/"$PAUSE"/"$HTMLPAUSE"/g`

		if [ -n "$LINE" ]; then
			CONTLINE=TRUE
			cat >> ./$OutputFile << EOF

<tr><!-- Text line $j -->
<td class="textLine wrap">
<span class="line"><span>$LINE</span></span><br /><progress value="0"></progress><br />
EOF
		fi

		# Do the rest of the continuation lines
		if [ $CONTLINE = "TRUE" ]; then
			for (( k=1; k<=$MaxCont; k++ ))
			do
			LINE=`grep "#Page"$i"Line"$j"-"$k"#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s/"$PAUSE"/"$HTMLPAUSE"/g`

				if [ -n "$LINE" ]; then
						cat >> ./$OutputFile << EOF
<span class="line"><span>$LINE</span></span><br /><progress value="0"></progress><br />
EOF
				fi
			done
		fi

		# Do the simple text lines with no audio
		LINE=`grep "#Page"$i"Text"$j"#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//'`

		# Substitute for blank lines
		if [ "$LINE" = "&nil" ]; then
			LINE="<br />"
		fi

		if [ -n "$LINE" ]; then
			cat >> ./$OutputFile << EOF
<!-- Text line $j --><tr><td><span> 
$LINE
</span><br />
EOF
		fi

		# Do the first text continuation line
		CONTTXT=FALSE
		# Look for the first text continuation line
		LINE=`grep "#Page"$i"Text"$j"-0#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s/"$PAUSE"/"$HTMLPAUSE"/g`

		if [ -n "$LINE" ]; then
			CONTTXT=TRUE
			cat >> ./$OutputFile << EOF
<!-- Text line $j --><tr><td><span>
$LINE<br />
EOF
		fi

		# Do the rest of the text continuation lines
		if [ $CONTTXT = "TRUE" ]; then
			for (( k=1; k<=$MaxCont; k++ ))
			do
			LINE=`grep "#Page"$i"Text"$j"-"$k"#" $StoryFile | cut -d '#' -f 3 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s/"$PAUSE"/"$HTMLPAUSE"/g`

				if [ -n "$LINE" ]; then
					cat >> ./$OutputFile << EOF
$LINE<br />
EOF
				else      # After the last continuation line.
					k=$MaxCont
					cat >> ./$OutputFile << EOF
</span></td></tr>
EOF
				fi
			done
		fi



		# Finish the line section
		if [ $CONTLINE = "TRUE" ]; then
			cat >> ./$OutputFile << EOF
</td>
<!-- Audio file, time in secs, page ID, line No. -->
<td class="button"><img src="../../common/play.png" onclick="playAudio($SOUND, '$TIME', $PAGENO, '$j' )"></img></td>
</tr>
EOF
		fi

	done
}

# Set up trailer
function do_trailer() {
cat >> ./$OutputFile << EOF

<!-- PAGE IDENTIFICATION SECTION - DO NOT CHANGE -->
<div class="footer underpic">
	<strong><span class="title">$StoryName</span></strong>
	<span class="pgnum">page #</span>
</div> <!-- END PAGE IDENTIFICATION SECTION -->

<div>
<audio id="AudioPlayer"></audio>
</div>
</div>
<!-- END OF STORY -->
</body>
</html>
EOF
}

##############################################

# Build new html file
do_header
do_pages
do_trailer

echo "Script complete"

exit


