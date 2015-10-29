#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

// M15 Indicators
double haOpen_M5,
   haClose_M5,
   haPrevOpen_M5,
   haPrevClose_M5,
   macdBase_M5,
   macdPrevBase_M5,
   close_M5,
   open_M5;

// H1 Indicators
double close_H1,
   haOpen_H1,
   haClose_H1,
   haPrevOpen_H1,
   haPrevClose_H1,
   ema20_H1,
   adxMain_H1,
   adxPlus_H1,
   adxMinus_H1;

// H4 Indicators
double haPrevOpen_H4,
   haPrevClose_H4,
   atr_H4;

double balanceToDefend,
    balanceBeforeOpen,
    previousOrderedLot;


double tradeLots;
double _takeProfit;
input double baseTradeLots = 0.01;
input double takeProfit = 200;
input double adxStrength = 30;
input double maxLost = 50;

int OnInit() {
    computeIndicators();
    displayComment();
    balanceToDefend = AccountBalance();
    _takeProfit = takeProfit * Point;
    return(INIT_SUCCEEDED);
}

void OnTick() {
    computeIndicators();
    displayComment();
    closePosition();
    openPosition();
    displayComment();
}

void computeIndicators() {
    // M15 Indicators
    haOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 0);
    haClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 0);
    haPrevOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 1);
    haPrevClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 1);
    macdBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    macdPrevBase_M5 = iMACD(NULL, PERIOD_M5, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    close_M5 = iClose(NULL, PERIOD_M5, 0);
    open_M5 = iOpen(NULL, PERIOD_M5, 0);

    // H1 Indicators
    close_H1 = iClose(NULL, PERIOD_H1, 0);
    haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
    adxMain_H1 = iADX(NULL, PERIOD_H1, 6, PRICE_CLOSE, MODE_MAIN, 0);
    adxPlus_H1 = iADX(NULL, PERIOD_H1, 6, PRICE_CLOSE, MODE_PLUSDI, 0);
    adxMinus_H1 = iADX(NULL, PERIOD_H1, 6, PRICE_CLOSE, MODE_MINUSDI, 0);

    // H4 Indicators
    haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1);
    haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1);
    atr_H4 = iATR(NULL, PERIOD_H4, 2, 0);
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
        "\n    EMA(20): ", close_H1 > ema20_H1 ? "UP" : "DOWN",
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

void closePosition() {
    if (OrdersTotal() == 0) {
        return;
    }

    OrderSelect(0, SELECT_BY_POS);

    if (AccountBalance() - AccountEquity() > maxLost) {
        closeAllOpen();
        return;
    }

    if (OrderType() == OP_BUY
        && adxPlus_H1 + 5 < adxMinus_H1) {
        closeAllOpen();
    }

    if (OrderType() == OP_SELL
        && adxMinus_H1 + 5 < adxPlus_H1) {
        closeAllOpen();
    }
}

void openPosition() {
    if (OrdersTotal() > 0) {
        return;
    }

    int ticketNumber;
    double lots = AccountBalance() < balanceBeforeOpen ?
        previousOrderedLot * .5 : baseTradeLots;

    if (AccountBalance() > balanceToDefend) {
        balanceToDefend = AccountBalance();
        lots = baseTradeLots * 1.5;
    }

    if (haPrevClose_H4 > haPrevOpen_H4
        && haPrevClose_H1 > haPrevOpen_H1
        && haClose_H1 > haOpen_H1
        && close_H1 > ema20_H1
        && adxMain_H1 >= adxStrength
        && adxPlus_H1 > adxMinus_H1 + 5
        && haPrevClose_M5 > haPrevOpen_M5
        && haClose_M5 > haOpen_M5
        && macdPrevBase_M5 > 0
        && macdPrevBase_M5 < macdBase_M5
        && close_M5 > open_M5) {

        balanceBeforeOpen = AccountBalance();
        ticketNumber = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        OrderModify(ticketNumber, OrderOpenPrice(), 0, Bid + _takeProfit, 0, Red);
        previousOrderedLot = lots;
    }

    if (haPrevClose_H4 < haPrevOpen_H4
        && haPrevClose_H1 < haPrevOpen_H1
        && haClose_H1 < haOpen_H1
        && close_H1 < ema20_H1
        && adxMain_H1 >= adxStrength
        && adxMinus_H1 > adxPlus_H1 + 5
        && haPrevClose_M5 < haPrevOpen_M5
        && haClose_M5 < haOpen_M5
        && macdPrevBase_M5 < 0
        && macdPrevBase_M5 < macdBase_M5
        && Close[0] < Open[0]) {

        balanceBeforeOpen = AccountBalance();
        ticketNumber = OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
        OrderModify(ticketNumber, OrderOpenPrice(), 0, Ask - _takeProfit, 0, Red);
        previousOrderedLot = lots;
    }
}

