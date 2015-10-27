#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

// H1 Indicators
double haOpen_M5,
   haClose_M5,
   haPrevOpen_M5,
   haPrevClose_M5,
   macdBase_M5,
   macdPrevBase_M5,
   stochasticMain_M5;

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

double tradeLots;

double diff,
    lastCloseTime,
    balanceToDefend;
int failTrades = 0;

bool hedgeMode = false;

int ticketNumber;

input double baseTradeLots = 0.01;
input double hedgeMultiplier = 10;
input int takeProfit = 50;
input int stopLoss = 150;
input int martingaleGrid = 100;
input int maxMartingaleTrade = 3;

double _takeProfit, _stopLoss, _martingaleGrid, previousLots;

void computeIndicators() {
    // M15 Indicators
    haOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 0);
    haClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 0);
    haPrevOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 1);
    haPrevClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 1);
    macdBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    macdPrevBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    stochasticMain_M5 = iStochastic(NULL, PERIOD_M5, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);

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

    avgTrueRange_D1 = iCustom(NULL, PERIOD_D1, "ATR", 2, 0, 1);
    trueRange_D1 = avgTrueRange_D1 / 5;


}

void displayComment() {
    Comment(
        "    Balance: ", NormalizeDouble(AccountBalance(), 5),
        "\n    Equity: ", NormalizeDouble(AccountEquity(), 5),
        "\n    Margin: ", AccountMargin(),
        "\n    Free Margin: ", NormalizeDouble(AccountFreeMargin(), 5),
        "\n    Margin Level: ", AccountEquity() > 0 && AccountMargin() > 0 ?
            (int)((AccountEquity() / AccountMargin()) * 100) : "", "%",
        "\n    Leverage: 1:", AccountLeverage(),
        "\n    Spread: ", (int)((Ask - Bid) / Point),
        "\n    Defend: ", balanceToDefend,
        "\n",
        "\n    Master Trend: ", haPrevClose_H4 > haPrevOpen_H4 ? "UP" : "DOWN",
        "\n    Primary Trend: ", haPrevClose_H1 > haPrevOpen_H1 ? "UP" : "DOWN",
        "\n    EMA(20): ", Bid > ema20_H1 ? "UP" : "DOWN",
        "\n    Previous Lots: ", previousLots,
        "\n    Fail Total: ", (int)failTrades,
        "\n    Hedge Mode: ", hedgeMode,
        ""
    );
}

void closeAllOpen() {
    int total = OrdersTotal();
    for(int i; i < total; i++) {
        OrderSelect(0, SELECT_BY_POS);
        int ticketNumber = OrderTicket();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        OrderClose(ticketNumber, OrderLots(), price, 3);
    }
}

void blah() {
    if (OrderProfit() < 0) {
        failTrades++;
        hedgeMode = failTrades <= maxMartingaleTrade;
        failTrades = hedgeMode ? failTrades : 0;
    } else {
        hedgeMode = false;
        failTrades = 0;
    }

    closeAllOpen();
}

void martingale() {
    if (OrdersTotal() == 0) {
        return;
    }

    OrderSelect(0, SELECT_BY_POS);

    if (OrderType() == OP_BUY && (MathAbs(Bid - OrderOpenPrice()) / Point) >= martingaleGrid) {
        blah();
    }

    if (OrderType() == OP_SELL && (MathAbs(Ask - OrderOpenPrice()) / Point) >= martingaleGrid) {
        blah();
    }
}

void openPosition() {
    if (OrdersTotal() > 0) {
        return;
    }

    balanceToDefend = hedgeMode ? balanceToDefend : AccountBalance();
    double lots = hedgeMode ? previousLots * 2 : baseTradeLots;

    if (haPrevClose_H4 > haPrevOpen_H4
        && haPrevClose_H1 > haPrevOpen_H1
        // && haClose_H1 > haOpen_H1
        // && macdPrevBase_M5 > 0
        && macdPrevBase_M5 < macdBase_M5) {

        ticketNumber = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy", 0, 0, Green);

        if (!hedgeMode) {
            OrderModify(ticketNumber, OrderOpenPrice(), 0, Ask + _takeProfit, 0, Red);
            hedgeMode = false;
            failTrades = 0;
        }

        previousLots = lots;
    }

    if (haPrevClose_H4 < haPrevOpen_H4
        && haPrevClose_H1 < haPrevOpen_H1
        // && haClose_H1 < haOpen_H1
        // && macdPrevBase_M5 < 0
        && macdPrevBase_M5 < macdBase_M5) {

        ticketNumber = OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell", 0, 0, Green);
        if (!hedgeMode) {
            OrderModify(ticketNumber, OrderOpenPrice(), 0, Bid - _takeProfit, 0, Red);
            hedgeMode = false;
            failTrades = 0;
        }

        previousLots = lots;
    }
}

int OnInit() {
    computeIndicators();
    displayComment();
    _takeProfit = takeProfit * Point;
    _stopLoss = stopLoss * Point;
    _martingaleGrid = martingaleGrid * Point;
    return(INIT_SUCCEEDED);
}

void OnTick() {
    computeIndicators();
    displayComment();
    martingale();
    openPosition();
    displayComment();
}
