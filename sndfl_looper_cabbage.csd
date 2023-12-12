<Cabbage>
form caption("Untitled") size(1150, 300),pluginId("lop1"), colour(50, 50, 50)

soundfiler bounds(4, 4, 1050, 140), channel("beg","len"), identChannel("filer"),  colour(0, 255, 255, 255), fontColour(160, 160, 160, 255)
label bounds(6, 4, 560, 14), align("left"), fontColour(200, 200, 200, 255), identChannel("stringbox") channel("label28")
filebutton bounds(1062, 4, 80, 25), text("Open File", "Open File"),  channel("filename"), shape("ellipse")

rslider bounds(186, 220, 70, 70), channel("kSize"), range(0.001, 1, 0.1, 0.5, 0.0001),text("Size"), textColour(0, 1, 1, 255) trackerColour(87, 223, 246, 255) colour(142, 143, 142, 255)
rslider bounds(1068, 34, 70, 70), channel("kAmp"), range(-90, 0, -12, 0.5, 0.5),text("Volume"), textColour(0, 1, 1, 255) trackerColour(87, 223, 246, 255) colour(142, 143, 142, 255)
rslider bounds(266, 220, 70, 70), channel("kDevStart"), range(0, 0.999, 0, 0.5, 0.001),text("Dev. Start"), textColour(0, 1, 1, 255) trackerColour(87, 223, 246, 255) colour(142, 143, 142, 255)
rslider bounds(346, 220, 70, 70), channel("kDevSize"), range(0, 0.999, 0, 0.5, 0.001),text("Dev. Size"), textColour(0, 1, 1, 255) trackerColour(87, 223, 246, 255) colour(142, 143, 142, 255)
nslider bounds(12, 230, 70, 50) channel("kSpeed") range(-2, 2, 1, 0.5, 0.01) text("Speed")
nslider bounds(92, 230, 70, 50) channel("kOffset") range(0, 1, 1, 1, 0.01) text("Offset")
hslider bounds(2, 142, 1059, 50) channel("kStart") range(0, 1, 0, 1, 0.001) textColour(0, 1, 1, 255) trackerColour(87, 223, 246, 255) colour(142, 143, 142, 255)

combobox bounds(1042, 194, 93, 32) channel("kWndw") text("Hamming", "Hanning", "ExpRamp", "Sharp", "Smooth") value(1) 
label bounds(972, 280, 177, 16) channel("label10011") text("by philipp von neumann")
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0
</CsOptions>
<CsInstruments>
ksmps = 32
nchnls = 2
0dbfs = 1 

opcode FileNameFromPath,S,S        ; Extract a file name (as a string) from a full path (also as a string)
 Ssrc    xin                ; Read in the file path string
 icnt    strlen    Ssrc            ; Get the length of the file path string
 LOOP:                    ; Loop back to here when checking for a backslash
 iasc    strchar Ssrc, icnt        ; Read ascii value of current letter for checking
 if iasc==92 igoto ESCAPE        ; If it is a backslash, escape from loop
 loop_gt    icnt,1,0,LOOP        ; Loop back and decrement counter which is also used as an index into the string
 ESCAPE:                ; Escape point once the backslash has been found
 Sname    strsub Ssrc, icnt+1, -1        ; Create a new string of just the file name
    xout    Sname            ; Send it back to the caller instrument
endop

