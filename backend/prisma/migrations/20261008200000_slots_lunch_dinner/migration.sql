-- S14: the named times of day become MORNING, LUNCH, DINNER (defaults 08:00, 13:00, 20:00).
-- NOON -> LUNCH; EVENING and NIGHT -> DINNER, one dose per part of the day.

-- Dose marks first, keeping the later mark when two old slots collapse into one.
UPDATE "DoseLog" SET "slot" = 'LUNCH' WHERE "slot" = 'NOON';
DELETE FROM "DoseLog" d
 USING "DoseLog" e
 WHERE d."medicineId" = e."medicineId" AND d."date" = e."date"
   AND d."slot" IN ('EVENING', 'NIGHT') AND e."slot" IN ('EVENING', 'NIGHT') AND d."id" <> e."id"
   AND (d."markedAt" < e."markedAt" OR (d."markedAt" = e."markedAt" AND d."id" < e."id"));
UPDATE "DoseLog" SET "slot" = 'DINNER' WHERE "slot" IN ('EVENING', 'NIGHT');

-- Schedules: rename, then drop duplicates and recount.
UPDATE "Schedule" SET "slots" = array(
  SELECT DISTINCT CASE x WHEN 'NOON' THEN 'LUNCH' WHEN 'EVENING' THEN 'DINNER' WHEN 'NIGHT' THEN 'DINNER' ELSE x END
  FROM unnest("slots") AS x
);
UPDATE "Schedule" SET "slots" = (
  SELECT coalesce(array_agg(s ORDER BY CASE s WHEN 'MORNING' THEN 1 WHEN 'LUNCH' THEN 2 ELSE 3 END), '{}')
  FROM unnest("slots") AS s
);
UPDATE "Schedule" SET "dosesPerDay" = cardinality("slots") + cardinality("times");
