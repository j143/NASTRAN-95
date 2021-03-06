      SUBROUTINE FERXTD (V1,V2,V3,V4,V5,ZB,IFN)
C
C     FERXTD is a modification of the old subroutine FNXTVC.  The
C     modification allows for reading the orthogonal vectors and the
C     SMA and LT matrices from memory instead of from files.  The
C     SMA and LT matrices may be partially in memory and part read
C     from the file.
C     FERXTD OBTAINS THE REDUCED TRIDIAGONAL MATRIX B WHERE FERFBD
C     PERFORMS THE OPERATIONAL INVERSE.   (DOUBLE PREC VERSION)
C
C           T   -
C      B = V  * A  * V
C
C     V1  = SPACE FOR THE PREVIOUS CURRENT TRIAL VECTOR. INITALLY NULL
C     V2  = SPACE FOR THE CURRENT TRIAL VECTOR. INITIALLY A PSEUDO-
C           RANDOM START VECTOR
C     V3,V4,V5 = WORKING SPACES FOR THREE VECTORS
C     IFN = NO. OF TRIAL VECOTRS EXTRACTED. INITIALLY ZERO.
C     SEE FEER FOR DEFINITIONS OF OTHER PARAMETERS. ALSO PROGRAMMER'S
C           MANUAL PP. 4.48-19G THRU I
C
C     REAL*16, MARKED BY 'CQ', WAS TRIED FOR IMPROVED ACCURACY. BUT THE
C     REAL*16  OPERATIONS ON VAX WERE 10 TIMES SLOWER THAN REAL*8
C     (NUMERIC ACCURACY IS VERY IMPORTANT IN THIS SUBROUTINE)
C
      INTEGER            SYSBUF    ,CNDFLG   ,SR5FLE   ,NAME(5)  ,
     1                   VCDOT     ,SMAPOS   ,EOFNRW
      DOUBLE PRECISION   V1(1)     ,V2(1)    ,V3(1)    ,V4(1)    ,
     1                   V5(1)     ,LMBDA    ,LAMBDA   ,B(2)     ,
     2                   ZERO      ,ZB(1)
CQ    REAL*16            D         ,DB       ,DSQ      ,SD       ,
      DOUBLE PRECISION   ZD
      DOUBLE PRECISION   D         ,DB       ,DSQ      ,SD       ,
     1                   AII       ,DBI      ,DEPX     ,DEPX2    ,
     2                   SDMAX     ,DTMP     ,OPDEPX   ,OMDEPX
      CHARACTER          UFM*23    ,UWM*25
      COMMON   /ZZZZZZ/  ZD(1)
      COMMON   /FEERIM/  NIDSMA    ,NIDLT    ,NIDORV   ,NLTLI
     1,                  NSMALI    ,IBFSMA   ,IBFLT
     2,                  IBFORV    ,SMAPOS(7),LTPOS(7)
      COMMON   /XMSSG /  UFM       ,UWM
      COMMON   /FEERCX/  IFKAA(7)  ,IFMAA(7) ,IFLELM(7),IFLVEC(7),
     1                   SR1FLE    ,SR2FLE   ,SR3FLE   ,SR4FLE   ,
     2                   SR5FLE    ,SR6FLE   ,SR7FLE   ,SR8FLE   ,
     3                   DMPFLE    ,NORD     ,XLMBDA   ,NEIG     ,
     4                   MORD      ,IBK      ,CRITF    ,NORTHO   ,
     5                   IFLRVA    ,IFLRVC
      COMMON   /FEERXX/  LAMBDA    ,CNDFLG   ,ITER     ,TIMED    ,
     1                   L16       ,IOPTF    ,EPX      ,ERRC     ,
     2                   IND       ,LMBDA    ,IFSET    ,NZERO    ,
     3                   NONUL     ,IDIAG    ,MRANK    ,ISTART
      COMMON   /SYSTEM/  KSYSTM(65)
      COMMON   /OPINV /  MCBLT(7)  ,MCBSMA(7),MCBVEC(7),MCBRM(7)
      COMMON   /UNPAKX/  IPRC      ,II       ,NN       ,INCR
      COMMON   /PACKX /  ITP1      ,ITP2     ,IIP      ,NNP      ,
     1                   INCRP
      COMMON   /NAMES /  RD        ,RDREW    ,WRT      ,WRTREW   ,
     1                   REW       ,NOREW    ,EOFNRW
      EQUIVALENCE        (KSYSTM(1),SYSBUF)  ,(KSYSTM(2),IO)
      DATA      NAME  /  4HFERX    ,4HTD     ,2*4HBEGN ,4HEND    /
      DATA      VCDOT ,  ZERO /     4HVC.    ,0.0D+0             /
