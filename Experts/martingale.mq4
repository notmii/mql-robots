#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

// M5 Indicators
double haOpen_M5,
   haClose_M5,
   haPrevOpen_M5,
   haPrevClose_M5,
   macdBase_M5,
   macdPrevBase_M5;

// M15 Indicators
double haOpen_M15,
   haClose_M15,
   haPrevOpen_M15,
   haPrevClose_M15,
   macdBase_M15,
   macdPrevBase_M15;

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
    trueRange_D1,
    trueRange_D1_2;

double tradeLots;

double diff,
    lastCloseTime,
    balanceToDefend,
    maxDrawDown,
    totalBuyLot,
    totalSelLot,
    martingaleGrid;

bool hedgeMode = false;

int ticketNumber;

input double hedgeMultiplier = 2;
input double baseTradeLots = 0.1;
input double maxAmountCanBeLoss = 10;

void computeIndicators() {
    // M5 Indicators
    // haOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 0);
    // haClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 0);
    // haPrevOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 1);
    // haPrevClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 1);
    // macdBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    // macdPrevBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);

    // M15 Indicators
    haOpen_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 2, 0);
    haClose_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 3, 0);
    haPrevOpen_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 2, 1);
    haPrevClose_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 3, 1);
    macdBase_M15 = iMACD(NULL, PERIOD_M15, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    macdPrevBase_M15 = iMACD(NULL, PERIOD_M15, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);

    // H1 Indicators
    haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    // macdBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    // macdPrevBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    // avgTrueRange_H1 = iCustom(NULL, PERIOD_H1, "ATR", 20, 0, 1);
    // trueRange_H1 = avgTrueRange_H1 / 5;
    ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);

    // H4 Indicators
    haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1);
    haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1);
    // avgTrueRange_H4 = iCustom(NULL, PERIOD_H4, "ATR", 4, 0, 1);
    // trueRange_H4 = avgTrueRange_H4 / 5;

    // D1 Indicators
    avgTrueRange_D1 = iCustom(NULL, PERIOD_D1, "ATR", 2, 0, 1);
    trueRange_D1 = avgTrueRange_D1 / 5;
    trueRange_D1_2 = avgTrueRange_D1 / 10;
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
        "\n",
        "\n    Master Trend: ", haPrevClose_H4 > haPrevOpen_H4 ? "UP" : "DOWN",
        "\n    Primary Trend: ", haPrevClose_H1 > haPrevOpen_H1 ? "UP" : "DOWN",
        "\n    EMA(20): ", Bid > ema20_H1 ? "UP" : "DOWN",
        "\n    ATR_D1: ", (int)(avgTrueRange_D1 / Point),
        "\n    ATR_H4: ", (int)(avgTrueRange_H4 / Point),
        "\n",
        "\n    Def Balance: ", NormalizeDouble(balanceToDefend, 5),
        "\n    Max Lost: ", NormalizeDouble(balanceToDefend - maxAmountCanBeLoss, 5),
        ""
    );
}

void closeAllOpen() {
    int total = OrdersTotal();
    for (int index = 0; index < total; index++) {
        OrderSelect(0, SELECT_BY_POS);
        ticketNumber = OrderTicket();
        double closePrice = OrderType() == OP_BUY ? Bid : Ask;
        OrderClose(ticketNumber, OrderLots(), closePrice, 3, Red);
    }
    ticketNumber = NULL;
}

void computeOpenLots() {
    totalBuyLot = 0;
    totalSelLot = 0;
    for (int index = 0; index < OrdersTotal(); index++) {
        OrderSelect(index, SELECT_BY_POS);
        if (OrderType() == OP_BUY) {
            totalBuyLot += OrderLots();
        } else if (OrderType() == OP_SELL) {
            totalSelLot += OrderLots();
        }
    }
}

void hedging() {
}

void martingale() {

    if (OrdersTotal() == 0) {
        return;
    }

    OrderSelect(OrdersTotal() - 1, SELECT_BY_POS);
    double trueRangeInPip = martingaleGrid / Point;

    // if (OrdersTotal() == 5 && OrderProfit() < 0) {
    //     hedging();
    //     return;
    // }

    if (OrderProfit() > 0) {
        double closePrice = OrderType() == OP_BUY ? Bid : Ask;
        double diff = MathAbs(closePrice - OrderOpenPrice()) / Point;
        if (diff > trueRangeInPip + 20) {
            closeAllOpen();
        }
        return;
    }

    if (AccountEquity() <= balanceToDefend - maxAmountCanBeLoss) {
        closeAllOpen();
        return;
    }

    int orderType = OrderType();

    if (totalBuyLot > totalSelLot) {
        double diff = MathAbs(Ask - OrderOpenPrice()) / Point;
        if (diff > trueRangeInPip) {
            double lots = OrderLots() * hedgeMultiplier;
            ticketNumber = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy to hedge", 0, 0, Green);
            // OrderModify(ticketNumber, OrderOpenPrice(), 0, Ask + grid, 0, Red);
            hedgeMode = true;
        }
    } else if (totalBuyLot < totalSelLot){
        double diff = MathAbs(Bid - OrderOpenPrice()) / Point;
        if (diff > trueRangeInPip) {
            double lots = OrderLots() * hedgeMultiplier;
            ticketNumber = OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell to hedge", 0, 0, Green);
            // OrderModify(ticketNumber, OrderOpenPrice(), 0, Bid - grid, 0, Red);
            hedgeMode = true;
        }
    }

}

void openPosition() {
    if (OrdersTotal() > 0) {
        return;
    }

    balanceToDefend = AccountBalance();
    martingaleGrid = trueRange_D1_2;

    if (haPrevClose_H4 > haPrevOpen_H4
        && haPrevClose_H1 > haPrevOpen_H1
        && haClose_H1 > haOpen_H1
        && haPrevClose_M15 > haPrevOpen_M15
        && haClose_M15 > haOpen_M15
        && macdPrevBase_M15 > 0
        && macdPrevBase_M15 < macdBase_M15
        && Close[0] > Open[0]) {

        ticketNumber = OrderSend(NULL, OP_BUY, baseTradeLots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        OrderModify(ticketNumber, OrderOpenPrice(), 0, Ask + trueRange_D1, 0, Red);
        hedgeMode = false;
    }

    if (haPrevClose_H4 < haPrevOpen_H4
        && haPrevClose_H1 < haPrevOpen_H1
        && haClose_H1 < haOpen_H1
        && haPrevClose_M15 < haPrevOpen_M15
        && haClose_M15 < haOpen_M15
        && macdPrevBase_M15 < 0
        && macdPrevBase_M15 < macdBase_M15
        && Close[0] < Open[0]) {

        ticketNumber = OrderSend(NULL, OP_SELL, baseTradeLots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
        OrderModify(ticketNumber, OrderOpenPrice(), 0, Bid - trueRange_D1, 0, Red);
        hedgeMode = false;
    }
}

int OnInit() {
    computeIndicators();
    displayComment();
    return(INIT_SUCCEEDED);
}

void OnTick() {
    computeIndicators();
    displayComment();
    computeOpenLots();
    martingale();
    openPosition();
    displayComment();
}
