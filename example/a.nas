include advlib
include os/goodlyay+24

using quit_resets_runargs
using allow_include


set hehe You can use @p to substitute their full player name (includes the +) or @nick to subtitute for a more natural version of their name (e.g. Mike_30+ becomes Mike)

#Error
    #Error.HandleMenu

    quit
quit

#Text
    // • runarg1 should be a package which is structured as an index/list of text to display.
    // • runarg2 can either be an integer value, empty or "true".
    //   • If runarg2 is a value: that value becomes the text's msgDelayMultiplier.
    //   • If runArg2 is empty (or something unrecognized): a fallback msgDelayMultiplier is selected.
    //   • If runArg2 is "true": the text display enters manual mode and the player must advance
    //     the text by pressing the interact hotkey.
    #Text.print
         if text.isActive quit
        set text.isActive true

        call #_Text.init
        call #_Text.validate

           if text.isManual call #_Text.waitToAdvance
        ifnot text.isManual call #_Text.doAutoAdvance

        call #_Text.exit
    quit

    // • runarg1 should be a package which is structured as an index/list of text to display.
    // • runarg2 can either be an integer value, empty or "true".
    //   • If runarg2 is a value: that value becomes the text's msgDelayMultiplier.
    //   • If runArg2 is empty (or something unrecognized): a fallback msgDelayMultiplier is selected.
    //   • If runArg2 is "true": the text display enters manual mode and the player must advance
    //   • the text by pressing the interact hotkey.
    // • runArg3 can be a package of a character or "|" separated list of characters that will be 
    //   the randomized leading characters of the scrolling text.
    #Text.printScrolling
        if text.isActive quit
        set text.isActive true

        call #_Text.init
        call #_Text.validate

        set text.isScrolling true
        setdiv msgDelayMultiplier 2
        setround msgDelayMultiplier

        set text.charList {{runArg3}}
        setsplit text.charList
        if text.charList.Length|>|0 set text.hasCharList true

           if text.isManual call #_Text.waitToAdvance
        ifnot text.isManual call #_Text.doAutoAdvance
        call #_Text.exit
    quit

    #_Text.init
        set text.id {runArg1}
        set text.index 0

           if runArg2 set text.isManual true
           if runArg2 set msgDelayMultiplier 75
        ifnot runArg2 set msgDelayMultiplier {runArg2}
                       if msgDelayMultiplier|=| set msgDelayMultiplier 75
    quit

    #_Text.waitToAdvance
        set text.j 0
        msg %ePress E to continue.
        // This fires off once to show the first line automatically.
        call #Text.printLine

        #waitManualTextAdvance
            if text.message.Length|=|0 delay msgDelay
            if text.message.Length|=|0 quit

            if text.doneIteratedLine cpemsg announce {text.message}
            if text.doneIteratedLine call #animAdvanceButton

            setadd text.j 1
            delay 200
            if text.j|<|300 jump #waitManualTextAdvance
        //
        call #Text.printLine
        jump #waitManualTextAdvance

        #animAdvanceButton
            call #checkEvenOrOdd|{text.j}
               if isEven cpemsg smallannounce E →
            ifnot isEven cpemsg smallannounce E  →
        quit
    quit

    #_Text.doAutoAdvance
        call #Text.printLine
        delay msgDelay
        if text.message.Length|>|0 jump #_Text.doAutoAdvance
    quit

    #Text.printLine
        if text.isPrinting quit
        set text.isPrinting true
        
        set text.message {{text.id}[{text.index}]}
        setsplit text.message

        setadd text.index 1
        if text.isManual set text.j 0

        ifnot text.isScrolling msg {text.message}
           if text.isScrolling cpemsg smallannounce
           if text.isScrolling call #_Text.printScrollingLine
        
        set text.isPrinting false
    quit

    #_Text.printScrollingLine
        if text.message.Length|=|0 cpemsg announce
        if text.message.Length|=|0 quit

        set text.doneIteratedLine false
        set % %
        set text.k 0
        set text.temp
        #loopIteratedLine
            if text.hasCharList set text.i 0
            if text.hasCharList call #_Menu.drawLeadingChar

            set text.temp {text.temp}{text.message[{text.k}]}
            if text.message[{text.k}]|=|% jump #_Text.captureColorCode
            cpemsg announce {text.temp}

            ifnot text.hasCharList delay 30

            setadd text.k 1
            ifnot text.k|>=|text.message.Length jump #loopIteratedLine
        //
        delay 500
        set text.doneIteratedLine true
    quit

    #_Menu.drawLeadingChar
        set text.rand
        setrandlist text.rand {text.charList}
        set text.temprand {text.temp}{text.rand}
        cpemsg announce {text.temprand}
        setadd text.i 1
        delay 10
        ifnot text.i|>|3 jump #_Menu.drawLeadingChar
    quit

    #_Text.captureColorCode
        setadd text.k 1
        set text.temp {text.temp}{text.message[{text.k}]}
        setadd text.k 1
        jump #loopIteratedLine
    quit

    #_Text.exit
        resetdata packages text.*
    quit

    #_Text.validate
        if {text.id}[0]|=| msg %4Error: #Text.print invalid params: {text.id}
        if {text.id}[0]|=| goto #_Text.exit
    quit