C
C     SR5FLE CONTAINS THE REDUCED TRIDIAGONAL ELEMENTS
C
C     SR6FLE CONTAINS THE G VECTORS
C     SR7FLE CONTAINS THE ORTHOGONAL  VECTORS
C     SR8FLE CONTAINS THE CONDITIONED MAA MATRIX
C
      IF (MCBLT(7) .LT. 0) NAME(2) = VCDOT
      NAME(3) = NAME(4)
      CALL CONMSG (NAME,3,0)
      ITER  = ITER + 1
      IPRC  = 2
      INCR  = 1
      INCRP = INCR
      ITP1  = IPRC
      ITP2  = IPRC
      IFG   = MCBRM(1)
      IFV   = MCBVEC(1)
      DEPX  = EPX
      DEPX2 = DEPX**2
      OPDEPX= 1.0D+0 + DEPX
      OMDEPX= 1.0D+0 - DEPX
CQ    OPDEPX= 1.0Q+0 + DEPX
CQ    OMDEPX= 1.0Q+0 - DEPX
      D     = ZERO
      NORD1 = NORD - 1
C
C     NORMALIZE START VECTOR
C
      DSQ = ZERO
      IF (IOPTF .EQ. 1) GO TO 20
      CALL FERLTD (MCBSMA(1),V2(1),V3(1),V5(1))
      DO 10 I = 1,NORD
   10 DSQ = DSQ + V2(I)*V3(I)
      GO TO 40
   20 DO 30 I = 1,NORD
   30 DSQ = DSQ + V2(I)*V2(I)
   40 DSQ = 1.0D+0/DSQRT(DSQ)
CQ 40 DSQ = 1.0D+0/QSQRT(DSQ)
      DO 50 I = 1,NORD
   50 V2(I) = V2(I)*DSQ
      IF (NORTHO .EQ. 0) GO TO 200
C
C     ORTHOGONALIZE WITH PREVIOUS VECTORS
C
      DO 60 I = 1,NORD
   60 V3(I) = V2(I)
C
C     READ ORTHOGONAL VECTORS INTO MEMORY IF SPACE EXISTS
C
      IF ( NIDORV .EQ. 0 ) GO TO 70
      IF ( NORTHO .EQ. 0 ) GO TO 70
      CALL GOPEN ( IFV, ZB(1), RDREW )
      II = 1
      NN = NORD
      NIDX = NIDORV/2 + 1 
      DO 65 IC = 1, NORTHO
      ILOC = ( IC-1 ) * NORD + NIDX
      CALL UNPACK ( *65, IFV, ZD( ILOC ) )
   65 CONTINUE
      CALL CLOSE ( IFV, EOFNRW )
C
C     BEGINNING OF ITERATION LOOP
C   
   70 DO 170 IX = 1,14
      NONUL = NONUL + 1
      IF (IOPTF .EQ. 0) 
     &  CALL FERLTD (MCBSMA(1),V2(1),V3(1),V5(1))
      IF ( NIDORV .NE. 0 ) GO TO 1000
C     
C  READ ORTHOGONAL VECTORS FROM FILE
C
      CALL GOPEN (IFV,ZB(1),RDREW)        
      SDMAX = ZERO
      DO 110 IY = 1,NORTHO
      II = 1
      NN = NORD
      SD = ZERO
      CALL UNPACK (*90,IFV,V5(1))
      DO 80 I = 1,NORD
      SD = SD + V3(I)*V5(I)
   80 CONTINUE
   90 IF (DABS(SD) .GT. SDMAX) SDMAX = DABS(SD)
CQ 90 IF (QABS(SD) .GT. SDMAX) SDMAX = QABS(SD)
      DO 100 I = 1,NORD
  100 V2(I) = V2(I) - SD*V5(I)
  110 CONTINUE
      CALL CLOSE (IFV,EOFNRW)
      GO TO 2000
C
C ORTHOGONAL VECTORS ARE IN MEMORY
C 
 1000 CONTINUE
      SDMAX = ZERO
      NIDX  = NIDORV/2 + 1 
      DO 1110 IY = 1, NORTHO
      SD    = ZERO
      ILOC  = (IY-1)*NORD + NIDX - 1 
      DO 1080 I = 1, NORD
      SD    = SD + V3(I)*ZD(ILOC+I)
 1080 CONTINUE
      IF ( DABS( SD ) .GT. SDMAX ) SDMAX = DABS( SD )
      DO 1100 I = 1, NORD
      V2(I) = V2(I) - SD*ZD(ILOC+I)
 1100 CONTINUE
 1110 CONTINUE
 2000 CONTINUE
      DSQ = ZERO
      IF (IOPTF .EQ. 1) GO TO 130
      CALL FERLTD (MCBSMA(1),V2(1),V3(1),V5(1))
      DO 120 I = 1,NORD1
  120 DSQ = DSQ + V2(I)*V3(I)
      GO TO 150
  130 DO 140 I = 1,NORD1
  140 DSQ = DSQ + V2(I)*V2(I)
