      SUBROUTINE SSGETD (ELID,TI,GRIDS)
C
C     THIS ROUTINE (CALLED BY -EDTL-) READS ELEMENT TEMPERATURE
C     DATA FROM A PRE-POSITIONED RECORD
C
C     ELID   = ID OF ELEMENT FOR WHICH DATA IS DESIRED
C     TI     = BUFFER DATA IS TO BE RETURNED IN
C     GRIDS  = 0 IF EL-TEMP FORMAT DATA IS TO BE RETURNED
C            = NO. OF GRID POINTS IF GRID POINT DATA IS TO BE RETURNED.
C     ELTYPE = ELEMENT TYPE TO WHICH -ELID- BELONGS
C     OLDEL  = ELEMENT TYPE CURRENTLY BEING WORKED ON (INITIALLY 0)
C     EORFLG = .TRUE. WHEN ALL DATA HAS BEEN EXHAUSTED IN RECORD
C     ENDID  = .TRUE. WHEN ALL DATA HAS BEEN EXHAUSTED WITHIN AN ELEMENT
C              TYPE.
C     BUFFLG = NOT USED
C     ITEMP  = TEMPERATURE LOAD SET ID
C     IDEFT  = NOT USED
C     IDEFM  = NOT USED
C     RECORD = .TRUE. IF A RECORD OF DATA IS INITIALLY AVAILABLE
C     DEFALT = THE DEFALT TEMPERATURE VALUE OR -1 IF IT DOES NOT EXIST
C     AVRAGE = THE AVERAGE ELEMENT TEMPERATURE
C
      LOGICAL         EORFLG   ,ENDID    ,BUFFLG   ,RECORD
      INTEGER         TI(7)    ,GRIDS    ,ELID     ,ELTYPE   ,OLDEL   ,
     1                NAME(2)  ,GPTT     ,DEFALT
      CHARACTER       UFM*23
      COMMON /XMSSG / UFM
      COMMON /SYSTEM/ DUM      ,IOUT
      COMMON /SSGETT/ ELTYPE   ,OLDEL    ,EORFLG   ,ENDID    ,BUFFLG  ,
     1                ITEMP    ,IDEFT    ,IDEFM    ,RECORD
      COMMON /LOADX / DUMMY(9) ,GPTT
      COMMON /FPT   / DEFALT
      DATA    NAME  / 4HSSGE,4HTD   /    ,MAXWDS   / 15 /
C
      IF (ITEMP .NE. 0) GO TO 20
      DO 10 I = 1,MAXWDS
   10 TI(I) = 0
      RETURN
C
   20 IF (.NOT.RECORD .OR. EORFLG) GO TO 80
   30 IF (ELTYPE .NE. OLDEL) GO TO 150
      IF (ENDID) GO TO 80
C
C     HERE WHEN ELTYPE IS AT HAND AND END OF THIS TYPE DATA
C     HAS NOT YET BEEN REACHED.  READ AN ELEMENT ID
C
   40 CALL READ (*200,*210,GPTT,ID,1,0,FLAG)
      IF (ID) 50,80,50
   50 IF (IABS(ID) .EQ. ELID) IF (ID) 90,90,70
      IF (ID) 40,40,60
   60 CALL READ (*200,*210,GPTT,TI,NWORDS,0,FLAG)
      GO TO 40
C
C     MATCH ON ELEMNT ID MADE, AND IT WAS WITH DATA.
C     IF QUAD4 OR TRIA3 ELEMENT, SET THE TI(7) FLAG FOR TLQD4D/S (QAUD4)
C     OR TLTR3D/S (TRIA3)
C
   70 CALL READ (*200,*210,GPTT,TI,NWORDS,0,FLAG)
      IF (ELTYPE.NE.64 .AND. ELTYPE.NE.83) RETURN
      TI(7) = 13
      IF (TI(6) .NE. 1) TI(7) = 2
      RETURN
C
C     NO MORE DATA FOR THIS ELEMENT TYPE
C
   80 ENDID = .TRUE.
C
C     NO DATA FOR ELEMENT ID DESIRED, THUS USE DEFALT
C
   90 IF (DEFALT .EQ. -1) GO TO 130
      IF (GRIDS  .GT.  0) GO TO 110
      DO 100 I = 2,MAXWDS
  100 TI(I) = 0
      TI(1) = DEFALT
      IF (ELTYPE .EQ. 34) TI(2) = DEFALT
      RETURN
  110 DO 120 I = 1,GRIDS
  120 TI(I) = DEFALT
      TI(GRIDS+1) = DEFALT
      RETURN
C
C     NO TEMP DATA OR DEFALT
C
  130 WRITE  (IOUT,140) UFM,ELID,ITEMP
  140 FORMAT (A23,' 4017. THERE IS NO TEMPERATURE DATA FOR ELEMENT',I9,
     1        ' IN SET',I9)
      CALL MESAGE (-61,0,0)
C
C     LOOK FOR MATCH ON ELTYPE (FIRST SKIP ANY UNUSED ELEMENT DATA)
C
  150 IF (ENDID) GO TO 180
  160 CALL READ (*200,*210,GPTT,ID,1,0,FLAG)
      IF (ID) 160,180,170
  170 CALL READ (*200,*210,GPTT,TI,NWORDS,0,FLAG)
      GO TO 160
C
C     READ ELTYPE AND COUNT
C
  180 CALL READ (*200,*190,GPTT,TI,2,0,FLAG)
      OLDEL  = TI(1)
      NWORDS = TI(2)
      ENDID  = .FALSE.
      GO TO 30
C
C     END OF RECORD HIT
C
  190 EORFLG = .TRUE.
      GO TO 80
C
  200 CALL MESAGE (-2,GPTT,NAME)
  210 CALL MESAGE (-3,GPTT,NAME)
      RETURN
      END