quit

#Scene
    // • runArg1 should be a package which are a set of coords, pitch and yaw of
    //   where the player will be located and oriented towards during the scene.
    #Scene.switch
        set scene.id {{runArg1}}

           if scene.isActive tempblock {scene.underPlayerID} {scene.coords.plat} 
           if scene.isActive set scene.coords.old {scene.coords.plat}
        ifnot scene.isActive call #_Scene.setup
        set scene.isActive true

        call #_Scene.setCoords
        setadd scene.i 1
        call #_Scene.setBarsID
        call #_Scene.moveBars
        call #_Scene.movePlayer
        ifnot scene.coords.old|=| call #_Scene.removeOldBars
    quit

    #_Scene.setup
        // Overwrite player velocity.
        boost 0 0 0 1 1 1 200
        freeze
        delay 100
        
        set scene.coords.pOrigin {PlayerX} {PlayerY} {PlayerZ} {PlayerYaw} {PlayerPitch}
        set scene.i 0
    quit

    #_Scene.setCoords
        set scene.coords.tele {scene.id}
        set scene.coords.plat {scene.coords.tele}
        setsplit scene.coords.plat " "
        setsub scene.coords.plat[1] 1
        set scene.coords.plat {scene.coords.plat[0]} {scene.coords.plat[1]} {scene.coords.plat[2]}
        setblockid scene.underPlayerID {scene.coords.plat}
    quit

    #_Scene.setBarsID
        call #checkEvenOrOdd|{scene.i}
           if isEven set scene.barsID 1
        ifnot isEven set scene.barsID 2
    quit

    #_Scene.moveBars
        // todo: Does this have to be an invisible lb?
        tempblock black {scene.coords.plat}
        cmd tempbot tp tbot.scenebars{scene.barsID} {scene.coords.tele}
    quit

    #_Scene.movePlayer
        cmd holdsilent air
        changemodel invisible
        cmd tempbot add tbot.player {scene.coords.pOrigin} $skin empty
        cmd tp {scene.coords.tele}
    quit

    #_Scene.removeOldBars
        if scene.barsID|=|1 cmd tempbot tp tbot.scenebars2 0 0 0 0 0
        if scene.barsID|=|2 cmd tempbot tp tbot.scenebars1 0 0 0 0 0
    quit

    #Scene.exit
        set scene.coords.end {{runArg1}}
        setsplit scene.coords.end " "
        
        changemodel humanoid
        cmd tempbot remove tbot.player

        if scene.coords.end.Length|>=|3 cmd tp {scene.coords.end}
        if scene.coords.end.Length|<|3 cmd tp {scene.coords.pOrigin}
        tempblock {scene.underPlayerID} {scene.coords.plat} 

        unfreeze

        cmd tempbot tp tbot.scenebars2 0 0 0 0 0
        cmd tempbot tp tbot.scenebars1 0 0 0 0 0

        resetdata packages scene.*
    quit
quit

