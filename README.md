# IPL Cricket Analytics

SQL analysis of 16 years of IPL match data -- 1,095 matches, 260,920 deliveries (2008-2024). Answers tactical and performance questions that a cricket franchise, broadcaster, or sports analytics team would actually care about.

---

## Dataset

- **Source:** [Kaggle -- IPL Complete Dataset (2008-2024)](https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020)
- **Tables:** `matches` (1,095 rows) · `deliveries` (260,920 rows)
- **Loaded into:** PostgreSQL 15 via psql

---

## Schema

| Table | Key Columns |
|---|---|
| matches | id, season, date, city, venue, team1, team2, toss_winner, toss_decision, winner, result, result_margin, method, target_runs, player_of_match |
| deliveries | match_id, inning, batting_team, bowling_team, over, ball, batter, bowler, batsman_runs, extra_runs, total_runs, is_wicket, player_dismissed, dismissal_kind |

---

## Analysis

Fifteen queries grouped into five areas.

### Batting

| Question | Techniques |
|---|---|
| Who are the top 10 run scorers all-time, with strike rate and runs per match? | Aggregation, NULLIF, ROUND |
| Who hit the most sixes -- and how does six-hitting correlate with total runs? | Conditional COUNT, ORDER BY |
| Who has the highest batting average in finals only? | JOIN on match metadata, NULL-safe average, HAVING |
| Who won the most Player of the Match awards -- and across how many seasons? | GROUP BY, NULL filter, MIN/MAX |

### Bowling

| Question | Techniques |
|---|---|
| Which bowlers have the best economy rate (minimum 100 overs bowled)? | HAVING, ROUND, casting, NULLIF |
| Who took the most wickets in PowerPlay overs (overs 1-6)? | WHERE with BETWEEN, dismissal kind exclusions |

### Team and Tactical Patterns

| Question | Techniques |
|---|---|
| What is each team's win percentage at home versus away? | CTE, UNION ALL, CASE, LEFT JOIN, team name normalization |
| Which teams chase successfully when the target exceeds 160? | Multi-CTE, conditional aggregation, HAVING with minimum attempt threshold |
| Does winning the toss actually improve a team's chance of winning? | CASE, conditional aggregation, percentage calculation |
| Which teams won more matches than the season average -- season by season? | Two-level CTE, GROUP BY, HAVING against a derived aggregate |
| Which teams are most consistent in first-innings scoring (lowest standard deviation)? | STDDEV_SAMP, multi-level aggregation, HAVING |

### Venue Intelligence

| Question | Techniques |
|---|---|
| Which venues produce the highest average first-innings scores? | Subquery join, GROUP BY, HAVING, MIN/MAX/AVG |
| Is each venue batting-first favoured or chase favoured? | Multi-CTE, CASE, aggregation, NULL handling |
| How many matches were decided by DLS versus normal result? | CASE inside subquery, window function (SUM OVER), percentage of total |

### Cross-Dimensional

| Question | Techniques |
|---|---|
| For each top-10 run scorer: career average, Player of the Match count, and best venue -- in a single query | 4-table join (deliveries, matches, POTM CTE, best-venue CTE), COALESCE, NULLIF, LEFT JOIN, DISTINCT ON |

---

## Technical Highlights

- **CTEs throughout** -- multi-step logic broken into named, readable stages rather than nested subqueries
- **Team name normalization** -- handles legacy franchises (Delhi Daredevils → Delhi Capitals, Kings XI Punjab → Punjab Kings) without touching the source data
- **NULLIF for divide-by-zero safety** -- all rate calculations (batting average, economy, win percentage) guard against zero denominators explicitly
- **HAVING for meaningful aggregation** -- minimum thresholds applied to economy rate (100 overs), chase analysis (5 attempts), venue analysis (5 or 10 matches) to avoid conclusions drawn from sparse data
- **Window function for proportions** -- DLS analysis uses `SUM(...) OVER ()` to calculate each result category as a percentage of all matches in a single pass
- **DISTINCT ON for best-per-group** -- identifies each batter's single best venue without a correlated subquery
- **NULL-safe dismissal counting** -- separates batter dismissals from run-outs and retired hurt using COALESCE and conditional CASE

---

## Tools

PostgreSQL 15 · psql · VS Code SQLTools

---

## Run It

```bash
# Load dataset
psql -d ipl_cricket -f ipl_analytics_queries.sql

# Or run a single query in psql
\i ipl_analytics_queries.sql
```
