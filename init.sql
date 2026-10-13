-- Informations fixes sur les stations (une ligne par station)
CREATE TABLE IF NOT EXISTS stations (
    station_id  INTEGER PRIMARY KEY,
    nom         TEXT,
    adresse     TEXT,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION
);

-- Relevés de disponibilité (une ligne par station et par relevé)
CREATE TABLE IF NOT EXISTS releves (
    id             BIGSERIAL PRIMARY KEY,
    releve_at      TIMESTAMPTZ NOT NULL,
    station_id     INTEGER NOT NULL,
    statut         TEXT,
    capacite       INTEGER,
    velos          INTEGER,
    mecaniques     INTEGER,
    electriques    INTEGER,
    places_libres  INTEGER,
    last_update    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_releves_station_date
    ON releves (station_id, releve_at);

-- Calendrier de la période d'étude (une ligne par jour)
CREATE TABLE IF NOT EXISTS calendrier (
    jour                     DATE PRIMARY KEY,
    jour_semaine             INTEGER,            -- 1 = lundi ... 7 = dimanche
    est_weekend              BOOLEAN,
    est_ferie                BOOLEAN DEFAULT FALSE,
    nom_ferie                TEXT,
    vacances_scolaires       BOOLEAN DEFAULT FALSE,  -- zone C (Toulouse)
    vacances_universitaires  BOOLEAN DEFAULT FALSE   -- à remplir selon le calendrier de l'université
);

-- Une ligne par jour, du 7 octobre 2026 au 3 janvier 2027 inclus
INSERT INTO calendrier (jour, jour_semaine, est_weekend)
SELECT d::date,
       EXTRACT(ISODOW FROM d)::int,
       EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2026-10-07'::date, '2027-01-03'::date, interval '1 day') AS d
ON CONFLICT (jour) DO NOTHING;

-- Jours fériés de la période
UPDATE calendrier SET est_ferie = TRUE, nom_ferie = 'Toussaint'      WHERE jour = '2026-11-01';
UPDATE calendrier SET est_ferie = TRUE, nom_ferie = 'Armistice 1918' WHERE jour = '2026-11-11';
UPDATE calendrier SET est_ferie = TRUE, nom_ferie = 'Noël'           WHERE jour = '2026-12-25';
UPDATE calendrier SET est_ferie = TRUE, nom_ferie = 'Jour de l''an'  WHERE jour = '2027-01-01';

-- Vacances scolaires zone C (dates à vérifier sur le calendrier officiel)
-- Toussaint : du samedi 17 octobre au dimanche 1er novembre 2026
UPDATE calendrier SET vacances_scolaires = TRUE
WHERE jour BETWEEN '2026-10-17' AND '2026-11-01';
-- Noël : du samedi 19 décembre 2026 au dimanche 3 janvier 2027
UPDATE calendrier SET vacances_scolaires = TRUE
WHERE jour BETWEEN '2026-12-19' AND '2027-01-03';

-- Événements à relever au fil des semaines (manifestations, travaux métro, matchs, concerts...)
CREATE TABLE IF NOT EXISTS evenements (
    id           SERIAL PRIMARY KEY,
    debut        TIMESTAMPTZ NOT NULL,
    fin          TIMESTAMPTZ,
    type         TEXT,          -- 'manifestation', 'travaux_metro', 'match', ...
    description  TEXT,
    lieu         TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION
);