#Menu
    // todo: invalid runargs 
    // todo: check against menu.options.Length != menu.labels.Length
    // todo: limit max char len to 64

    // • runArg1 should be the name of an object that contains the following properties:
    //   • myThing.superName...(this is the top line of the menu)
    //   • myThing.name........(this is the middle line of the menu)
    //   • myThing.options.....(these are the displayed options of the menu)
    //   • myThing.labels......(these are the labels the above options perform when an option is selected)
    // • runArg2 can be "true" or "false" and decides whether a menu can be backed out of.
    // • runArg3 can be "true" or "false" and decides whether a menu can be exited out of.
    #Menu.open
        set menu.id {runArg1}
        set menu.disableBack {runArg2}
        set menu.disableExit {runArg3}

        ifnot menu.isPop call #_Menu.pushStack
           if menu.isPop set menu.isPop false

        ifnot menu.isOpen call #_Menu.handleMenuInit
           if menu.isOpen call #_Menu.handleMenuRedraw
          set menu.isOpen true

        call #_Menu.splitOptionAndLabel|menu.options|menu.labels
        call #_Menu.joinMenuOptions

        set menu.options.i 0
        set menu.topLine {menu.superName}
        set menu.midLine {menu.name}
        set menu.botLine {menu.optionDisplay[0]}
        call #_Menu.displayAndWaitForOptionSelect
    quit

    #_Menu.handleMenuInit
        set menu.superName {{menu.id}.superName}
        set menu.name {{menu.id}.name}
        set menu.options {{menu.id}.options}
        set menu.labels {{menu.id}.labels}
        
        if scene.isActive quit
        call #_Menu.freezePlayer
        call #_Menu.moveBars
    quit

    #_Menu.pushStack
        setadd menu.stack.size 1
        cpemsg top3 {menu.stack.size}
        set menu.stack[{menu.stack.size}].id {menu.id}
        set menu.stack[{menu.stack.size}].disableBack {menu.disableBack}
        set menu.stack[{menu.stack.size}].disableExit {menu.disableExit}
        set menu.stack[{menu.stack.size}].superName {{menu.id}.superName}
        set menu.stack[{menu.stack.size}].name {{menu.id}.name}
        set menu.stack[{menu.stack.size}].options {{menu.id}.options}
        set menu.stack[{menu.stack.size}].labels {{menu.id}.labels}
    quit

    #_Menu.popStack
        set menu.isPop true
        resetdata packages menu.stack[{menu.stack.size}]*
        setsub menu.stack.size 1
        cpemsg top3 {menu.stack.size}
    quit

    #_Menu.handleMenuRedraw
        resetdata packages menu.option*
        resetdata packages menu.label*

        set menu.id {menu.stack[{menu.stack.size}].id}
        set menu.disableBack {menu.stack[{menu.stack.size}].disableBack}
        set menu.disableExit {menu.stack[{menu.stack.size}].disableExit}
        set menu.superName {menu.stack[{menu.stack.size}].superName}
        set menu.name {menu.stack[{menu.stack.size}].name}
        set menu.options {menu.stack[{menu.stack.size}].options}
        set menu.labels {menu.stack[{menu.stack.size}].labels}

        set menu.pauseActionable false
    quit

    #_Menu.freezePlayer
        boost 0 0 0 1 1 1 200
        freeze
        delay 100

        // Don't open menu if the player is in the air.
        set menu.underY {PlayerY}
        setsub menu.underY 1
        setblockid menu.idUnderPlayer {PlayerX} {menu.underY} {PlayerZ}
        delay 100
        if menu.idUnderPlayer|=|0 goto #_Menu.denyInput
    quit

    #_Menu.moveBars
        changemodel invisible
        cmd holdsilent air
        cmd tempbot tp tbot.menubars {PlayerCoordsDecimal} {PlayerYaw} {PlayerPitch}
        reach 0
    quit

    #_Menu.splitOptionAndLabel
        set menu.i 0
        set menu.s_options {{runArg1}}
        set menu.s_labels {{runArg2}}
        setsplit menu.s_options |
        setsplit menu.s_labels |
        
        #loopSplitMenu
            set menu.options[{menu.i}] {menu.s_options[{menu.i}]}
            set menu.labels[{menu.i}] {menu.s_labels[{menu.i}]}
            setadd menu.i 1
            if menu.s_options.Length|>|menu.i jump #loopSplitMenu

        set menu.options.Length {menu.i}
        set menu.labels.Length {menu.i}
        resetdata packages menu.s_*
    quit

    #_Menu.joinMenuOptions
        set menu.tempOptions
        set menu.i 0
        #populateOptionDisplay
            set menu.tempOptions[{menu.i}] {menu.options}
            setadd menu.i 1
            if menu.options.Length|>|menu.i jump #populateOptionDisplay
        //

        set menu.i 0
        set menu.j 0
        #setColorInactiveOption
            setsplit menu.tempOptions[{menu.i}] |
            #loopColorInactiveLine
                set menu.temp {menu.tempOptions[{menu.i}][{menu.j}]}
                set menu.tempOptions[{menu.i}][{menu.j}] %7{menu.temp}
                setadd menu.j 1
                if menu.options.Length|>|menu.j jump #loopColorInactiveLine
            //
            set menu.j 0
            setadd menu.i 1
            if menu.options.Length|>|menu.i jump #setColorInactiveOption
        //

        set menu.i 0
        set menu.j 0
        #setColorActiveOption
            set menu.k 2
            set menu.temp {menu.tempOptions[{menu.i}][{menu.j}]}
            setsplit menu.temp
            set menu.temp_ %6
            #joinActiveMenuOption
                set menu.temp_ {menu.temp_}{menu.temp[{menu.k}]}
                setadd menu.k 1
                if menu.temp.Length|>|menu.k jump #joinActiveMenuOption
            //
            set menu.tempOptions[{menu.i}][{menu.j}] {menu.temp_}
            setadd menu.i 1
            setadd menu.j 1
            if menu.options.Length|>|menu.i jump #setColorActiveOption
        //

        set menu.i 0
        set menu.j 0
        #joinMenuOptionString
            set menu.temp
            #joinMenuOptionLine
                if menu.j|=|0 set menu.temp {menu.tempOptions[{menu.i}][{menu.j}]}
                if menu.j|>|0 set menu.temp {menu.temp}  {menu.tempOptions[{menu.i}][{menu.j}]}
                setadd menu.j 1
                if menu.options.Length|>|menu.j jump #joinMenuOptionLine
            //
            set menu.optionDisplay[{menu.i}] {menu.temp}
            set menu.j 0
            setadd menu.i 1
            if menu.options.Length|>|menu.i jump #joinMenuOptionString
        //

        resetdata packages menu.temp*
        // return menu.optionDisplay[]
    quit

    #_Menu.displayAndWaitForOptionSelect
        set menu.i 0
        #loopMenuDisplay
            // When menus are nested, the old menu's display loop has to be killed.
            // #_Menu.chooseOption delay is timed to kill the old thread.
            if menu.pauseActionable terminate

            ifnot menu.isOpen terminate
            if menu.i|>=|6000 goto #_Menu.chooseOption
            call #_Menu.updateDisplay
            delay 100
            setadd menu.i 1
            cpemsg top1 {menu.i}
            jump #loopMenuDisplay
        quit
    quit

    #_Menu.updateDisplay
        cpemsg announce {menu.topLine}
        cpemsg bigannounce {menu.midLine}
        cpemsg smallannounce {menu.botLine}
    quit

    #_Menu.denyInput
        msg %4Cannot open a menu.
        goto #Menu.exit
    quit

    #_Menu.inputLeft
        setsub menu.options.i 1
        if menu.options.i|<|0 set menu.options.i {menu.options.Length}
        if menu.options.i|=|menu.options.Length setsub menu.options.i 1
        set menu.botLine {menu.optionDisplay[{menu.options.i}]}

        cpemsg top2 {menu.options.i}

        call #_Menu.updateDisplay
    quit

    #_Menu.inputRight
        setadd menu.options.i 1
        if menu.options.i|=|menu.options.Length set menu.options.i 0
        set menu.botLine {menu.optionDisplay[{menu.options.i}]}

        cpemsg top2 {menu.options.i}

        call #_Menu.updateDisplay
    quit

    #_Menu.chooseOption
        set menu.pauseActionable true
        set menu.botLine Choosing option...
        call #_Menu.updateDisplay
        delay 300
        jump {menu.labels[{menu.options.i}]}
    quit

    #_Menu.back
        set menu.pauseActionable true
        set menu.botLine Going back...
        call #_Menu.updateDisplay
        call #_Menu.popStack
        if menu.stack.size|=|0 goto #Menu.exit
        delay 300
        jump #Menu.open|{menu.stack[{menu.stack.size}].id}
    quit

    #Menu.handleInput
        // Specifically, inputs when an option is being chosen should not happen.
        // The option should resolve before the player can make another action.
        if menu.pauseActionable quit 
        if runArg1|=|back jump #checkMenuBackInput
        if runArg1|=|exit jump #checkMenuExitInput
        if runArg1|=|interact jump #_Menu.chooseOption
        if runArg1|=|leftarrow jump #_Menu.inputLeft
        if runArg1|=|rightarrow jump #_Menu.inputRight

        #checkMenuBackInput
            set menu.temp 0
            if menu.disableExit setadd menu.temp 1
            if menu.stack.size|=|1 setadd menu.temp 1 
            if menu.temp|=|2 msg Cannot exit from this menu.
            if menu.temp|=|2 quit

            if menu.disableBack msg Cannot go back from this menu.
            if menu.disableBack quit

            jump #_Menu.back
        quit

        #checkMenuExitInput
            if menu.disableBack msg Cannot exit from this menu.
            if menu.disableBack quit

            if menu.disableExit msg Cannot exit from this menu.
            if menu.disableExit quit

            jump #Menu.exit
        quit
    quit

    #Menu.exit
        cpemsg announce
        cpemsg bigannounce
        cpemsg smallannounce

        resetdata packages menu.*

        if scene.isActive quit

        cmd tempbot tp tbot.menubars {PlayerX} 0 {PlayerZ} {PlayerYaw} {PlayerPitch}
        cmd tempbot tp tbot.menubars 0 0 0 0 0
        changemodel humanoid

        //This just feels better
        delay 200
        reach 1000
        unfreeze
    quit
