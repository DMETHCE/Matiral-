*&---------------------------------------------------------------------*
*& Report /ILG/MM_GP_SNAP
*&---------------------------------------------------------------------*
*& רישום תמונת מצב מה-View /ILG/IMMGreenTrack לטבלה /ILG/MM_GP_TRK:
*& מחיקת כל הרשומות הקיימות בטבלה ורישום מחדש של כל שורות ה-View,
*& בתוספת חותמת תאריך ושעת עדכון (AEDAT / AEZET).
*&---------------------------------------------------------------------*
REPORT /ilg/mm_gp_snap.

INCLUDE /ilg/mm_gp_snap_dat.   " Data declarations
INCLUDE /ilg/mm_gp_snap_sel.   " Selection screen
INCLUDE /ilg/mm_gp_snap_f01.   " Forms

START-OF-SELECTION.
  PERFORM check_authority.
  PERFORM main_process.
