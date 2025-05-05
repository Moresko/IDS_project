
--region DROP
-- Zmazanie tabuliek
DROP TABLE  "RESERVATION_ROOM";
DROP TABLE "RESERVATION_SERVICE";
DROP TABLE "SERVICES";
DROP TABLE "RESERVATIONS";
DROP TABLE "PAYMENTS";
DROP TABLE "GUESTS";
DROP TABLE "ROOMS";
DROP SEQUENCE "ID_RESERVATION";
DROP MATERIALIZED VIEW "rooms_popularity";
--endregion

--region CREATE
--  Vytvorenie tabuliek
CREATE TABLE "ROOMS"
(
    "ID"             INT          NOT NULL PRIMARY KEY
        CHECK ( "ID" > 0),
    "number_of_beds" INT          NOT NULL
        CHECK ( "number_of_beds" > 0 ),
    "room_view"      VARCHAR(255) NOT NULL
        CHECK ( "room_view" in ('sea', 'street', 'areal')),
    "facilities"     VARCHAR(255) NOT NULL
        CHECK ( "facilities" in ('standard', 'junior', 'presidential', 'penthouse') )
);

CREATE TABLE "GUESTS"
(
    "ID"      INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "name"    VARCHAR(255)              NOT NULL,
    "surname" VARCHAR(255)              NOT NULL,
    "phone"   VARCHAR(22)               NOT NULL,
    "email"   VARCHAR(255)              NOT NULL
        CHECK ( regexp_like("email", '^[a-zA-Z]+[a-zA-Z0-9.]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') )
);

CREATE TABLE "PAYMENTS"
(
    "ID"       INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "method"   VARCHAR(255)              NOT NULL
        CHECK ( "method" in ('card', 'cash', 'check')),
    "amount"   INT                       NOT NULL
        CHECK ( "amount" > 0 ),
    "guest_id" INT                       NOT NULL,
    CONSTRAINT "payments_guest_id_foreign_key"
        FOREIGN KEY ("guest_id") REFERENCES "GUESTS" ("ID")
            ON DELETE CASCADE
);

CREATE TABLE "RESERVATIONS"
(
    "ID"               INT DEFAULT NULL PRIMARY KEY,
    "check_in"         DATE NOT NULL
        CHECK ( EXTRACT(YEAR FROM "check_in") >= 2022 ),
    "check_out"        DATE NOT NULL,
    CHECK ( EXTRACT(YEAR FROM "check_in") <= EXTRACT(YEAR FROM "check_out")
        AND EXTRACT(MONTH FROM "check_in") <= EXTRACT(MONTH FROM "check_out")
        AND EXTRACT(DAY FROM "check_in") < EXTRACT(DAY FROM "check_out")),
    "number_of_guests" INT  NOT NULL
        CHECK ("number_of_guests" >= 1),
    "payment_id"       INT  NOT NULL,
    CONSTRAINT "reservation_payment_id_foreign_key"
        FOREIGN KEY ("payment_id") REFERENCES "PAYMENTS" ("ID")
            ON DELETE CASCADE,
    "guest_id"         INT  NOT NULL,
    CONSTRAINT "reservation_guest_id_foreign_key"
        FOREIGN KEY ("guest_id") REFERENCES "GUESTS" ("ID")
            ON DELETE CASCADE

);

CREATE TABLE "SERVICES"
(
    "ID"                    INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "cost"                  INT                       NOT NULL,
    "hours_available_from"  VARCHAR(5)
        CHECK ( regexp_like("hours_available_from", '(^[0-1][0-9]:[0-5][0-9]$)|(^2[0-3]:[0-5][0-9]$)') ),
    "hours_available_until" VARCHAR(5)
        CHECK ( regexp_like("hours_available_until", '(^[0-1][0-9]:[0-5][0-9]$)|(^2[0-3]:[0-5][0-9]$)') ),
    "method"                VARCHAR(255) DEFAULT NULL,
    "duration"              VARCHAR(255) DEFAULT NULL,
    "cuisine"               VARCHAR(255) DEFAULT NULL
    -- Generalizacia/specializacia
    -- Ak su method a duration NULL jedna sa o DINNER
    -- Ak je cuisine NULL jedna sa o MASSAGE
);