quit

#Env
    // • runArg1 is the value fog distance will start at.
    // • runArg2 is the value fog distance will end at.
    // • runArg3 is the delay between fog changes.
    // • runArg4 is the change in distance per iteration until val reaches the goal.
    #Env.interpolateFog
        set fog.val {runArg1}
        set fog.goal {runArg2}
        set fog.delay {runArg3}
        set fog.rate {runArg4}
        if fog.rate|=| set fog.rate 1
        if fog.val|>|fog.goal set fog.condense true
        if fog.val|<|fog.goal set fog.expand true
        #interpolateFogLoop
            env maxfog {fog.val}
            delay {fog.delay}

            if fog.val|=|fog.goal jump #finishInterpolateFog
            if fog.condense call #checkCondenseFog
            if fog.expand call #checkExpandFog

            if fog.goal|>|0 jump #interpolateFogLoop
        quit

        #checkCondenseFog
            setsub fog.val {fog.rate}
            if fog.val|<=|0 set fog.val 1
        quit

        #checkExpandFog
            setadd fog.val {fog.rate}
            if fog.val|>=|fog.goal set fog.val {fog.goal}
        quit

        #finishInterpolateFog
            resetdata packages fog.*
        quit
    quit
quit

#Coord
    //runArgs: coordName, axis, amount to add
    #Coord.Add
        set temp.x 0
        set temp.y 1
        set temp.z 2
        set temp.a {{runArg1}}
        set temp.i {temp.{runArg2}}
        setsplit temp.a " "
        setadd temp.a[{temp.i}] {runArg3}
        set {runArg1} {temp.a[0]} {temp.a[1]} {temp.a[2]}
        resetdata packages temp.*
    quit
    
    //runArgs: coordName1, coordName2, resultName
    #Coord.AddPair
        call #_Coord.Split
        setadd temp.a[0] temp.b[0]
        setadd temp.a[1] temp.b[1]
        setadd temp.a[2] temp.b[2]
        call #_Coord.Merge
    quit
    
    //runArgs: coordName1, coordName2, resultName
    #Coord.SubPair
        call #_Coord.Split
        setsub temp.a[0] temp.b[0]
        setsub temp.a[1] temp.b[1]
        setsub temp.a[2] temp.b[2]
        call #_Coord.Merge
    quit

    #_Coord.Split
        set temp.a {{runArg1}}
        set temp.b {{runArg2}}
        set temp.res {runArg3}
        setsplit temp.a " "
        setsplit temp.b " "
    quit
    #_Coord.Merge
        set {temp.res} {temp.a[0]} {temp.a[1]} {temp.a[2]}
        resetdata packages temp.*
    quit
