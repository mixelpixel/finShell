# finShell
  Fun finance related stuff!  Specifically written for macOS zsh (BSD)

  This repository was started in late December of 2024 with the purpose of keeping an eye on a particular portfolio of dividend yielding stocks (e.g. a list of my particular set of symbols and associated buy-in prices.)  There are a couple I have owned previously for some time (F, ET, SOL, T) and two high yield rate dividend stocks I have owned for at least one payment period (HTGC & DKL).  In my head, I am looking at those positions as able to weather a little more market volatility, and a future goal for this project is to incclude in the portfolio reports factoring of such leverage (as contrasted to the main onus of this portfolio: MAXIMAL short term dividend yields governed by cler risk mitigation boundaries.) Since March of 2020 when the market fell with the onset of COVID-19, I have been investing with Robinhoodd.  I mainly just bought a bunch of Apple at the time (which has done very well since) and have made a couple well-timed buys of ye ol' dip since (e.g. $META in'22).  I have learnerd a lot about being patient and tempering expectation.  Robinhood was very convenient to learn with a small account.  Now that it has grown, I am at the limits of what Robinhoood offers to help me manage my portfolio, so I thought I would see what I could achieve without spending any more money on services juust to access e.g. financial data.

  My working hypothesis for the portfolio is that the next quarter or two are likely to bear what are now, to me, unclear growth opportunities.  I figured I would bolster my dividend yielding stocks to keep the income incoming.  Ultimately I am looking to ceate a reporting script that will give me a quick overview of the portfolio's performance so I can monitor for exit signals and avoid losing money.  For each investment, I figure if the stock price stays above buy-in price minus annual dividend yield, let 'er ride.  If it gets near or goes below that threshold, I figure I can just reallocate the funds tied up in that stock to another better opportunity.  E.g. if I plunk a benjamin on a stock and the annual yield at buy in is "20%" it's TOO GOOD TO BE TRUE but I want to believe . . . (yes, I hoped Mike Tyson would knock ouut Jake Paul) so, if it stays above $80, I will keep it in and earning interest.  I am still wrapping my head around dividend financing scheduling, but in this example, the annual yield is $20 and if the payments are monthly, then each pay period yields 1/2th of that ($1.66 or 1.66%).  There may soon be a world where I want to assess varying schedules in timelines per payment frequency, but this is already getting very mathy quick and all I am really concerned about is the bottom line.  For now, it is enough to know that the $1.66 would then be 2.075% or 24.9% . . . so the yield rates are misleading and need to be put against the declared price at the time of payment vs time of declaration.  And here's why it is worth it - if the decllared payment is issued at 100% then that $20 "loss" in stock price is offset by $1.66 AND if the stock remains above my initial $80, then next thing to consider is _how many payments will there be at that yield with 100% payout?_  The answer to this would help to figure "how long ddo I stay in?"  Per the working approach, I plan on owning none of these after q1 and am alright if I lose 10% of the total portfolio as expense to LEARNING (both finance and programming with the help of the free tier of OpenAI's Chat GPT).  If, however, there is growth, then at the end of q1 I can either cash it out, or let it ride and REAP THE WHIRLWIND!

  I am NOT suggesting anyone follow my suit, but these are the tools I'll be using and refining to collate the deets.  I am certain if someone who actually had ever studied economics and finance would do things very differently, but I am learning as I go :)  With that in mind, my secondary goal is to get this useful so I can monitor additional portfolio lists for other potential investments (i.e. I might expand it to collate basic financials and e.g. look at a much bigger list of ~100 potential dividend stock investment candidates).

  For some context, I started last year looking into stock options trading and quickly realized that I had a lot to learn about economics and finance!  I also reallized it takes a lot more discipline to keep your eye on the ball and to remain both impartial and analytical than I was incentivized to apply.  I figured this wouldd be a more approachble goal for also building my habits to support financial stewardship.

  If these scripts can also be of use to you, please have at them and let me know if you are able to make them better, thanks,
  - Patrick

## q1-25divMonitor.sh
The script q1-25divMonitor.sh will show a portfolio of stocks, their average buy-in price, & the difference between that and the current price.

Portfolio i.e. a single stock or cryptocurrency symbol, and that asset's buy-in price for a single-stock at the time of purchase) e.g. in BSD zsh syntax:

```sh
portfolio=(
  "OXLC:5.09"
  "BCE:22.63"
  "ABR:13.68"
  "GNK:14.05"
)
```

Example output:
```term
$ q1-25divMonitor.sh
Symbol | Buy-In Price | Current Price | Delta      | % Change
-------------------------------------------------------------
OXLC   | 5.09         | 5.07          | -.02       | -0.39   %
BCE    | 22.63        | 23.18         | .55        |  2.43   %
ABR    | 13.68        | 13.85         | .17        |  1.24   %
GNK    | 14.05        | 13.94         | -.11       | -0.78   %
CSWC   | 21.47        | 21.82         | .35        |  1.63   %
DKL    | 40.62        | 42.26         | 1.64       |  4.04   %
HTGC   | 18.39        | 20.09         | 1.70       |  9.24   %
AB     | 37.45        | 37.09         | -.36       | -0.96   %
WES    | 38.75        | 38.43         | -.32       | -0.82   %
BTI    | 36.31        | 36.32         | .01        |  0.03   %
F      | 9.91         | 9.9           | -.01       | -0.10   %
EPR    | 44.1         | 44.28         | .18        |  0.41   %
MO     | 52.38        | 52.29         | -.09       | -0.17   %
ET     | 11.98        | 19.59         | 7.61       |  63.52  %
SOL    | 123.14       | 193.375       | 70.235     |  57.04  %
ATNI   | 22.46        | 16.81         | -5.65      | -25.16  %
T      | 19.5         | 22.77         | 3.27       |  16.77  %
```

## q1-25divINFO.sh
  The script q1-25divINFO.sh will show a portfolio of stocks, their average buy-in price, the current price, a summative of the previous year's dividend payments for a trailing annual yield, and the projected forward annual yield.  Most stocks in this portfolio are quarterly.  I have not (yet!) handled the one cryptocurrency I want to report on (and for the purposes of this fiscal qtr, I will prolly just hard-code a ballpark target of ~6+%).  OF NOTE: Most stocks in this portfolio are quarterly, but some are monthly, and I have done what I can to account for disbursed payments per most recent payment date.  If you want to apply this script to a dividend earning portfolio with more complex structures and schedules, I wish you the best.

Example output (Symbol burgers):
```term
$ sh trailingAndFWDdivYield2.sh
OXLC:
  Buy-in Price: 5.09
  Current Price: 5.07
  Total Dividends (Last Year): 1.29
  Trailing Yield: 25.44%
  Projected Total Dividends (Next Year): 1.08
  Forward Yield: 21.30%

CSWC:
  Buy-in Price: 21.47
  Current Price: 21.82
  Total Dividends (Last Year): 2.53
  Trailing Yield: 11.59%
  Projected Total Dividends (Next Year): 2.52
  Forward Yield: 11.55%

DKL:
  Buy-in Price: 40.62
  Current Price: 42.26
  Total Dividends (Last Year): 4.315
  Trailing Yield: 10.21%
  Projected Total Dividends (Next Year): 4.4
  Forward Yield: 10.41%

HTGC:
  Buy-in Price: 18.39
  Current Price: 20.09
  Total Dividends (Last Year): 1.92
  Trailing Yield: 9.56%
  Projected Total Dividends (Next Year): 1.92
  Forward Yield: 9.56%

T:
  Buy-in Price: 19.5
  Current Price: 22.77
  Total Dividends (Last Year): 1.3875
  Trailing Yield: 6.09%
  Projected Total Dividends (Next Year): 1.1100
  Forward Yield: 4.87%
```

### q1-25divINFO.v2.sh
Example output (a [table](https://youtu.be/dWOGbu5BcT0)):
```term
$ sh q1-25divINFO.v2.sh
+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+
| Symbol | Buy-in Price | Curr. Price  | Tot. Div. (Last Yr)   | TRAIL YLD    | Proj. Div. (Next Yr)    | FWD YLD   |
+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+
| OXLC   | 5.09         | 5.07         | 1.29                  | 25.44%       | 1.08                    | 21.30%    |
| BCE    | 22.63        | 23.18        | 4.18069110075         | 18.04%       | 3.9900                  | 17.21%    |
| ABR    | 13.68        | 13.85        | 1.72                  | 12.42%       | 1.72                    | 12.42%    |
| GNK    | 14.05        | 13.94        | 1.57                  | 11.26%       | 1.6                     | 11.48%    |
| CSWC   | 21.47        | 21.82        | 2.53                  | 11.59%       | 2.52                    | 11.55%    |
| DKL    | 40.62        | 42.26        | 4.315                 | 10.21%       | 4.4                     | 10.41%    |
| HTGC   | 18.39        | 20.09        | 1.92                  | 9.56%        | 1.92                    | 9.56%     |
| AB     | 37.45        | 37.09        | 2.98                  | 8.03%        | 3.08                    | 8.30%     |
| WES    | 38.75        | 38.43        | 2.325                 | 6.05%        | 3.500                   | 9.11%     |
| BTI    | 36.31        | 36.32        | 3.694969              | 10.17%       | 2.972236                | 8.18%     |
| F      | 9.91         | 9.9          | .78                   | 7.88%        | .60                     | 6.06%     |
| EPR    | 44.1         | 44.28        | 3.675                 | 8.30%        | 3.420                   | 7.72%     |
| MO     | 52.38        | 52.29        | 4.98                  | 9.52%        | 4.08                    | 7.80%     |
| ET     | 11.98        | 19.59        | 1.2750                | 6.51%        | 1.2900                  | 6.58%     |
| SOL    | 123.14       | 193.705      | n/a                   | n/a          | 11.622                  | 6.00%     |
| ATNI   | 22.46        | 16.81        | 1.20                  | 7.14%        | .96                     | 5.71%     |
| T      | 19.5         | 22.77        | 1.3875                | 6.09%        | 1.1100                  | 4.87%     |
+--------+--------------+--------------+-----------------------+--------------+-------------------------+-----------+
```

Next up, I think I would like to combine the two into one table showing pertinent dividend details with the basic position.  I am not entirely sure, however, that I fully grasp the math yet for teasing out what I expect vs. where it's going.  I would also like to finesse how crypto is situated given the variable reward rates from staking (so I would want a mic of price and yield as a exit floor), but for now I need to go touch some grass since this is now in a useful state (as of Jan 1, 3:30pm MST)

## q1-25divDATES.sh
Dividend Finance Scheduling data report.  Note the asterisks on the Declaration Date to indicate stocks with near future declarations.  When the Declaration Date matches the day the script is run, it will display a leading asterisk(*).  In the example below, the report was run on 01/02/2025
Example output:
```term
> sh q1-25divDATES.sh
| Symbol     | Cash Amount    | Declaration Date   | Ex-Dividend Date   | Pay Date     | Frequency  |
|------------|----------------|--------------------|--------------------|--------------|------------|
| OXLC       | 0.09           | 2024-11-01         | 2025-01-17         | 2025-01-31   | 12         |
| BCE        | 0.9975         | 2024-11-07         | 2024-12-16         | 2025-01-15   | 4          |
| ABR        | 0.43           | 2024-11-01         | 2024-11-15         | 2024-11-27   | 4          |
| GNK        | 0.4            | 2024-11-06         | 2024-11-18         | 2024-11-25   | 4          |
| CSWC       | 0.05           | 2024-10-23*        | 2024-12-13         | 2024-12-31   | 4          |
| DKL        | 1.1            | 2024-10-29         | 2024-11-08         | 2024-11-14   | 4          |
| HTGC       | 0.4            | 2024-10-28         | 2024-11-13         | 2024-11-20   | 4          |
| AB         | 0.77           | 2024-10-24*        | 2024-11-04         | 2024-11-21   | 4          |
| WES        | 0.875          | 2024-10-17*        | 2024-11-01         | 2024-11-14   | 4          |
| BTI        | 0.743059       | 2024-02-08*        | 2024-12-20         | 2025-02-06   | 4          |
| F          | 0.15           | 2024-10-28         | 2024-11-07         | 2024-12-02   | 4          |
| EPR        | 0.285          | 2024-12-12         | 2024-12-31         | 2025-01-15   | 12         |
| MO         | 1.02           | 2024-12-11         | 2024-12-26         | 2025-01-10   | 4          |
| ET         | 0.3225         | 2024-10-28         | 2024-11-08         | 2024-11-19   | 4          |
| ATNI       | 0.24           | 2024-12-18         | 2024-12-31         | 2025-01-08   | 4          |
| T          | 0.2775         | 2024-12-12         | 2025-01-10         | 2025-02-03   | 4          |

=== NEAR FUTURE Ex-Dividend Date Report ===
Ex-Dividend dates occurring in the next 10 days:
| Symbol     | Ex-Dividend Date   |
|------------|--------------------|
| T          | 2025-01-10         |
```

# Note
These scripts can be described as Zsh with GNU utilities flavor. Here's why:
1. **Shell Type:** The script explicitly uses `#!/bin/zsh`, which indicates it's written for the Z shell (Zsh).
2. **Utilities Used:** It relies heavily on external tools like `curl`, `jq`, and `bc`. These are common utilities found in many Unix-like environments, but their behavior (especially for `jq` and `bc`) typically aligns with the GNU core utilities.
3. **Portability:**
  - BSD utilities might behave differently from GNU utilities (e.g., flags in tools like `date` or `echo`).
  - The script uses `date` commands (e.g., `date -j -f`) with behavior found in macOS/BSD-style `date` utilities, but it assumes GNU-style compatibility in other areas (e.g., `bc` calculations).
  - Therefore, it's a blend, but its reliance on Zsh-specific features places it solidly in the Zsh ecosystem.

Key Notes:
- If running on pure BSD environments, modifications might be required for utilities like `date`.
- For Linux users, GNU tools are the default, but the Zsh shell must still be installed if not already present.