opcode sndfl_looper, aa, Skkkki
  SFile, kSpeed, kLoopStart, kLoopSize, kStereoOffset, iWndwFt xin
  setksmps 1
  ;; read data from soundfil
  iSndflSec filelen SFile
  iSndflSr filesr SFile
  iSndflSamps = iSndflSec*iSndflSr
  
  ;; create the tables for the soundfile
  iSndflNumChnls filenchnls SFile
  if iSndflNumChnls == 1 then
    iSndflTbl1 ftgen 0,0,0,1,SFile,0,0,1
    iSndflTbl2 = iSndflTbl1 
  elseif iSndflNumChnls == 2 then
    iSndflTbl1 ftgen 0,0,0,1,SFile,0,0,1
    iSndflTbl2 ftgen 0,0,0,1,SFile,0,0,2
  endif

  ;; parameter for the table reading
  kChange changed kStereoOffset
  if kChange == 1 then
    reinit UPDATE
  endif

  kSpeed = kSpeed
  kStart = (kLoopStart*iSndflSamps)
  kSize = kLoopSize*iSndflSamps
  kPhasorSpeed = kSpeed/(kSize/iSndflSr)
  aSyncIn init 0
  aSyncOut1 init 1
  aSyncOut2 init 1
  kPhasorSpeed1 = (k(aSyncOut1) == 1 ? kPhasorSpeed : kPhasorSpeed1)
  kPhasorSpeed2 = (k(aSyncOut2) == 1 ? kPhasorSpeed : kPhasorSpeed2)

  UPDATE:
    aIndex1,aSyncOut1 syncphasor kPhasorSpeed1,aSyncIn
    aIndex2,aSyncOut2 syncphasor kPhasorSpeed2,aSyncIn,i(kStereoOffset)
    kSize1 = (k(aSyncOut1) == 1 ? kSize : kSize1)
    kSize2 = (k(aSyncOut2) == 1 ? kSize : kSize2)
    kStart1 = (k(aSyncOut1) == 1 ? kStart : kStart1)
    kStart2 = (k(aSyncOut2) == 1 ? kStart : kStart2)
    aSndfl1 table (aIndex1*kSize1)+kStart1,iSndflTbl1,0,0,1
    aSndfl2 table (aIndex2*kSize2)+kStart2,iSndflTbl2,0,0,1
    aWin1 table aIndex1,iWndwFt,1
    aWin2 table aIndex2,iWndwFt,1

    ;; output
    aSndfl1 *= aWin1
    aSndfl2 *= aWin2
    xout aSndfl1,aSndfl2 
endop

instr 1
    gSndFl chnget "filename"
    gkSpeed chnget "kSpeed"
    gkStart chnget "kStart"
    gkSize chnget "kSize"
    gkOffset chnget "kOffset"
    gkAmp chnget "kAmp"
    gkDevStart chnget "kDevStart"
    gkDevSize chnget "kDevSize"
    if changed:k(gSndFl)==1 then
        turnoff2 2,0,0
        event "i",99,0,0
        event "i",2,0,216000
    endif
     
  kWndw chnget "kWndw"   
  printks2 "kWndw: %d\n",kWndw
  giWndw ftgen 1000,0,4096,10,1
  iWndwCol ftgen 100,0,6,-2,1,2,3,4,5,5

  iHamming ftgen 1,0,4096,20,1,1
  iHanning ftgen 2,0,4096,20,2,1
  iExpRamp ftgen 3,0,4096,5,0.0001,2048,1,2048,0.0001
  iSharp ftgen 4,0,4096,5,1,4095,0.00001
  iSmooth ftgen 5,0,4096,7,0,100,1,3896,1,100,0
  
  ftmorf kWndw-1,100,giWndw
endin

instr 2
    
  iWndwFt = giWndw
  
  kDevStart = random:k(1-gkDevStart,1+gkDevStart)
  kStart = gkStart*kDevStart
  
  kDevSize = random:k(1-gkDevSize,1+gkDevSize)
  kSize = gkSize*kDevSize
  aSig1,aSig2 sndfl_looper gSndFl,gkSpeed,kStart,kSize,gkOffset,iWndwFt  
  
  ;; output
  aOut1 = aSig1*ampdbfs(gkAmp)
  aOut2 = aSig2*ampdbfs(gkAmp)  
  outs aOut1,aOut2
endin

instr 99
 Smessage sprintfk "file(%s)", gSndFl            ; print sound file image to fileplayer
 chnset Smessage, "filer"
 
 Sname FileNameFromPath gSndFl                ; Call UDO to extract file name from the full path
 Smessage sprintfk "text(%s)",Sname                ; create string to update text() identifier for label widget
 chnset Smessage, "stringbox"                    ; send string to  widget

endin
</CsInstruments>
<CsScore>
i1 0 z

</CsScore>
</CsoundSynthesizer>
;;; by philipp von neumann