quit
// ==================================================================
// ==================================================================
#spawnMB
    // args for input
    definehotkey back|Q|async
    definehotkey exit|Q|async shift
    definehotkey interact|E|async
    definehotkey leftarrow|LEFT|async
    definehotkey rightarrow|RIGHT|async

    set back back
    set exit exit
    set interact interact
    set leftarrow leftarrow
    set rightarrow rightarrow

    cmd tempbot add tbot.scenebars1 0 0 0 0 0 https://dl.dropbox.com/s/qn6fbamtqfzix49/cutscene.png empty
    cmd tempbot model tbot.scenebars1 g+cutscene

    cmd tempbot add tbot.scenebars2 0 0 0 0 0 https://dl.dropbox.com/s/qn6fbamtqfzix49/cutscene.png empty
    cmd tempbot model tbot.scenebars2 g+cutscene

    cmd tempbot add tbot.menubars 0 0 0 0 0 https://dl.dropbox.com/s/qn6fbamtqfzix49/cutscene.png empty
    cmd tempbot model tbot.menubars g+cutscene
quit

#Hotkey
    #inputAsync
        if runArg1|=|back jump #_Hotkey.inputBack
        if runArg1|=|exit jump #_Hotkey.inputExit
        if runArg1|=|interact jump #_Hotkey.inputInteract
        if runArg1|=|leftarrow jump #_Hotkey.inputLeft
        if runArg1|=|rightarrow jump #_Hotkey.inputRight
    quit

    #input
    quit

    #_Hotkey.inputBack
        if menu.isOpen jump #Menu.handleInput|back
    quit

    #_Hotkey.inputExit
        if menu.isOpen jump #Menu.handleInput|exit
    quit

    #_Hotkey.inputInteract
        if text.isManual jump #Text.printLine
        if menu.isOpen jump #Menu.handleInput|interact
    quit

    #_Hotkey.inputLeft
        if menu.isOpen jump #Menu.handleInput|leftarrow
    quit

    #_Hotkey.inputRight
        if menu.isOpen jump #Menu.handleInput|rightarrow
    quit
