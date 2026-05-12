# IPL Cricket Analytics

SQL portfolio project using the IPL Complete Dataset (2008-2024).

## Dataset
- Source: [Kaggle - IPL Complete Dataset](https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020)
- Tables: `matches` (1,095 rows), `deliveries` (260,920 rows)
- Loaded into: PostgreSQL via psql

## Schema

| Table | Column |
|---|---|
| matches | id, season, date, city, venue, team1, team2, toss_winner, toss_decision, winner, result, result_margin, method, super_over, target_runs, target_overs, player_of_match, match_type, umpire1, umpire2 |
| deliveries | match_id, inning, batting_team, bowling_team, over, ball, batter, bowler, non_striker, batsman_runs, extra_runs, total_runs, extras_type, is_wicket, player_dismissed, dismissal_kind, fielder |

## Queries (Week 1)

| # | Question |
|---|---|
| 1 | Top 10 run scorers across all seasons |
| 2 | Win % by team, home vs away |
| 3 | Best economy rate (min 100 overs) |
| 4 | Most successful chasing teams (targets > 160) |
| 5 | Most Player of the Match awards |
| 6 | Teams with most wins per season |
| 7 | Average first innings score by venue |
| 8 | DLS vs normal match results |
| 9 | Top 5 PowerPlay wicket-takers |
| 10 | Highest batting average in finals only |
| 11 | Most sixes all-time |
| 12 | Toss impact on match result |
| 13 | Most consistent batting teams by season |
| 14 | Venue run environment (bat first vs chase) |
| 15 | Checkpoint: 4-table join with HAVING and NULL handling |

## Tools
PostgreSQL · psql · VS Code SQLTools
