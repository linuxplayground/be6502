10 RAM=$7F40
20 REG=$7F41
25 CALL $8388
26 50 X=7:VAL=$1F:GOSUB 2000
30 POKE REG,$00:POKE REG,$40
40 FOR N=0TO980:POKE RAM,127:NEXT N
100 Y=12:D=0
110 FOR X = 0 TO 39
120 GOSUB 1000
130 NEXT X
140 X=20:D=1
145 FOR Y=0 TO 23:GOSUB 1000: NEXT Y
200 X=0:Y=0:D=3:GOSUB 1000
210 X=39:Y=0:D=2:GOSUB 1000
220 X=0:Y=23:D=5:GOSUB 1000
230 X=39:Y=23:D=4:GOSUB 1000
250 X=20:Y=12:D=6:GOSUB 1000
300 Y=0:D=0:FOR X=1TO38:GOSUB 1000:NEXT X
310 Y=23:D=0:FOR X=1TO38:GOSUB 1000:NEXT X
320 X=0:D=1:FOR Y=1TO22:GOSUB 1000:NEXT Y
330 X=39:D=1:FOR Y=1TO22:GOSUB 1000:NEXT Y
999 END
1000 REM PLOT X,Y,D
1001 REM X=COL,Y=ROW,D=CHAR
1010 CELL=Y*40+X
1020 CH = CELL >> 8: CH = CH + 64
1030 CL = CELL AND 255
1040 POKE REG,CL:POKE REG,CH
1050 POKE RAM,D
1055 FOR N=1TO5:NEXT N
1080 RETURN
2000 REM SET REGISTER
2010 REM X = REGISTER, VAL = VALUE
2020 POKE REG,VAL:POKE REG,X + 128
2030 RETURN
