*&---------------------------------------------------------------------*
*& Report ZMM_PROCESS_GREEN_PATH  --  LEGACY / לא בשימוש
*&---------------------------------------------------------------------*
*& התוכנית המקורית לעיבוד ורישום רצף מסמכים למסלול ירוק / בקרה מפצה.
*& נשמרת כאן לתיעוד בלבד. התוכנית אינה מתקמפלת (12 שגיאות - ראו
*& docs/abap/abap_program_analysis.md) והוחלפה על ידי CDS View חי:
*& ZC_MM_GREENTRACK (ראו src/cds + docs/cds/cds_spec.md).
*&---------------------------------------------------------------------*
REPORT zmm_process_green_path.

TABLES: /ilg/mm_grpo_det, qmma.

TYPES: BEGIN OF ty_target,
         mandt                 TYPE mandt,
         qmnum                 TYPE qmnum,
         logical_status        TYPE string,
         is_monitor            TYPE char1,
         mblnr                 TYPE mblnr,
         mblnr_handled_manually TYPE char1,
         belnr_mm              TYPE re_belnr,
         gjahr_mm              TYPE gjahr,
         belnr_fi              TYPE belnr_d,
         gjahr_fi              TYPE gjahr,
         bukrs                 TYPE bukrs,
         is_paid               TYPE char1,
         augbl                 TYPE augbl,
         augdt                 TYPE augdt,
         is_reversed           TYPE char1,
         stgrd                 TYPE stgrd,
         stgrd_txt             TYPE text60,
         aedat                 TYPE aedat,
         aezet                 TYPE aezet,
       END OF ty_target.

*DATA: lt_target_db TYPE TABLE OF zmm_green_track, " השם של טבלת היעד שלכם ב-SE11
*      ls_target_db LIKE LINE OF lt_target_db.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_qmnum FOR qmma-qmnum.
  PARAMETERS: p_clear AS CHECKBOX DEFAULT 'X'. " מחיקת נתונים קודמים בטבלת היעד לפני הרישום
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  PERFORM process_green_path_data.