CREATE TABLE "RESERVATION_SERVICE"
(
    "reservation_id" INT NOT NULL,
    CONSTRAINT "reservation_service_reservation_id_foreign_key"
        FOREIGN KEY ("reservation_id") REFERENCES "RESERVATIONS" ("ID")
            ON DELETE CASCADE,
    "service_id"     INT NOT NULL,
    CONSTRAINT "reservation_service_service_id_foreign_key"
        FOREIGN KEY ("service_id") REFERENCES "SERVICES" ("ID")
            ON DELETE CASCADE,
    CONSTRAINT "reservation_service_primary_key"
        PRIMARY KEY ("reservation_id", "service_id")
);

CREATE TABLE "RESERVATION_ROOM"
(
    "reservation_id" INT NOT NULL,
    CONSTRAINT "reservation_room_reservation_id_foreign_key"
        FOREIGN KEY ("reservation_id") REFERENCES "RESERVATIONS" ("ID")
            ON DELETE CASCADE,
    "room_id"        INT NOT NULL,
    CONSTRAINT "reservation_room_room_id_foreign_key"
        FOREIGN KEY ("room_id") REFERENCES "ROOMS" ("ID")
            ON DELETE CASCADE,
    CONSTRAINT "reservation_room_primary_key"
        PRIMARY KEY ("reservation_id", "room_id")
);
--endregion

--region TRIGGER
--TRIGGER "ID_RESERVATION" automaticky generuje hodnotu primarneho kluca tabulky "RESERVATIONS".
CREATE SEQUENCE "ID_RESERVATION";
CREATE OR REPLACE TRIGGER "ID_RESERVATION"
    BEFORE INSERT
    ON "RESERVATIONS"
    FOR EACH ROW
BEGIN
    IF :NEW."ID" IS NULL THEN
        :NEW."ID" := "ID_RESERVATION".NEXTVAL;
    END IF;
END;
--TRIGGER "ALL_DAY_AVAILABLE_HOURS" pri nezadani dostupnych hodin sluzby priradi cas.
-- Ak nie je zadany pociatocny cas, nastavi 00:00.
-- Ak nie je zadany koncovy cas, nastavi 23:59
CREATE OR REPLACE TRIGGER "ALL_DAY_AVAILABLE_HOURS"
    BEFORE INSERT
    ON "SERVICES"
    FOR EACH ROW
BEGIN
    IF :NEW."hours_available_from" IS NULL THEN
        :NEW."hours_available_from" := '00:00';
    end if;
    IF :NEW."hours_available_until" IS NULL THEN
        :NEW."hours_available_until" := '23:59';
    end if;
end;
--endregion

--region INSERT
-- Naplnenie tabuliek
INSERT INTO "ROOMS" ("ID", "number_of_beds", "room_view", "facilities")
VALUES (444, 4, 'areal', 'penthouse');
INSERT INTO "ROOMS" ("ID", "number_of_beds", "room_view", "facilities")
VALUES (618, 2, 'street', 'standard');
INSERT INTO "ROOMS" ("ID", "number_of_beds", "room_view", "facilities")
VALUES (301, 1, 'sea', 'junior');
INSERT INTO "ROOMS" ("ID", "number_of_beds", "room_view", "facilities")
VALUES (302, 2, 'sea', 'standard');

INSERT INTO "GUESTS" ("name", "surname", "phone", "email")
VALUES ('Jakub', 'Kasem', '+421 904 880 512', 'vymysleny.email@gmail.com');
INSERT INTO "GUESTS" ("name", "surname", "phone", "email")
VALUES ('Patrik', 'Vrbovsky', '+421950334232', 'rytmus@rytmus.sk');
INSERT INTO "GUESTS" ("name", "surname", "phone", "email")
VALUES ('Martin', 'Mores', '226 517 250', 'dalsi.vymyslenyEmail@apple.com');
INSERT INTO "GUESTS" ("name", "surname", "phone", "email")
VALUES ('Tomas', 'Klimik', '+421 905 839 123', 'klimcoo@centrum.sk');

INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('card', 100, 3);
INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('cash', 50, 1);
INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('card', 100, 4);
INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('check', 100, 2);
INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('card', 500, 1);

--Nasledujuce INSERT do "RESERVATIONS" spustia TRIGGER "ID_RESERVATION"
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-06-02 17:30', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-06-05 10:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 2, 2, 1);
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-04-20 16:20', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-04-21 12:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 1, 3, 4);
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-07-10 15:30', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-07-11 12:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 1, 4, 2);
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-05-15 14:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-05-18 11:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 1, 1, 3);
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-06-20 15:30', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-06-23 10:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 4, 5, 1);

INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (15, '18:30', '21:50', 'indian');
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "method", "duration")
VALUES (30, '10:00', '18:00', 'thai', '30 min');
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (15, '18:30', '21:50', 'czech');
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (30, '11:30', '16:00', 'indian');
--Nasledujuci INSERT do "SERVICES" spusti TRIGGER "ALL_DAY_AVAILABLE_HOURS"
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (12, NULL, NULL, 'street food');

INSERT INTO "RESERVATION_SERVICE" ("reservation_id", "service_id")
VALUES (2, 1);
INSERT INTO "RESERVATION_SERVICE" ("reservation_id", "service_id")
VALUES (1, 2);
INSERT INTO "RESERVATION_SERVICE" ("reservation_id", "service_id")
VALUES (3, 3);


INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (1, 618);
INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (2, 444);
INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (3, 444);
INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (4, 618);
INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (5, 444);
--endregion

--region TRIGGER DEMONSTRATION

--Ukazka TRIGGER "ID_RESERVATION"
-- rezervacie budu mat ID zhodne s poradim v ktorom boli vlozene
SELECT *
FROM "RESERVATIONS";

--Ukazka TRIGGER "ALL_DAY_AVAILABLE_HOURS"
-- sluzba s primarnym klucom 5, ktora bola vlozena s hodnotami NULL pri "hours_available_from" a "hours_available_until"
-- bude mat celodennu prevadzku
SELECT *
FROM "SERVICES"
WHERE "ID" = 5;

--endregion

--region PROCEDURE

--Procedura pocita kolko kapacity izieb je priemerne zaplnenych pri izbach s danym vyhladom
CREATE OR REPLACE PROCEDURE "BEDS_OCCUPANCY"(room_view IN VARCHAR) AUTHID CURRENT_USER
AS
    beds_count  "ROOMS"."number_of_beds"%TYPE;
    guest_count "RESERVATIONS"."number_of_guests"%TYPE;
    beds_nmb    INT;
    guests_nmb  INT;
    occupancy   NUMBER;
    CURSOR beds IS SELECT "number_of_beds", "number_of_guests"
                   FROM "ROOMS",
                        "RESERVATION_ROOM",
                        "RESERVATIONS"
                   WHERE "RESERVATION_ROOM"."room_id" = "ROOMS"."ID"
                     AND "RESERVATIONS"."ID" = "RESERVATION_ROOM"."reservation_id"
                     AND "ROOMS"."room_view" = room_view;
BEGIN
    IF NOT (room_view in ('sea', 'street', 'areal')) THEN
        DBMS_OUTPUT.PUT_LINE('Mozne vyhlady izieb su ''sea'', ''street'', ''areal''.');
        RETURN;
    END IF;
    beds_nmb := 0;
    guests_nmb := 0;
    OPEN beds;
    LOOP
        FETCH beds INTO beds_count, guest_count;
        EXIT WHEN beds%NOTFOUND;
        beds_nmb := beds_nmb + beds_count;
        guests_nmb := guests_nmb + guest_count;
    END LOOP;
    CLOSE beds;
    occupancy := guests_nmb / beds_nmb * 100;

    DBMS_OUTPUT.PUT_LINE('Izby s vyhladom: ' || room_view);
    DBMS_OUTPUT.PUT_LINE('su priemerne naplnene na: ' || occupancy || '%.');
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        BEGIN
            DBMS_OUTPUT.put_line('V izbach s vybranym vyhladom nie su zaznamy o poskytnutych ubytovaniach.');
        END;
END;
/

--Procedura vypise pocet dostupnych sluzieb podla typu (vecera, masaz) na zaklade zadaneho casu
CREATE OR REPLACE PROCEDURE "AVAILABLE_SERVICES"(time_from IN VARCHAR, time_until IN VARCHAR)
AS
    time1    VARCHAR(6);
    time2    VARCHAR(6);
    dinners  INT;
    massages INT;
    overall  INT;
    flag1    "SERVICES"."method"%TYPE;
    flag2    "SERVICES"."duration"%TYPE;
    flag3    "SERVICES"."cuisine"%TYPE;
    CURSOR servicess IS SELECT "method", "duration", "cuisine"
                        FROM "SERVICES"
                        WHERE NOT (("hours_available_until" > time2 AND "hours_available_from" > time2) OR
                                   ("hours_available_from" < time1 AND "hours_available_until" < time1));