quit

#checkEvenOrOdd
    set checkEven {runArg1}
    setmod checkEven 2
    if checkEven|=|0 set isEven true
    if checkEven|=|1 set isEven false
quit

//runArgs: label to call, total times to loop, delay between loops
#genericLoop
    set labelToCall {runArg1}
    set loopCount {runArg2}
    set loopDelay {runArg3}
    
    set index 0
    #genericLoopStart
        call {labelToCall}|{index}
        delay loopDelay
        setadd index 1
        if index|<|loopCount jump #genericLoopStart
    quit
quit

// ==================================================================
// ==================================================================
// ==================================================================
#testText
    set q.text.intro[0] %6a sound
    set q.text.intro[1] %6that has no finish
    set q.text.intro[2] %6and no beginning
    set q.text.intro[3] %6but persists
    set q.text.intro[4] %6as the eternal drone

    //correct call
    msg %eNORMAL
    call #Text.print|q.text.intro
    //correct call fast
    msg %eFAST
    call #Text.print|q.text.intro|20
    //correct call slow
    msg %eMANUAL
    call #Text.print|q.text.intro|true
quit

#testIterateText
    set homer[0] %7Sing in me, Muse, and through me tell the story
    set homer[1] %7of that man skilled in all ways of contending,
    set homer[2] %7the wanderer, harried for years on end,
    set homer[3] %7after he plundered the stronghold
    set homer[4] %7on the proud height of Troy.
    call #Text.printScrolling|homer
quit

#testIterateTextManual
    set homer[0] %aSing in me, %6Muse%a, and through me tell the story
    set homer[1] %aof that man skilled in all ways of contending,
    set homer[2] %athe wanderer, harried for years on end,
    set homer[3] %aafter he plundered the stronghold
    set homer[4] %aon the proud height of Troy.

    set homer.charList A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z

    call #Text.printScrolling|homer|true|homer.charList
quit

#testScene
    set q.scene.intro 64 65 64 180 5
    set q.scene.intro2 56 68 74 153 8
    set endCoords 72 64 90 324 0

    call #Scene.switch|q.scene.intro
    delay 3000
    call #Scene.switch|q.scene.intro2
    delay 3000
    call #Scene.exit|endCoords
