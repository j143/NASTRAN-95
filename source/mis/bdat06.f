      SUBROUTINE BDAT06
C
C     THIS SUBROUTINE PROCESSES THE GTRAN BULK DATA
C
      EXTERNAL        RSHIFT,ANDF
      LOGICAL         PRINT,TDAT
CWKBI 8/94 ALPHA-VMS
      INTEGER         GEOM4, SCR1
      INTEGER         SCR2,BUF3,SCBDAT,BUF2,BUF1,GTRAN(2),FLAG,ID(5),
     1                COMBO,SCORE,Z,AAA(2),OUTT,BUF4,ANDF,RSHIFT,IHD(96)
      CHARACTER       UFM*23
      COMMON /XMSSG / UFM
      COMMON /ZZZZZZ/ Z(1)
      COMMON /CMB001/ SCR1,SCR2,SCBDAT,SCSFIL,SCCONN,SCMCON,
     1                SCTOC,GEOM4,CASECC
      COMMON /CMB002/ BUF1,BUF2,BUF3,BUF4,BUF5,SCORE,LCORE,INPT,OUTT
      COMMON /CMB003/ COMBO(7,5),CONSET,IAUTO,TOLER,NPSUB,CONECT,TRAN,
     1                MCON,RESTCT(7,7),ISORT,ORIGIN(7,3),IPRINT
      COMMON /CMB004/ TDAT(6)
      COMMON /CMBFND/ INAM(2),IERR
      COMMON /OUTPUT/ ITITL(96),IHEAD(96)
      COMMON /BLANK / STEP,IDRY
      DATA   GTRAN  / 1510,15 / , AAA/ 4HBDAT,4H06   /
      DATA   IHD  / 11*4H    ,4H  SU,4HMMAR,4HY OF,4H PRO,4HCESS,4HED G,
     1       4HTRAN,4H BUL,4HK DA,4HTA  ,19*4H    ,4H PSE,4HUDO-,4H    ,
     2       4H    ,4H COM,4HPONE,4HNT  ,4H    ,4H   T,4HRANS,2*4H     ,
     3       4HGRID,4H    ,4HREFE,4HRENC,4HE   ,14*4H    ,4H  ST,4HRUCT,
     4       4HURE ,4HNO. ,4H   S,4HTRUC,4HTURE,4H NO.,4H    ,4H  SE   ,
     5       4HT ID,2*4H    ,4H ID ,4H    ,4HTRAN,4HS  I,4HD   ,7*2H   /
C
      IFILE = SCR1
      KK    = 0
      PRINT = .FALSE.
      IF (ANDF(RSHIFT(IPRINT,5),1) .EQ. 1) PRINT = .TRUE.
      DO 10 I = 1,96
      IHEAD(I) = IHD(I)
   10 CONTINUE
      CALL OPEN (*100,SCR2,Z(BUF3),1)
      IFILE = SCBDAT
      CALL LOCATE (*80,Z(BUF1),GTRAN,FLAG)
      IF (PRINT) CALL PAGE
      IFILE = GEOM4
   20 CALL READ (*110,*60,GEOM4,ID,1,0,N)
      DO 30 I = 1,NPSUB
      IF (ID(1) .EQ. COMBO(I,3)) GO TO 40
   30 CONTINUE
      CALL READ (*110,*120,GEOM4,ID,-4,0,N)
      GO TO 20
   40 TDAT(6) = .TRUE.
      KK = KK + 1
      CALL READ (*110,*120,GEOM4,ID(2),4,0,N)
      CALL FINDER (ID(2),IS,IC)
      IF (IERR .NE. 1) GO TO 50
      WRITE (OUTT,210) UFM,ID(2),ID(3)
      IDRY = -2
   50 CONTINUE
      IF (PRINT) CALL PAGE2 (1)
      IF (PRINT) WRITE (OUTT,200) IS,IC,ID(1),ID(4),ID(5)
      ID(3) = ID(1)
      ID(1) = IS
      ID(2) = IC
      ID(4) = IC*1000000 + ID(4)
      Z(BUF4+KK) = ID(5)
      CALL WRITE (SCR2,ID,5,0)
      GO TO 20
   60 CALL WRITE (SCR2,ID,0,1)
      CALL CLOSE (SCR2,1)
      IF (.NOT.TDAT(6)) GO TO 80
      IFILE = SCR2
      CALL OPEN (*100,SCR2,Z(BUF3),2)
      CALL READ (*110,*70,SCR2,Z(SCORE),LCORE,0,NN)
      GO TO 130
   70 CALL SORT (0,0,5,1,Z(SCORE),NN)
      CALL WRITE (SCBDAT,Z(SCORE),NN,1)
   80 CALL EOF (SCBDAT)
      Z(BUF4) = KK
      CALL CLOSE (SCR2,1)
      IF (PRINT) CALL PAGE2 (3)
      IF (PRINT) WRITE (OUTT,220)
      RETURN
C
  100 IMSG = -1
      GO TO 140
  110 IMSG = -2
      GO TO 140
  120 IMSG = -3
      GO TO 140
  130 IMSG = -8
  140 CALL MESAGE (IMSG,IFILE,AAA)
      RETURN
C
  200 FORMAT (36X,I1,14X,I5,8X,I8,4X,I8,4X,I8)
  210 FORMAT (A23,' 6530, THE BASIC SUBSTRUCTURE ',2A4, /30X,
     1       'REFERED TO BY A GTRAN BULK DATA CARD WHICH CANNOT BE ',
     2       'FOUNDD IN THE PROBLEM TABLE OF CONTENTS.')
  220 FORMAT (/5X,'NOTE - THE PSEUDOSTRUCTURE AND COMPONENT NUMBERS RE',
     1       'FER TO THEIR POSITIONS IN THE PROBLEM TABLE OF CONTENTS.')
      END