C
C 150 IF (DSQ .LT. DEPX2) GO TO 500
C
C     COMMENTS FORM G.CHAN/UNISYS ABOUT DSQ AND DEPX2 ABOVE,   1/92
C
C     DEPX2 IS SQUARE OF EPX. ORIGINALLY SINCE DAY 1, EPX (FOR VAX AND
C     IBM) IS 10.**-14 AND THEREFORE DEPX2 = 10.**-28. (10.**-24 FOR
C     THE 60/64 BIT MACHINES, USING S.P. COMPUTATION)
C     (EPX WAS SET TO 10.**-10 FOR ALL MACHINES, S.P. AND D.P., 1/92)
C
C     NOTICE THAT DSQ IS THE DIFFERENCE OF TWO CLOSE NUMERIC NUMBERS.
C     THE FINAL VAULES OF DSQ AND THE PRODUCT OF V2*V2 OR V2*V3 APPROACH
C     ONE ANOTHER, AND DEFFER ONLY IN SIGN. THEREFORE, THE NUMBER OF
C     DIGITS (MANTISSA) AS WELL AS THE EXPONENT ARE IMPORTANT HERE
C     (PREVIOUSLY, DO LOOPS 120 AND 140 COVERED 1 THRU NORD)
C
C     MOST OF THE 32 BIT MACHINES HOLD 15 DIGIT IN D.P. WORD, AND SAME
C     FOR THE 64 BIT MACHINES USING S.P. WORD. THEREFORE, CHECKING DSQ
C     DOWN TO 10.**-28 (OR 10.**-24) IS BEYOND THE HARDWARE LIMITS.
C     THIS MAY EXPLAIN SOME TIMES THE RIGID BODY MODES (FREQUENCY = 0.0)
C     GO TO NEGATIVE; IN SOME INSTANCES REACHING -1.E+5 RANGE
C
C     NEXT 7 LINES TRY TO SOLVE THE ABOVE DILEMMA
C
  150 D = V3(NORD)
      IF (IOPTF .EQ. 1) D = V2(NORD)
      D = V2(NORD)*D
      DTMP = DSQ
      DSQ  = DSQ + D
      IF (DSQ .LT. DEPX2) GO TO 500
      DTMP = DABS(D/DTMP)
CQ    DTMP = QABS(D/DTMP)
      IF (DTMP.GT.OMDEPX .AND. DTMP.LT.OPDEPX) GO TO 500
      D = ZERO
C
      DSQ = DSQRT(DSQ)
CQ    DSQ = QSQRT(DSQ)
      IF (L16 .NE. 0) WRITE (IO,620) IX,SDMAX,DSQ
      DSQ = 1.0D+0/DSQ
      DO 160 I = 1,NORD
      V2(I) = V2(I)*DSQ
  160 V3(I) = V2(I)
      IF (SDMAX .LT. DEPX) GO TO 200
  170 CONTINUE
C
      GO TO 500
  200 IF (IFN .NE. 0) GO TO 300
C
C     SWEEP START VECTOR FOR ZERO ROOTS
C
      DSQ = ZERO
      IF (IOPTF .EQ. 1) GO TO 220
      CALL FERSWD (V2(1),V3(1),V5(1))
      CALL FERLTD (MCBSMA(1),V3(1),V4(1),V5(1))
      DO 210 I = 1,NORD
  210 DSQ = DSQ + V3(I)*V4(I)
      GO TO 240
  220 CONTINUE
      CALL FERFBD (V2(1),V4(1),V3(1),V5(1))
      DO 230 I = 1,NORD
  230 DSQ = DSQ + V3(I)*V3(I)
  240 DSQ = 1.0D+0/DSQRT(DSQ)
CQ240 DSQ = 1.0D+0/QSQRT(DSQ)
      DO 250 I = 1,NORD
  250 V2(I) = V3(I)*DSQ
      GO TO 320
C
C     CALCULATE OFF DIAGONAL TERM OF B
C
  300 D = ZERO
      DO 310 I = 1,NORD
  310 D = D + V2(I)*V4(I)
C
C     COMMENTS FROM G.CHAN/UNISYS 1/92
C     WHAT HAPPENS IF D IS NEGATIVE HERE? NEXT LINE WOULD BE ALWAY TRUE.
C
      IF (D .LT. DEPX*DABS(AII)) GO TO 500
