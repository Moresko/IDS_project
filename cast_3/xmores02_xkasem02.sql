--TODO popisovat ake data sa hladaju

-- Zmazanie tabuliek
DROP TABLE "RESERVATION_ROOM";
DROP TABLE "RESERVATION_SERVICE";
DROP TABLE "SERVICES";
DROP TABLE "RESERVATIONS";
DROP TABLE "PAYMENTS";
DROP TABLE "GUESTS";
DROP TABLE "ROOMS";

--region DRUHA CAST
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
    "ID"               INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "check_in"         DATE                      NOT NULL
        CHECK ( EXTRACT(YEAR FROM "check_in") >= 2022 ),
    "check_out"        DATE                      NOT NULL,
    CHECK ( EXTRACT(YEAR FROM "check_in") <= EXTRACT(YEAR FROM "check_out")
        AND EXTRACT(MONTH FROM "check_in") <= EXTRACT(MONTH FROM "check_out")
        AND EXTRACT(DAY FROM "check_in") < EXTRACT(DAY FROM "check_out")),
    "number_of_guests" INT                       NOT NULL
        CHECK ("number_of_guests" >= 1),
    "payment_id"       INT                       NOT NULL,
    CONSTRAINT "reservation_payment_id_foreign_key"
        FOREIGN KEY ("payment_id") REFERENCES "PAYMENTS" ("ID")
            ON DELETE CASCADE,
    "guest_id"         INT                       NOT NULL,
    CONSTRAINT "reservation_guest_id_foreign_key"
        FOREIGN KEY ("guest_id") REFERENCES "GUESTS" ("ID")
            ON DELETE CASCADE

);

CREATE TABLE "SERVICES"
(
    "ID"                    INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "cost"                  INT                       NOT NULL,
    "hours_available_from"  VARCHAR(5)                NOT NULL
        CHECK ( regexp_like("hours_available_from", '(^[0-1][0-9]:[0-5][0-9]$)|(^2[0-3]:[0-5][0-9]$)') ),
    "hours_available_until" VARCHAR(5)                NOT NULL
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

--Spojenie 2 tabuliek
--Ktori hostia platili kartou (Guest_ID, Name, Surname)
SELECT "guest_id" Guest_ID, "name" Name, "surname" Surname
FROM "PAYMENTS",
     "GUESTS"
WHERE "GUESTS"."ID" = "PAYMENTS"."guest_id"
  AND "PAYMENTS"."method" = 'card';

-- Spojenie 2 tabluek
-- Sposoby platby vsetkych rezervacii (Reservation_ID, Method, Amount)
SELECT "RESERVATIONS"."ID" Reservation_ID, "PAYMENTS"."method" Method, "PAYMENTS"."amount" Amount
FROM "PAYMENTS",
     "RESERVATIONS"
WHERE "RESERVATIONS"."payment_id" = "PAYMENTS".ID;

-- klauzula GROUP BY a agregacna funkcia
-- Pocet rezervacii jednotlivych izieb (Room_ID, Number_of_reservations)
SELECT "ROOMS"."ID" Room_ID, COUNT(*) Number_of_reservations
FROM "RESERVATIONS",
     "RESERVATION_ROOM",
     "ROOMS"
WHERE "RESERVATION_ROOM"."reservation_id" = "RESERVATIONS"."ID"
  AND "RESERVATION_ROOM"."room_id" = "ROOMS"."ID"
GROUP BY "ROOMS".ID;

-- klauzula GROUP BY a agregacna funkcia
-- Typy kuchyn veceri a ich priemerna cena (Cuisine, Average_cost)
SELECT "cuisine" Cuisine, AVG("cost") Average_cost
FROM "SERVICES"
WHERE "cuisine" IS NOT NULL
GROUP BY "cuisine";

-- predikat IN s vnorenym SELECT
-- Zoznam izieb, ktore maju vyhlad na more a ich zariadenie je standardne (ROOM_ID, NUMBER_OF_BEDS)
SELECT "ROOMS"."ID" ROOM_ID, "ROOMS"."number_of_beds" NUMBER_OF_BEDS
FROM "ROOMS"
WHERE "ROOMS"."room_view" IN (SELECT "room_view" FROM "ROOMS" WHERE "room_view" = 'sea')
  AND "facilities" = 'standard';

-- spojenie 3 tabuliek
-- Pocet hosti, ktori maju vyhlad na areal (Number_of_guests)
SELECT SUM("number_of_guests") Number_of_guests
FROM "ROOMS",
     "RESERVATION_ROOM",
     "RESERVATIONS"
WHERE "ROOMS"."ID" = "RESERVATION_ROOM"."room_id"
  AND "RESERVATIONS"."ID" = "RESERVATION_ROOM"."reservation_id"
  AND "ROOMS"."room_view" = 'areal';

-- predikat EXISTS
-- Hostia ktori rezervovali sluzbu (Guest_ID, Name, Surname)
SELECT "GUESTS"."ID" Guest_ID, "GUESTS"."name" Name, "GUESTS"."surname" Surname
FROM "RESERVATIONS",
     "GUESTS"
WHERE EXISTS(SELECT * FROM "RESERVATION_SERVICE" WHERE "RESERVATIONS"."ID" = "RESERVATION_SERVICE"."reservation_id")
  AND "RESERVATIONS"."guest_id" = "GUESTS"."ID"
ORDER BY "GUESTS"."ID";
