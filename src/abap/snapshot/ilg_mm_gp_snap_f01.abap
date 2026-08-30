*&---------------------------------------------------------------------*
*& Include /ILG/MM_GP_SNAP_F01 - לוגיקה
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form CHECK_AUTHORITY
*&---------------------------------------------------------------------*
*& בדיקת הרשאה לעדכון טבלת היעד לפני תחילת העיבוד
*&---------------------------------------------------------------------*
FORM check_authority.

  AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
    ID 'TABLE' FIELD '/ILG/MM_GP_TRK'
    ID 'ACTVT' FIELD '02'.
  IF sy-subrc <> 0.
    MESSAGE TEXT-014 TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form MAIN_PROCESS
*&---------------------------------------------------------------------*
*& שליפה מה-View, החתמת תאריך/שעה ורישום לטבלת היעד
*&---------------------------------------------------------------------*
FORM main_process.

  PERFORM get_data.
  PERFORM save_data.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
*& שליפת כל הרשומות מה-View /ILG/IMMGreenTrack למבנה טבלת היעד,
*& והחתמת תאריך ושעת העדכון על כל שורה
*&---------------------------------------------------------------------*
FORM get_data.

  SELECT qmnum                AS qmnum,
         logicalstatuscode    AS status_code,
         logicalstatus        AS logical_status,
         ismonitor            AS is_monitor,
         mblnr                AS mblnr,
         mblnrhandledmanually AS mblnr_manual,
         belnrmm              AS belnr_mm,
         gjahrmm              AS gjahr_mm,
         rbstat               AS rbstat,
         bukrs                AS bukrs,
         belnrfi              AS belnr_fi,
         gjahrfi              AS gjahr_fi,
         ispaid               AS is_paid,
         augbl                AS augbl,
         augdt                AS augdt,
         isreversed           AS is_reversed,
         stgrd                AS stgrd,
         stgrdtxt             AS stgrd_txt
    FROM /ilg/immgreentrack
    INTO CORRESPONDING FIELDS OF TABLE @gt_trk
    ORDER BY qmnum.

  LOOP AT gt_trk ASSIGNING FIELD-SYMBOL(<fs_trk>).
    <fs_trk>-aedat = sy-datum.
    <fs_trk>-aezet = sy-uzeit.
  ENDLOOP.

  gv_count = lines( gt_trk ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SAVE_DATA
*&---------------------------------------------------------------------*
*& מחיקת כל הרשומות הקיימות בטבלת היעד ורישום התמונה החדשה.
*& יחידה לוגית אחת: מחיקה + רישום + COMMIT יחיד בסופה
*&---------------------------------------------------------------------*
FORM save_data.

  DATA: lv_count_c TYPE string.

  lv_count_c = gv_count.
  CONDENSE lv_count_c.

  " הרצת בדיקה - ללא שינוי בטבלה
  IF cb_test = abap_true.
    gv_msg = TEXT-013.
    REPLACE '&' IN gv_msg WITH lv_count_c.
    WRITE: / gv_msg.
    RETURN.
  ENDIF.

  " מחיקת כל הרשומות הקיימות (מפתח לעולם אינו ריק - נמחק הכל)
  DELETE FROM /ilg/mm_gp_trk WHERE qmnum IS NOT INITIAL.

  " רישום התמונה החדשה
  MODIFY /ilg/mm_gp_trk FROM TABLE @gt_trk.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    gv_msg = TEXT-011.
    REPLACE '&' IN gv_msg WITH lv_count_c.
    WRITE: / gv_msg.
  ELSE.
    ROLLBACK WORK.
    WRITE: / TEXT-012.
  ENDIF.

ENDFORM.