BEGIN
    IF time_from IS NULL THEN
        time1 := '00:00';
        DBMS_OUTPUT.PUT_LINE('Pociatocny cas nebol zadany. Automaticky nastaveny na 00:00.');
    ELSE
        time1 := time_from;
    END IF;
    IF time_until IS NULL THEN
        time2 := '23:59';
        DBMS_OUTPUT.PUT_LINE('Koncovy cas nebol zadany. Automaticky nastaveny na 23:59.');
    ELSE
        time2 := time_until;
    END IF;
    IF LENGTH(time1) != 5 OR LENGTH(time2) != 5 THEN
        DBMS_OUTPUT.PUT_LINE('Zadane casy musia byt vo formate HH:MM.');
        RETURN;
    END IF;
    IF time1 >= time2 THEN
        DBMS_OUTPUT.PUT_LINE('Zadane casy musia byt v casovej postupnosti.');
        RETURN;
    END IF;
    dinners := 0;
    massages := 0;
    OPEN servicess;
    LOOP
        FETCH servicess INTO flag1, flag2, flag3;
        EXIT WHEN servicess%NOTFOUND;
        IF flag1 IS NULL AND flag2 IS NULL THEN
            dinners := dinners + 1;
        END IF;
        IF flag3 IS NULL THEN
            massages := massages + 1;
        END IF;
    END LOOP;
    CLOSE servicess;
    overall := dinners + massages;
    DBMS_OUTPUT.PUT_LINE('Celkovy pocet dostupnych sluzieb v dany cas: ' || overall);
    DBMS_OUTPUT.PUT_LINE('Pocet dostupnych veceri v dany cas: ' || dinners);
    DBMS_OUTPUT.PUT_LINE('Pocet dostupnych masazi v dany cas: ' || massages);
END;
/

-- Ukazka PROCEDURE "BEDS_OCCUPANCY"
BEGIN
    "BEDS_OCCUPANCY"('street');
END;

-- Ukazka PROCEDURE "AVAILABLE_SERVICES"
BEGIN
    "AVAILABLE_SERVICES"('18:00', NULL);
END;

--endregion

--region MATERIALIZED VIEW

-- Materializovany pohlad zachytava kolko krat boli jednotlive izby rezervovane
CREATE MATERIALIZED VIEW "rooms_popularity"
            BUILD IMMEDIATE
    REFRESH FORCE ON DEMAND
AS
SELECT "r"."ID" AS "room number", "r"."room_view" AS "view", "r"."facilities", COUNT(*) AS "number of reservations"
FROM "ROOMS" "r", "RESERVATION_ROOM" "rr"
WHERE "r"."ID" = "rr"."room_id"
GROUP BY "r"."ID",  "r"."room_view", "r"."facilities";
-- Dotaz pre aktualizaciu MATERIALIZED VIEW "upcoming_check_ins"
CREATE OR REPLACE PROCEDURE "refresh_mv_chckin" AS
BEGIN
    DBMS_MVIEW.REFRESH('"rooms_popularity"');--, 'C', );
END;
/
-- Predvedenie pohladu
SELECT * FROM "rooms_popularity";

-- Aktualizovanie hodnot
UPDATE "ROOMS" SET "room_view" = 'sea' WHERE "ID" = 444;

--Pohlad sa aktualizuje na dotaz
BEGIN
    "refresh_mv_chckin"();
END;

-- Predvedenie aktualizovaneho pohladu
SELECT * FROM "rooms_popularity";

--endregion

--region PRIVILEGES
--tabulky
GRANT ALL ON "RESERVATION_ROOM" TO XMORES02;
GRANT ALL ON "RESERVATION_SERVICE" TO XMORES02;
GRANT ALL ON "SERVICES" TO XMORES02;
GRANT ALL ON "RESERVATIONS" TO XMORES02;
GRANT ALL ON "PAYMENTS" TO XMORES02;
GRANT ALL ON "GUESTS" TO XMORES02;
GRANT ALL ON "ROOMS" TO XMORES02;
--funkcie
GRANT EXECUTE ON "BEDS_OCCUPANCY" TO XMORES02;
GRANT EXECUTE ON "AVAILABLE_SERVICES" TO XMORES02;
--materializovany pohlad
GRANT ALL ON "rooms_popularity" TO XMORES02;

--endregion

--region EXPLAIN PLAN
--Explain plan a test
EXPLAIN PLAN FOR
SELECT "method", "name", COUNT(*) pocet
FROM PAYMENTS, GUESTS
WHERE "amount" >  60
GROUP BY "method", "name";


SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());
--Vytvorenie indexu pre urychlenie

CREATE INDEX amount_index ON PAYMENTS ("amount", "method");

EXPLAIN PLAN FOR
SELECT "method", "name", COUNT(*) pocet
FROM PAYMENTS, GUESTS
WHERE "amount" >  60
GROUP BY "method", "name";

DROP INDEX amount_index;

--endregion