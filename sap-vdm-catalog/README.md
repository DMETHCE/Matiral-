# קטלוג VDM — טבלאות סטנדרט, Views משוחררים ושדות

מאגר אחד לכל שאלה של "איזה View משוחרר מחליף את טבלה X ומה שם השדה".
**לפני כל מחקר באינטרנט או בקשה מהמשתמש לבדוק ב-ADT — מחפשים כאן.**

## הקבצים

| קובץ | מה יש בו |
|------|----------|
| `views.tsv` | כל ה-CDS Views בקטלוג של SAP (מהדורת Private Cloud — הקרובה ביותר ל-On-Premise): שם, קטגוריה, סטטוס (RELEASED / DEPRECATED), כותרת, View הטקסט, טבלאות DB שמוזכרות בתיאור, רכיב, יורש |
| `fields.tsv` | כל השדות של כל View: שם שדה, תיאור, סוג, אורך, סטטוס, יורש |
| `table_field_map.tsv` | מיפוי מאומת **שדה בטבלה → שדה ב-View**. נבנה ידנית; כל שורה עם תאריך ומקור |
| `fetch_catalog.py` | רענון הקטלוג מ-api.sap.com (ציבורי, בלי התחברות) |

## איך מחפשים

```
grep -i "BKPF" table_field_map.tsv                  # מיפוי מאומת לטבלה
grep -i "	BKPF" views.tsv                            # Views שהתיאור שלהם מזכיר את BKPF
grep -i "^I_JournalEntry	" fields.tsv              # כל השדות של View
grep -i "Reversal" fields.tsv | grep "^I_Journal"     # שדה לפי מילה בתיאור
grep -i "NotifActivity" views.tsv                    # View לפי חלק מהשם
```

## כללים

1. **שם View ושם שדה נלקחים רק מכאן** (או מ-ADT). לא מהזיכרון.
2. View עם סטטוס `DEPRECATED` — לא משתמשים; עמודת `successors` אומרת למה לעבור.
3. `fields.tsv` מוכיח שהשדה **קיים**. איזה שדה בטבלה הוא מייצג — רק `table_field_map.tsv`.
   מיפוי חדש שאומת (ADT / help.sap.com / api.sap.com) — מוסיפים שורה עם תאריך ומקור.
4. View שלא נמצא כאן — מריצים `fetch_catalog.py --only <VIEW>` ומוסיפים.
5. מה שהקטלוג לא עונה עליו: **אילו שורות** ה-View מחזיר (סינון פנימי, DCL). זה נבדק רק ב-ADT.

## רענון

```
python fetch_catalog.py                    # כל מהדורת Private Cloud (~10 דקות)
python fetch_catalog.py --only I_JOURNALENTRY,I_PURCHASEORDERAPI01   # Views בודדים -> *_partial.tsv
```

## פתוח

- `I_QltyNotificationActivity` מתועד להודעות איכות. להודעות PM יש `C_MaintNotifActivityDEX`
  (Consumption, Released, לחילוץ נתונים). מי מהם מחזיר את הודעות המסלול הירוק — Data Preview ב-ADT.
