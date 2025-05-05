-- Zmazanie tabuliek
DROP TABLE "RESERVATION_ROOM";
DROP TABLE "RESERVATION_SERVICE";
DROP TABLE "SERVICES";
DROP TABLE "RESERVATIONS";
DROP TABLE "PAYMENTS";
DROP TABLE "GUESTS";
DROP TABLE "ROOMS";

--TODO Checknut vsetky zmeny oproti casti 1 a zapisat ich do /cast_2/README.md
--TODO pridat do ERD Guest(1..*)-Stays in-Room(1) ??? dame to tam/nedame?
-- ak to tam nedame, tak vymazat z GUESTS "room_id" a constraint foreing key on delete
-- a upravit insert aby tam nebolo na konci "room_id" a prislusne data
--TODO ON DELETE nastavit bud CASCADE alebo SET NULL
--TODO odovzdat

--  Vytvorenie tabuliek
CREATE TABLE "ROOMS"
(
    "ID"             INT NOT NULL PRIMARY KEY
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
    "name"    VARCHAR(255) NOT NULL,
    "surname" VARCHAR(255) NOT NULL,
    "phone"   VARCHAR(22)  NOT NULL,
    "email"   VARCHAR(255) NOT NULL
        CHECK ( regexp_like("email", '^[a-zA-Z]+[a-zA-Z0-9.]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') ),
    "room_id"         INT               NOT NULL,
        CONSTRAINT "guest_room_id_foreign_key"
        FOREIGN KEY ("room_id") REFERENCES "ROOMS" ("ID")
            ON DELETE CASCADE
);

CREATE TABLE "PAYMENTS"
(
    "ID"       INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "method"   VARCHAR(255)              NOT NULL
        CHECK ( "method" in ('card', 'cash', 'check')),
    "amount"   INT                       NOT NULL
        CHECK ( "amount" > 0 ),
    "guest_id" INT               NOT NULL,
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
    "guest_id"         INT               NOT NULL,
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

INSERT INTO "GUESTS" ("name", "surname", "phone", "email", "room_id")
VALUES ('Jakub', 'Kasem', '+421 904 880 512', 'vymysleny.email@gmail.com', 444);
INSERT INTO "GUESTS" ("name", "surname", "phone", "email", "room_id")
VALUES ('Patrik', 'Vrbovsky', '+421950334232', 'rytmus@rytmus.sk', 444);
INSERT INTO "GUESTS" ("name", "surname", "phone", "email", "room_id")
VALUES ('Martin', 'Mores', '+226 517 250', 'dalsi.vymyslenyEmail@apple.com', 618);
INSERT INTO "GUESTS" ("name", "surname", "phone", "email", "room_id")
VALUES ('Michael', 'Kmet', '421915432121', 'pointOFview@seznam.cz', 618);
INSERT INTO "GUESTS" ("name", "surname", "phone", "email", "room_id")
VALUES ('Tomas', 'Klimik', '+421 905 839 123', 'klimcoo@centrum.sk', 444);

INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('card', 100, 3);
INSERT INTO "PAYMENTS" ("method", "amount", "guest_id")
VALUES ('cash', 50, 1);

INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-06-02 17:30', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-06-05 10:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 2, 1, 1);
INSERT INTO "RESERVATIONS" ("check_in", "check_out", "number_of_guests", "payment_id", "guest_id")
VALUES (TO_DATE('2022-07-10 15:30', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'),
        TO_DATE('2022-07-11 12:00', 'YYYY-MM-DD HH24:MI', 'NLS_DATE_LANGUAGE=AMERICAN'), 1, 2, 4);

INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (15, '18:30', '21:50', 'indian');
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "method", "duration")
VALUES (30, '10:00', '18:00', 'thai', '30 min');
INSERT INTO "SERVICES" ("cost", "hours_available_from", "hours_available_until", "cuisine")
VALUES (15, '18:30', '21:50', 'czech');

INSERT INTO "RESERVATION_SERVICE" ("reservation_id", "service_id")
VALUES (2, 1);
INSERT INTO "RESERVATION_SERVICE" ("reservation_id", "service_id")
VALUES (2, 2);

INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (1, 618);
INSERT INTO "RESERVATION_ROOM" ("reservation_id", "room_id")
VALUES (2, 444);