quit

#testMenu
    set mainMenu.superName extra display line goes here
    set mainMenu.name menu name here
    set mainMenu.options map|journal|fast travel|stats|hi-scores|exit
    set mainMenu.labels #openMap|#openJournal|#openTravel|#openStats|#openHighScores|#openMenuExit

    jump #Menu.open|mainMenu
quit

#openMap
    msg selected #openMap
    call #Menu.exit
quit

#openJournal
    msg selected #openJournal

    set journalMenu.superName this time it's a submenu
    set journalMenu.name another menu example
    set journalMenu.options letters|sentences|words
    set journalMenu.labels #openLetters|#openSentences|#openWords

    jump #Menu.open|journalMenu
quit

#openLetters
    set journalMenu.name letters submenu
    jump #Menu.open|journalMenu
quit

#openSentences
    set journalMenu.name sentences submenu
    jump #Menu.open|journalMenu
quit

#openWords
    set journalMenu.name words submenu
    jump #Menu.open|journalMenu
quit

#openTravel
    msg selected #openTravel
    call #Menu.exit
quit

#openStats
    msg selected #openStats
    call #Menu.exit
quit

#openHighScores
    msg selected #openHighScores
    call #Menu.exit
quit

#openMenuExit
    msg #openMenuExit
    call #Menu.exit
quit

#testFog
    call #Env.interpolateFog|1000|1|1
    delay 1000
    call #Env.interpolateFog|1|1000|1
quit

#testSequence
    set text.example[0] Rise and shine, Mister Freeman. Rise and... shine.
    set text.example[1] Not that I... wish to imply you have been sleeping on the job. 
    set text.example[2] No one is more deserving of a rest... 
    set text.example[3] and all the effort in the world would have gone to waste until...
    set text.example[4] well, let's just say your hour has... come again.
    set text.example[5] The right man in the wrong place... 
    set text.example[6] Can make all the difference in the world.
    set text.example[7] So, wake up, Mister Freeman. 
    set text.example[8] Wake up and... smell the ashes...
    set q.scene.example 82 66 89 90 0

    set ▌ ▌

    call #Scene.switch|q.scene.example
    delay 1000
    call #Text.printScrolling|text.example|true|▌
    delay 2000
    call #Env.interpolateFog|1000|1|1
    delay 2000
    call #Scene.exit
    delay 2000
    call #Env.interpolateFog|1|1000|1
quit

#testDialogue
    set testDialogue.scene 36 67 86 64 8

    set testDialogue.text[0] Psst, kid.
    set testDialogue.text[1] Follow me.
    set testDialogue.text[2] I got something to show you.

    set testDialogue.menu.superName
    set testDialogue.menu.name
    set testDialogue.menu.options Get away, freak|Yeah, sounds cool
    set testDialogue.menu.labels #dialogueDunno|#dialogueCool

    call #Scene.switch|testDialogue.scene
    delay 1000
    call #Text.printScrolling|testDialogue.text|true
    call #Menu.open|testDialogue.menu|true
quit

#dialogueDunno
    set dunnoDialogue.text[0] A meek resistance.
    set dunnoDialogue.text[1] Your regret wears heavy.
    set dunnoDialogue.text[2] If not today, then tomorrow.
    set dunnoDialogue.text[3] See you soon...

    set dunnoDialogue.menu.superName
    set dunnoDialogue.menu.name
    set dunnoDialogue.menu.options Get a job, hippie|I changed my mind
    set dunnoDialogue.menu.labels #dialogueHippie|#dialogueCool

    call #Text.printScrolling|dunnoDialogue.text|true
    call #Menu.open|dunnoDialogue.menu|true
quit

#dialogueCool
    set coolDialogue.text[0] Most excellent.
    set coolDialogue.text[1] You won't regret it.
    set coolDialogue.text[2] Now if you would follow me into this alleyway...

    call #Text.printScrolling|coolDialogue.text|true
    call #Scene.exit
    call #Menu.exit
quit

#dialogueHippie
    set dialogueHippie.text[0] So it goes.
    call #Text.printScrolling|dialogueHippie.text|true
    call #Scene.exit
    call #Menu.exit
quit

#show
    show every single package
    msg %e------------------------------------
quit