*&---------------------------------------------------------------------*
*& Form PROCESS_GREEN_PATH_DATA
*&---------------------------------------------------------------------*
FORM process_green_path_data.

  " 1. שליפת כל הסטים מטבלת המסלול הירוק
  SELECT qmnum, mblnr, belnr, gjahr, extra_vlue_ind, monitor_indicator, mn_gr_doc_ind
    FROM /ilg/mm_grpo_det
    INTO TABLE @DATA(lt_grpo)
    WHERE qmnum IN @s_qmnum.

  IF lt_grpo IS INITIAL.
    MESSAGE 'לא נמצאו נתונים להרצה' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " 2. שליפת קודי הסטטוסים מטבלת QMMA
  SELECT qmnum, mncod, erdat, erzeit
    FROM qmma
    FOR ALL ENTRIES IN @lt_grpo
    WHERE qmnum = @lt_grpo-qmnum
    INTO TABLE @DATA(lt_qmma).

  " 3. שליפת סיבות סטורנו מטבלת התרגום T041CT
  SELECT stgrd, txt20
    FROM t041ct
    WHERE spras = @sy-langu
    INTO TABLE @DATA(lt_t041ct).

  SORT lt_qmma BY qmnum mncod.
  SORT lt_t041ct BY stgrd.

  LOOP AT lt_grpo ASSIGNING FIELD-SYMBOL(<ls_grpo>).

    CLEAR ls_target_db.
    ls_target_db-mandt    = sy-mandt.
    ls_target_db-qmnum    = <ls_grpo>-qmnum.
    ls_target_db-mblnr    = <ls_grpo>-mblnr.
    ls_target_db-belnr_mm = <ls_grpo>-belnr.
    ls_target_db-gjahr_mm = <ls_grpo>-gjahr.

    " ---------------------------------------------------------
    " א. בדיקת אינדיקטור בקרה ידנית (בוליאני)
    " ---------------------------------------------------------
    IF <ls_grpo>-monitor_indicator IS NOT INITIAL OR <ls_grpo>-extra_vlue_ind IS NOT INITIAL.
      ls_target_db-is_monitor = 'X'.
    ENDIF.

    " בדיקת אינדיקטור טובין ידני
    IF <ls_grpo>-mn_gr_doc_ind = '2' OR <ls_grpo>-mn_gr_doc_ind = '4'.
      ls_target_db-mblnr_handled_manually = 'X'.
    ENDIF.

    " ---------------------------------------------------------
    " ב. איסוף קודי הסטטוס של הסט מ-QMMA
    " ---------------------------------------------------------
    DATA: lv_has_50 TYPE abap_bool VALUE abap_false,
          lv_has_60 TYPE abap_bool VALUE abap_false,
          lv_has_70 TYPE abap_bool VALUE abap_false,
          lv_has_80 TYPE abap_bool VALUE abap_false.

    LOOP AT lt_qmma ASSIGNING FIELD-SYMBOL(<ls_qmma>) WHERE qmnum = <ls_grpo>-qmnum.
      CASE <ls_qmma>-mncod.
        WHEN '50'. lv_has_50 = abap_true.
        WHEN '60'. lv_has_60 = abap_true.
        WHEN '70'. lv_has_70 = abap_true.
        WHEN '80'. lv_has_80 = abap_true.
      ENDCASE.
    ENDLOOP.

    " ---------------------------------------------------------
    " ג. שרשור חשבונית פיננסית (BKPF) ובדיקת סטורנו / תשלום
    " ---------------------------------------------------------
    IF <ls_grpo>-belnr IS NOT INITIAL AND <ls_grpo>-gjahr IS NOT INITIAL.

      DATA: lv_awkey TYPE bkpf-awkey.
      CONCATENATE <ls_grpo>-belnr <ls_grpo>-gjahr INTO lv_awkey.

      " שליפת מסמך פיננסי ראשוני מ-BKPF
      SELECT SINGLE bukrs, belnr, gjahr, xreversed, awref_rev, aworg_rev
        FROM bkpf
        INTO @DATA(ls_bkpf)
        WHERE awkey = @lv_awkey.

      IF sy-subrc = 0.
        ls_target_db-bukrs    = ls_bkpf-bukrs.
        ls_target_db-belnr_fi = ls_bkpf-belnr.
        ls_target_db-gjahr_fi = ls_bkpf-gjahr.

        " 1. בדיקת סטורנו/ביטול
        IF ls_bkpf-xreversed = 'X'.
          ls_target_db-is_reversed = 'X'.

          " שליפת סיבת הסטורנו מפרטי הביטול ב-BKPF
          IF ls_bkpf-awref_rev IS NOT INITIAL.
            DATA: lv_rev_awkey TYPE bkpf-awkey.
            CONCATENATE ls_bkpf-awref_rev ls_bkpf-aworg_rev INTO lv_rev_awkey.

            SELECT SINGLE stgrd
              FROM bkpf
              INTO @ls_target_db-stgrd
              WHERE awkey = @lv_rev_awkey.

            IF sy-subrc = 0 AND ls_target_db-stgrd IS NOT INITIAL.
              READ TABLE lt_t041ct ASSIGNING FIELD-SYMBOL(<ls_t041ct>)
                WITH KEY stgrd = ls_target_db-stgrd BINARY SEARCH.
              IF sy-subrc = 0.
                ls_target_db-stgrd_txt = <ls_t041ct>-txt20.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

        " 2. בדיקת תשלום בפועל ב-ACDOCA / BSEG
        SELECT SINGLE augbl, augdt
          FROM acdoca
          INTO (@ls_target_db-augbl, @ls_target_db-augdt)
          WHERE bukrs = @ls_bkpf-bukrs
            AND belnr = @ls_bkpf-belnr
            AND gjahr = @ls_bkpf-gjahr
            AND koart = 'K'
            AND augbl NE ''.

        IF sy-subrc <> 0.
          " Fallback לטבלת BSEG במידה ומדובר במערכת ישנה / תצוגת BSEG
          SELECT SINGLE augbl, augdt
            FROM bseg
            INTO (@ls_target_db-augbl, @ls_target_db-augdt)
            WHERE bukrs = @ls_bkpf-bukrs
              AND belnr = @ls_bkpf-belnr
              AND gjahr = @ls_bkpf-gjahr
              AND koart = 'K'
              AND augbl NE ''.
        ENDIF.

        IF ls_target_db-augbl IS NOT INITIAL.
          ls_target_db-is_paid = 'X'.
        ENDIF.

      ENDIF.
    ENDIF.

    " ---------------------------------------------------------
    " ד. חישוב הסטטוס הלוגי לפי עץ ההחלטות באפיון
    " ---------------------------------------------------------
    IF lv_has_50 = abap_true AND lv_has_60 = abap_true.
      IF ls_target_db-is_reversed = 'X' OR ls_target_db-is_paid = abap_false.
        ls_target_db-logical_status = 'נדחה לאחר אישור ובוטל'.
      ELSE.
        ls_target_db-logical_status = 'נדחה לאחר אישור ושולם'.
      ENDIF.

    ELSEIF lv_has_60 = abap_true.
      IF ls_target_db-is_reversed = 'X'.
        ls_target_db-logical_status = 'נדחה לאחר אישור דורש'.
      ELSEIF lv_has_70 = abap_true OR lv_has_80 = abap_true OR ls_target_db-mblnr_handled_manually = 'X'.
        ls_target_db-logical_status = 'אושר והושלם לאחר עיסוק ידני'.
      ELSE.
        ls_target_db-logical_status = 'אושר והושלם ללא תקלה'.
      ENDIF.

    ELSEIF lv_has_50 = abap_true.
      ls_target_db-logical_status = 'נדחה על ידי דורש'.

    ELSE.
      ls_target_db-logical_status = 'בתהליך'.
    ENDIF.

    " תאריך ושעת עדכון
    ls_target_db-aedat = sy-datum.
    ls_target_db-aezet = sy-uzeit.

    APPEND ls_target_db TO lt_target_db.

  ENDLOOP.

  " ---------------------------------------------------------
  " ה. רישום לטבלת היעד (Clear & Insert/Modify)
  " ---------------------------------------------------------
  IF lt_target_db IS NOT INITIAL.
    IF p_clear = 'X'.
      IF s_qmnum[] IS INITIAL.
        DELETE FROM zmm_green_track. " מחיקת כל הטבלה במידה ולא הוגדר סנון
      ELSE.
        DELETE FROM zmm_green_track WHERE qmnum IN @s_qmnum.
      ENDIF.
    ENDIF.

    MODIFY zmm_green_track FROM TABLE lt_target_db.
    IF sy-subrc = 0.
      COMMIT WORK.
      WRITE: / 'עבודת התוכנית הסתיימה בהצלחה. עודכנו', lines( lt_target_db ), 'רשומות.'.
    ELSE.
      ROLLBACK WORK.
      WRITE: / 'שגיאה בביצוע MODIFY לטבלת היעד.'.
    ENDIF.
  ENDIF.

ENDFORM.
