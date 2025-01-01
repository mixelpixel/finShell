# finShell
Fun finance related stuff!  Specifically this repository was started in late December of 2024 with the purpose of keeping an eye on a particular portfolio of dividend yielding stocks (e.g. a list of my set of symbols and associated buy-in prices.)  There are a couple I have owned previously for some time (F, ET, SOL, T) and two high yield rate dividend stocks I have owned for at least one payment perio (HTGC & DKL).  Since March of 2020 when the market fell with the onset of COVID-19, I have been investing with Robinhoodd.  I mainly just bought a bunch of Apple at the time (which has done very well) and have made a couple well-timed buys of ye ol' dip since.  My working hypothesis is that the next quarter or two are likely to bear what are now unclear growth opportunities, so I figured I would bolster my dividend yielding stocks.  Ultimately I am looking to rceate a reporting script that will give me a quick overview of the stock's performance.  For each investment, I figure if the stock price stays above price minus annual yield, let 'er ride.  If it gets near or goes below that threshold, I figure I can just reallocate the funds tied up in that stock to another better opportunity.  I am NOT suggesting anyone follow suit, but these are the tools I'll be using and refining to collate the deets.  I am certain if someone who actually had ever studied economics and finance might do things very differently, but I am learning as I go :).

If these scripts can be of use to you, please have at them and let me know if you are able to make them better!

## q1-25divMonitor.sh
The script q1-25divMonitor.sh will show a portfolio of stocks, their average buy-in price, & the difference between that and the current price.
Example output:
```
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

Example output:
```
sh trailingAndFWDdivYield2.sh
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
