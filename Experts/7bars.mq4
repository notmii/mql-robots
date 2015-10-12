#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

// H1 Indicators
double haOpen_H1,
   haClose_H1,
   haPrevOpen_H1,
   haPrevClose_H1,
   macdBase_H1,
   macdPrevBase_H1,
   avgTrueRange_H1,
   trueRange_H1,
   ema20_H1;

// H4 Indicators
double haPrevOpen_H4,
   haPrevClose_H4,
   avgTrueRange_H4,
   trueRange_H4;

// D1 Indicators
double avgTrueRange_D1,
    trueRange_D1;

double highest,
    highestBuffer,
    lowest,
    lowestBuffer,
    lastClose;

void computeIndicators()
{
    // H1 Indicators
    haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    macdBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    macdPrevBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    avgTrueRange_H1 = iCustom(NULL, PERIOD_H1, "ATR", 20, 0, 1);
    trueRange_H1 = avgTrueRange_H1 / 5;
    ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);

    // H4 Indicators
    haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1);
    haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1);
    avgTrueRange_H4 = iCustom(NULL, PERIOD_H4, "ATR", 20, 0, 1);
    trueRange_H4 = avgTrueRange_H4 / 5;

    avgTrueRange_D1 = iCustom(NULL, PERIOD_D1, "ATR", 20, 0, 1);
    trueRange_D1 = avgTrueRange_D1 / 5;
}

void compute7BarRange()
{
    int index = Hour() > 3 ? Hour() - 3 : 21 + Hour();
    highest = High[index];
    lowest = Low[index];
    for (int i = 0; i < 7; i++) {
        highest = High[index + i] > highest ? High[index + i] : highest;
        lowest = Low[index + i] < lowest ? Low[index + i] : lowest;
    }
    highestBuffer = highest + trueRange_D1;
    lowestBuffer = lowest - trueRange_D1;
}

void paintTriggerLines()
{
    ObjectDelete(0, "highest");
    ObjectDelete(0, "highestBuffer");
    ObjectDelete(0, "lowest");
    ObjectDelete(0, "lowestBuffer");
    ObjectCreate("highest", OBJ_HLINE, 0, Time[0], highest, 0, 0);
    ObjectCreate("highestBuffer", OBJ_HLINE, 0, Time[0], highestBuffer, 0, 0);
    ObjectCreate("lowest", OBJ_HLINE, 0, Time[0], lowest, 0, 0);
    ObjectCreate("lowestBuffer", OBJ_HLINE, 0, Time[0], lowestBuffer, 0, 0);
}


int OnInit()
{
    computeIndicators();
    compute7BarRange();
    paintTriggerLines();
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    computeIndicators();
    compute7BarRange();
    paintTriggerLines();

    Comment(
        "    Balance: ", NormalizeDouble(AccountBalance(), 5),
        "\n    Equity: ", NormalizeDouble(AccountEquity(), 5),
        "\n    Margin: ", AccountMargin(),
        "\n    Free Margin: ", NormalizeDouble(AccountFreeMargin(), 5),
        "\n    Margin Level: ", AccountEquity() > 0 && AccountMargin() > 0 ?
            (int)((AccountEquity() / AccountMargin()) * 100) : "", "%",
        "\n    Leverage: 1:", AccountLeverage(),
        "\n    Spread: ", (int)((Ask - Bid) / Point),
        "\n",
        "\n    Master Trend: ", haPrevClose_H4 > haPrevOpen_H4 ? "UP" : "DOWN",
        "\n    Primary Trend: ", haPrevClose_H1 > haPrevOpen_H1 ? "UP" : "DOWN",
        "\n    EMA(20): ", Bid > ema20_H1 ? "UP" : "DOWN",
        ""
    );

    if (Bid >= highest
        && Bid <= highestBuffer
        && macdPrevBase_H1 < macdBase_H1
        && haPrevClose_H1 > haPrevOpen_H1) {

        //SendNotification("Buy position now!");
        // PlaySound("expert.wav");
        // OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
    }

    if (Bid <= lowest
        && Bid >= lowestBuffer
        && macdPrevBase_H1 > macdBase_H1
        && haPrevClose_H1 < haPrevOpen_H1) {

        //SendNotification("Sell position now!");
        // PlaySound("expert.wav");
        // OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
    }

}