CQ    IF (D .LT. DEPX*QABS(AII)) GO TO 500
  320 CALL GOPEN (IFG,ZB(1),WRT)
      IIP = 1
      NNP = NORD
      IF (IOPTF .EQ. 1) GO TO 330
      CALL FERSWD (V2(1),V3(1),V5(1))
      CALL FERLTD (MCBSMA(1),V3(1),V4(1),V5(1))
      CALL PACK (V2(1),IFG,MCBRM(1))
      GO TO 350
  330 CONTINUE
      CALL FERFBD (V2(1),V4(1),V3(1),V5(1))
      CALL PACK (V4(1),IFG,MCBRM(1))
      DO 340 I = 1,NORD
  340 V4(I) = V3(I)
  350 CALL CLOSE (IFG,NOREW)
C
C     CALCULATE DIAGONAL TERM OF B
C
      AII = ZERO
      DO 400 I = 1,NORD
  400 AII = AII + V2(I)*V4(I)
      IF (D .EQ. ZERO) GO TO 420
      DO 410 I = 1,NORD
  410 V3(I) = V3(I) - AII*V2(I) - D*V1(I)
      GO TO 440
  420 DO 430 I = 1,NORD
  430 V3(I) = V3(I) - AII*V2(I)
  440 DB = ZERO
      IF (IOPTF .EQ. 1) GO TO 460
      CALL FERLTD (MCBSMA(1),V3(1),V4(1),V5(1))
      DO 450 I = 1,NORD
  450 DB = DB + V3(I)*V4(I)
      GO TO 480
  460 DO 470 I = 1,NORD
  470 DB = DB + V3(I)*V3(I)
  480 DB = DSQRT(DB)
CQ480 DB = QSQRT(DB)
      ERRC = SNGL(DB)
      B(1) = AII
      B(2) = D
      CALL WRITE (SR5FLE,B(1),4,1)
      IF ( NIDORV .NE. 0 ) GO TO 3000
      CALL GOPEN (IFV,ZB(1),WRT)
      IIP  = 1
      NNP  = NORD
      CALL PACK (V2(1),IFV,MCBVEC(1))
      CALL CLOSE (IFV,NOREW)
      GO TO 4000
3000  CONTINUE
      NIDX = NIDORV/2 + 1 
      ILOC = NORTHO * NORD + NIDX
      DO 3100 I = IIP, NNP
      ZD( ILOC+I-1 ) = V2( I )
3100  CONTINUE
4000  CONTINUE
      NORTHO = NORTHO + 1
      IFN  = NORTHO - NZERO
      IF (L16 .NE. 0) WRITE (IO,610) IFN,MORD,AII,DB,D
      IF ( IFN .LT. MORD ) GO TO 6000
C
C NEED TO SAVE ORTHOGONAL VECTORS BACK TO FILE
C
      CALL GOPEN ( IFV, ZB(1), WRT ) 
      IIP  = 1
      NNP  = NORD
      NIDX = NIDORV/2 + 1 
      DO 5000 I = 1, NORTHO
      ILOC = (I-1)*NORD + NIDX
      CALL PACK ( ZD( ILOC ), IFV, MCBVEC(1) )
5000  CONTINUE
      CALL CLOSE ( IFV, NOREW )
6000  CONTINUE
      IF (IFN .GE. MORD) GO TO 630
C
C     IF NULL VECTOR GENERATED, RETURN TO OBTAIN A NEW SEED VECTOR
C
      IF (DB .LT. DEPX*DABS(AII)) GO TO 630
C
C     A GOOD VECTOR IN V2. MOVE IT INTO 'PREVIOUS' VECTOR SPACE V1,
C     NORMALIZE V3 AND V2. LOOP BACK FOR MORE VECTORS.
C
      DBI = 1.0D+0/DB
      DO 490 I = 1,NORD
      V1(I) = V2(I)
      V3(I) = V3(I)*DBI
  490 V2(I) = V3(I)
      GO TO 70
C
  500 MORD = IFN
      WRITE (IO,600) UWM,MORD
      GO TO 630
C
  600 FORMAT (A25,' 2387, PROBLEM SIZE REDUCED TO',I5,' DUE TO -', /5X,
     1        'ORTHOGONALITY DRIFT OR NULL TRIAL VECTOR', /5X,
     2        'ALL EXISTING MODES MAY HAVE BEEN OBTAINED.  USE DIAG 16',
     3        ' TO DETERMINE ERROR BOUNDS',/)
  610 FORMAT (5X,'TRIDIAGONAL ELEMENTS ROW (IFN)',I5, /5X,'MORD =',I5,
     1        ', AII,DB,D = ',1P,3D16.8)
  620 FORMAT (11X,'ORTH ITER (IX)',I5,',  MAX PROJ (SDMAX)',1P,D16.8,
     1        ',  NORMAL FACT (DSQ)',1P,D16.8)
C
  630 NAME(3) = NAME(5)
      CALL CONMSG (NAME,3,0)
      RETURN
      END
