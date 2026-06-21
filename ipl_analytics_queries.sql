-- ============================================================
-- IPL Cricket Database: Week 1 Portfolio Query Set
-- Dataset : IPL Complete Dataset (2008-2024)
--           kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020
-- Author  : Gnanendra
-- Project : Analytics-to-Engineering Transition | Week 1
-- ============================================================
-- ============================================================
-- QUERY 1: Top 10 Run Scorers Across All Seasons
-- ============================================================
-- Skills demonstrated: aggregation, ORDER BY, LIMIT, NULLIF
SELECT d.batter,
    SUM(d.batsman_runs) AS total_runs,
    COUNT(DISTINCT d.match_id) AS matches_played,
    COUNT(d.ball) AS balls_faced,
    ROUND(
        SUM(d.batsman_runs)::NUMERIC / NULLIF(COUNT(DISTINCT d.match_id), 0),
        2
    ) AS runs_per_match,
    ROUND(
        SUM(d.batsman_runs)::NUMERIC / NULLIF(COUNT(d.ball), 0) * 100,
        2
    ) AS strike_rate
FROM deliveries d
GROUP BY d.batter
ORDER BY total_runs DESC
LIMIT 10;
-- ============================================================
-- QUERY 2: Win Percentage by Team -- Home vs Away
-- ============================================================
-- Skills: CTE, UNION ALL, CASE, LEFT JOIN, window-free aggregation
-- Assumption: home city defined in the lookup CTE below.
-- Extend the VALUES list to cover all franchises in your dataset.
WITH team_home_city AS (
    SELECT team, city
    FROM (
        VALUES 
            ('Mumbai Indians', 'Mumbai'),
            ('Chennai Super Kings', 'Chennai'),
            ('Royal Challengers Bangalore', 'Bangalore'),
            ('Kolkata Knight Riders', 'Kolkata'),
            ('Sunrisers Hyderabad', 'Hyderabad'),
            ('Delhi Capitals', 'Delhi'),
            ('Rajasthan Royals', 'Jaipur'),
            ('Punjab Kings', 'Chandigarh'),
            ('Lucknow Super Giants', 'Lucknow'),
            ('Gujarat Titans', 'Ahmedabad')
    ) AS t(team, city)
),
normalized_matches AS (
    -- Standardize legacy team names to their current names across all columns
    SELECT 
        id,
        CASE 
            WHEN team1 = 'Delhi Daredevils' THEN 'Delhi Capitals'
            WHEN team1 = 'Kings XI Punjab' THEN 'Punjab Kings'
            ELSE team1 
        END AS team1,
        CASE 
            WHEN team2 = 'Delhi Daredevils' THEN 'Delhi Capitals'
            WHEN team2 = 'Kings XI Punjab' THEN 'Punjab Kings'
            ELSE team2 
        END AS team2,
        city,
        CASE 
            WHEN winner = 'Delhi Daredevils' THEN 'Delhi Capitals'
            WHEN winner = 'Kings XI Punjab' THEN 'Punjab Kings'
            ELSE winner 
        END AS winner
    FROM matches
),
all_match_appearances AS (
    -- Each match contributes two rows: one per team
    SELECT id, team1 AS team, city, winner
    FROM normalized_matches
    UNION ALL
    SELECT id, team2 AS team, city, winner
    FROM normalized_matches
),
classified AS (
    SELECT a.team,
        CASE
            WHEN a.city = h.city THEN 'Home'
            ELSE 'Away'
        END AS match_type,
        CASE
            WHEN a.winner = a.team THEN 1
            ELSE 0
        END AS won
    FROM all_match_appearances a
    LEFT JOIN team_home_city h ON a.team = h.team
    WHERE a.winner IS NOT NULL
)
SELECT 
    team,
    match_type,
    COUNT(*) AS total_matches,
    SUM(won) AS wins,
    ROUND(SUM(won)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS win_pct
FROM classified
WHERE match_type IN ('Home', 'Away')
GROUP BY team, match_type
ORDER BY team, match_type;

-- ============================================================
-- QUERY 3: Bowlers with Best Economy Rate (min 100 overs bowled)
-- ============================================================
-- Skills: aggregation, HAVING, ROUND, NULLIF, casting
-- Economy = runs conceded per over.
-- Extras bowled off wides/noballs count against the bowler (total_runs includes them).
SELECT d.bowler,
    COUNT(*) AS balls_bowled,
    ROUND(COUNT(*) / 6.0, 1) AS overs_bowled,
    SUM(d.total_runs) AS runs_conceded,
    ROUND(SUM(d.total_runs)::NUMERIC / NULLIF(COUNT(*) / 6.0, 0),2) AS economy_rate,
    SUM(CASE WHEN d.is_wicket = 1 AND d.dismissal_kind NOT IN ('run out', 'retired hurt') THEN 1
        ELSE 0 
        END) AS wickets
FROM deliveries d
GROUP BY d.bowler
HAVING ROUND(COUNT(*) / 6.0, 1) >= 100
ORDER BY economy_rate ASC
LIMIT 20;

-- ============================================================
-- QUERY 4: Most Successful Chasing Teams (Targets Above 160)
-- ============================================================
-- Skills: multi-CTE, conditional aggregation, HAVING, subquery join
WITH first_innings_totals AS (
    SELECT match_id,
        SUM(total_runs) AS first_innings_score
    FROM deliveries
    WHERE inning = 1
    GROUP BY match_id
),
match_chaser AS (
    SELECT m.id AS match_id,
        m.winner, 
        CASE -- Chasing team is whoever did NOT bat first
            WHEN m.toss_decision = 'field' THEN m.toss_winner
            ELSE CASE
                WHEN m.toss_winner = m.team1 THEN m.team2
                ELSE m.team1
            END
        END AS chasing_team,
        f.first_innings_score
    FROM matches m
        JOIN first_innings_totals f ON m.id = f.match_id
    WHERE m.winner IS NOT NULL
        AND m.result != 'no result'
)
SELECT chasing_team,
    COUNT(*) AS chases_attempted,
    SUM(CASE WHEN winner = chasing_team THEN 1
            ELSE 0
        END) AS successful_chases,
    ROUND( SUM(CASE WHEN winner = chasing_team THEN 1
                ELSE 0
            END)::NUMERIC / NULLIF(COUNT(*), 0) * 100,2 ) AS chase_success_pct,
    ROUND(AVG(first_innings_score), 1) AS avg_target_faced
FROM match_chaser
WHERE first_innings_score > 160
GROUP BY chasing_team
HAVING COUNT(*) >= 5 -- minimum 5 attempts for statistical relevance
ORDER BY chase_success_pct DESC;

-- ============================================================
-- QUERY 5: Players with Most Player of the Match Awards
-- ============================================================
-- Skills: GROUP BY, COUNT, NULL filter, ORDER BY
SELECT m.player_of_match,
    COUNT(*) AS potm_awards,
    COUNT(DISTINCT m.season) AS seasons_with_award,
    MIN(m.season) AS first_season,
    MAX(m.season) AS last_season
FROM matches m
WHERE m.player_of_match IS NOT NULL -- explicit NULL guard
GROUP BY m.player_of_match
ORDER BY potm_awards DESC
LIMIT 15;

-- ============================================================
-- QUERY 6: Teams with Most Wins Per Season (GROUP BY + HAVING)
-- Returns seasons where a team won MORE than the season-average wins
-- ============================================================
-- Skills: two-level CTE, GROUP BY, HAVING, JOIN on aggregate
WITH wins_per_team_season AS (
    SELECT season,
        winner AS team,
        COUNT(*) AS wins
    FROM matches
    WHERE winner IS NOT NULL
        AND result != 'no result'
    GROUP BY season,
        winner
),
season_averages AS (
    SELECT season,
        ROUND(AVG(wins), 2) AS avg_wins_per_team
    FROM wins_per_team_season
    GROUP BY season
)
SELECT w.season,
    w.team,
    w.wins AS team_wins,
    s.avg_wins_per_team
FROM wins_per_team_season w
    JOIN season_averages s ON w.season = s.season
Group BY w.season,
    w.team,
    w.wins,
    s.avg_wins_per_team
HAVING w.wins > s.avg_wins_per_team -- only above-average performers
ORDER BY w.season,
    w.wins DESC;

-- ============================================================
-- QUERY 7: Average First Innings Score by Venue
-- ============================================================
-- Skills: subquery join, GROUP BY, HAVING, MIN/MAX/AVG, ROUND
SELECT m.venue,
    m.city,
    COUNT(DISTINCT m.id) AS matches_at_venue,
    ROUND(AVG(fi.first_innings_score), 2) AS avg_first_innings,
    MAX(fi.first_innings_score) AS highest_score,
    MIN(fi.first_innings_score) AS lowest_score
FROM matches m
    JOIN (
        SELECT match_id,
            SUM(total_runs) AS first_innings_score
        FROM deliveries
        WHERE inning = 1
        GROUP BY match_id
    ) AS fi ON m.id = fi.match_id
GROUP BY m.venue,
    m.city
HAVING COUNT(DISTINCT m.id) >= 5 -- exclude venues with sparse data
ORDER BY avg_first_innings DESC;

-- ============================================================
-- QUERY 8: Matches Decided by DLS Method vs Normal Result
-- ============================================================
-- Skills: CASE inside subquery, window function (SUM OVER), INITCAP
SELECT result_category,
    match_count,
    ROUND(match_count::NUMERIC / SUM(match_count) OVER () * 100, 2) AS pct_of_all_matches
FROM (
        SELECT CASE
                WHEN UPPER(result) LIKE '%D/L%' THEN 'DLS Method'
                WHEN result = 'runs' THEN 'Won by Runs'
                WHEN result = 'wickets' THEN 'Won by Wickets'
                WHEN result = 'tie' THEN 'Tie'
                WHEN result = 'no result' THEN 'No Result'
                WHEN result IS NULL THEN 'Unknown / NULL'
                ELSE 'Other'
            END AS result_category,
            COUNT(*) AS match_count
        FROM matches
        GROUP BY result_category
    ) AS categorized
ORDER BY match_count DESC;

-- ============================================================
-- QUERY 9: Top 5 Bowlers by Wickets in PowerPlay Overs (0-5)
-- ============================================================
-- Skills: WHERE with BETWEEN, NOT IN for dismissal exclusions, NULL awareness
-- NOTE: adjust range to BETWEEN 1 AND 6 if your 'over' column is 1-indexed.
SELECT d.bowler,
    COUNT(*) AS powerplay_wickets,
    COUNT(DISTINCT d.match_id) AS matches_bowled_pp,
    ROUND(COUNT(*) / 6.0, 1) AS powerplay_overs_bowled
FROM deliveries d
WHERE d.over BETWEEN 0 AND 5 -- PowerPlay overs (0-indexed)
    AND d.is_wicket = 1
    AND COALESCE(d.dismissal_kind, '') NOT IN (
        'run out',
        'retired hurt',
        'obstructing the field'
    )
GROUP BY d.bowler
ORDER BY powerplay_wickets DESC
LIMIT 5;

-- ============================================================
-- QUERY 10: Batsmen with Highest Average in Finals Only
-- ============================================================
-- Skills: JOIN on match metadata, GROUP BY, HAVING, NULLIF, NULL-safe average
SELECT d.batter,
    SUM(d.batsman_runs) AS finals_runs,
    COUNT(*) AS balls_faced,
    -- Dismissals: rows where this batter was the one dismissed
    SUM(
        CASE
            WHEN d.player_dismissed = d.batter THEN 1
            ELSE 0
        END
    ) AS dismissals,
    ROUND(
        SUM(d.batsman_runs)::NUMERIC / NULLIF(
            SUM(
                CASE
                    WHEN d.player_dismissed = d.batter THEN 1
                    ELSE 0
                END
            ),
            0 -- prevent divide-by-zero for not-out batsmen
        ),
        2
    ) AS batting_average,
    ROUND(
        SUM(d.batsman_runs)::NUMERIC / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS strike_rate
FROM deliveries d
    JOIN matches m ON d.match_id = m.id
WHERE LOWER(m.match_type) = 'final' -- adjust if column uses 'Final' or 'SF' etc.
GROUP BY d.batter
HAVING SUM(d.batsman_runs) >= 30 -- minimum runs to qualify
ORDER BY batting_average DESC NULLS LAST -- NULLs for not-out players go to bottom
LIMIT 10;

-- ============================================================
-- QUERY 11: Most Sixes Hit -- All-Time Leaders
-- ============================================================
-- Skills: conditional COUNT, ROUND, ORDER BY
SELECT d.batter,
    SUM(
        CASE
            WHEN d.batsman_runs = 6 THEN 1
            ELSE 0
        END
    ) AS sixes,
    SUM(
        CASE
            WHEN d.batsman_runs = 4 THEN 1
            ELSE 0
        END
    ) AS fours,
    SUM(d.batsman_runs) AS total_runs,
    COUNT(DISTINCT d.match_id) AS matches
FROM deliveries d
GROUP BY d.batter
ORDER BY sixes DESC
LIMIT 10;

-- ============================================================
-- QUERY 12: Toss Impact -- Does Winning the Toss Help Win the Match?
-- ============================================================
-- Skills: CASE, conditional aggregation, percentage calculation
SELECT toss_decision,
    COUNT(*) AS total_matches,
    SUM(
        CASE
            WHEN toss_winner = winner THEN 1
            ELSE 0
        END
    ) AS toss_winner_also_won,
    ROUND(
        SUM(
            CASE
                WHEN toss_winner = winner THEN 1
                ELSE 0
            END
        )::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS toss_win_pct
FROM matches
WHERE winner IS NOT NULL
    AND result != 'no result'
GROUP BY toss_decision
ORDER BY toss_win_pct DESC;

-- ============================================================
-- QUERY 13: Most Consistent Batting Teams by Season
--           (lowest standard deviation in first-innings totals)
-- ============================================================
-- Skills: STDDEV_SAMP, multiple aggregations, HAVING
WITH team_innings_totals AS (
    SELECT m.season,
        d.batting_team,
        d.match_id,
        SUM(d.total_runs) AS innings_score
    FROM deliveries d
        JOIN matches m ON d.match_id = m.id
    WHERE d.inning = 1
    GROUP BY m.season,
        d.batting_team,
        d.match_id
)
SELECT season,
    batting_team,
    COUNT(match_id) AS innings_played,
    ROUND(AVG(innings_score), 1) AS avg_score,
    ROUND(STDDEV_SAMP(innings_score), 1) AS score_std_dev,
    MIN(innings_score) AS lowest_score,
    MAX(innings_score) AS highest_score
FROM team_innings_totals
GROUP BY season,
    batting_team
HAVING COUNT(match_id) >= 8 -- enough games for std dev to be meaningful
ORDER BY season,
    score_std_dev ASC;

-- ============================================================
-- QUERY 14: Venue-Level Run Environment
--           Batting-first win % vs chasing win % per venue
-- ============================================================
-- Skills: multi-CTE, CASE, aggregation, JOIN, NULL handling
WITH match_context AS (
    SELECT m.id,
        m.venue,
        m.winner,
        m.result,
        -- Determine who batted first
        CASE
            WHEN m.toss_decision = 'bat' THEN m.toss_winner
            ELSE CASE
                WHEN m.toss_winner = m.team1 THEN m.team2
                ELSE m.team1
            END
        END AS batting_first_team
    FROM matches m
    WHERE m.winner IS NOT NULL
        AND m.result != 'no result'
),
venue_results AS (
    SELECT venue,
        COUNT(*) AS total_matches,
        SUM(
            CASE
                WHEN winner = batting_first_team THEN 1
                ELSE 0
            END
        ) AS bat_first_wins,
        SUM(
            CASE
                WHEN winner != batting_first_team THEN 1
                ELSE 0
            END
        ) AS chase_wins
    FROM match_context
    GROUP BY venue
)
SELECT venue,
    total_matches,
    bat_first_wins,
    chase_wins,
    ROUND(
        bat_first_wins::NUMERIC / NULLIF(total_matches, 0) * 100,
        1
    ) AS bat_first_win_pct,
    ROUND(
        chase_wins::NUMERIC / NULLIF(total_matches, 0) * 100,
        1
    ) AS chase_win_pct,
    CASE
        WHEN bat_first_wins > chase_wins THEN 'Bat First Favoured'
        WHEN chase_wins > bat_first_wins THEN 'Chase Favoured'
        ELSE 'Neutral'
    END AS venue_type
FROM venue_results
WHERE total_matches >= 10   -- Changed from HAVING to WHERE
ORDER BY total_matches DESC;

-- ============================================================
-- QUERY 15: CHECKPOINT -- 4-Table Join with Aggregation,
--           HAVING, and NULL Handling
-- ============================================================
-- This query earns the Week 1 checkpoint sign-off.
-- It answers: "For each top-10 run scorer, what is their
--  POTM award count, economy rate when bowling, and which
--  venue produced their best batting returns?"
--
-- Four logical tables joined:
--   (1) deliveries  -- batting stats
--   (2) matches     -- match metadata (venue, season)
--   (3) potm_counts -- derived: Player of the Match tally (CTE)
--   (4) best_venue  -- derived: per-batter best venue (CTE)
--
-- NULL handling:
--   NULLIF prevents divide-by-zero in averages and economy.
--   COALESCE replaces NULLs in POTM count (players who never won).
--   NULL-safe CASE for bowler wicket exclusions.
WITH potm_counts AS (
    -- Table 3: Player of the Match award tally
    SELECT player_of_match AS player,
        COUNT(*) AS potm_awards
    FROM matches
    WHERE player_of_match IS NOT NULL
    GROUP BY player_of_match
),
batting_by_venue AS (
    -- Intermediate: runs per batter per venue
    SELECT d.batter,
        m.venue,
        SUM(d.batsman_runs) AS venue_runs,
        COUNT(DISTINCT d.match_id) AS venue_matches
    FROM deliveries d
        JOIN matches m ON d.match_id = m.id -- JOIN 1: deliveries -> matches
    WHERE d.inning IN (1, 2)
    GROUP BY d.batter,
        m.venue
),
best_venue AS (
    -- Table 4: Each batter's single best venue by total runs
    SELECT DISTINCT ON (batter) batter,
        venue AS best_venue,
        venue_runs AS best_venue_runs
    FROM batting_by_venue
    ORDER BY batter,
        venue_runs DESC
),
overall_batting AS (
    -- Table 1 aggregate: career batting stats
    SELECT d.batter,
        SUM(d.batsman_runs) AS career_runs,
        COUNT(DISTINCT d.match_id) AS matches_played,
        SUM(
            CASE
                WHEN d.player_dismissed = d.batter THEN 1
                ELSE 0
            END
        ) AS dismissals
    FROM deliveries d
    GROUP BY d.batter
)
SELECT ob.batter,
    ob.career_runs,
    ob.matches_played,
    ROUND(
        ob.career_runs::NUMERIC / NULLIF(ob.dismissals, 0),
        2
    ) AS batting_average,
    COALESCE(pc.potm_awards, 0) AS potm_awards,
    -- NULL -> 0
    bv.best_venue,
    bv.best_venue_runs
FROM overall_batting ob
    LEFT JOIN potm_counts pc ON ob.batter = pc.player -- JOIN 2: batting -> POTM
    LEFT JOIN best_venue bv ON ob.batter = bv.batter -- JOIN 3: batting -> venue
WHERE ob.career_runs >= 1000 -- combined the NULL guard and the 1000 run qualifier
ORDER BY ob.career_runs DESC
LIMIT 10;

-- ============================================================