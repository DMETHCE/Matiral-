# HANA-Safe ABAP Rules

These rules apply to **every** OpenSQL statement produced for this user.

## 1. Never use `SELECT *`

❌
```abap
SELECT * FROM mara INTO TABLE gt_mara WHERE matnr IN so_matnr.
```

✅
```abap
SELECT matnr, mtart, matkl
  FROM mara
  INTO TABLE @DATA(gt_mara)
  WHERE matnr IN @so_matnr.
```

## 2. `SELECT SINGLE` only with full key

`SELECT SINGLE` is only deterministic when **all key fields** are in the WHERE clause. Otherwise use `UP TO 1 ROWS` with `ORDER BY`.

❌
```abap
SELECT SINGLE bukrs FROM bseg INTO lv_bukrs WHERE belnr = lv_belnr.
```

✅
```abap
SELECT bukrs
  FROM bseg
  INTO @lv_bukrs
  UP TO 1 ROWS
  WHERE belnr = @lv_belnr
  ORDER BY bukrs.
ENDSELECT.
```

Or — better yet — pass the full key.

## 3. Order at the database, not afterwards

❌
```abap
SELECT matnr, erdat FROM mara INTO TABLE gt_mara WHERE …
SORT gt_mara BY erdat DESCENDING.
```

✅
```abap
SELECT matnr, erdat
  FROM mara
  INTO TABLE @gt_mara
  WHERE …
  ORDER BY erdat DESCENDING.
```

## 4. No nested SELECTs inside loops

Use `JOIN` or prepare a driver table and use `FOR ALL ENTRIES`.

❌
```abap
LOOP AT gt_ekpo INTO gwa_ekpo.
  SELECT SINGLE lifnr FROM ekko INTO lv_lifnr WHERE ebeln = gwa_ekpo-ebeln.
  " …
ENDLOOP.
```

✅ (JOIN)
```abap
SELECT p~ebeln, p~ebelp, k~lifnr
  FROM ekpo AS p
  INNER JOIN ekko AS k ON k~ebeln = p~ebeln
  INTO TABLE @DATA(gt_items)
  WHERE p~ebeln IN @so_ebeln.
```

✅ (FOR ALL ENTRIES — driver table must be non-empty)
```abap
IF gt_ekpo IS NOT INITIAL.
  SELECT ebeln, lifnr
    FROM ekko
    INTO TABLE @DATA(gt_ekko)
    FOR ALL ENTRIES IN @gt_ekpo
    WHERE ebeln = @gt_ekpo-ebeln.
ENDIF.
```

## 5. Prefer `INTO TABLE` over row-by-row

Avoid `SELECT … ENDSELECT.` loops when a set operation is possible.

## Golden Rule

Push as much work as possible **to the database**. In-memory operations in ABAP on large result sets defeat the purpose of HANA.
