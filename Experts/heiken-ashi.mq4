#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

// H1 Indicators
double haOpen_M15,
   haClose_M15,
   haPrevOpen_M15,
   haPrevClose_M15,
   macdBase_M15,
   macdPrevBase_M15,
   close_M15,
   open_M15;

// H1 Indicators
double haOpen_H1,
   haClose_H1,
   haPrevOpen_H1,
   haPrevClose_H1,
   ema20_H1,
   adxMain_H1;

// H4 Indicators
double haPrevOpen_H4,
   haPrevClose_H4;

// D1 Indicators
double atr_D1,
    trueRange_D1;

double highest,
    highestBuffer,
    lowest,
    lowestBuffer,
    lastClose;

double balanceToDefend;
double tradeLots;
double previousTradeLots;
double lastCloseTime;

bool hedgeMode = false;

int ticketNumber;

input double baseTradeLots = 0.01;
input double hedgeMultiplier = 10;
input int adxMainTrigger = 25;
input int validHeikenshiBar = 50;
input int trailingStop = 10;

int OnInit() {
    computeIndicators();
    displayComment();
    balanceToDefend = AccountBalance();
    return(INIT_SUCCEEDED);
}

void OnTick() {
    computeIndicators();
    displayComment();
    // tailStop();
    closePosition();
    openPosition();
    // tailStop();
    displayComment();
}

void computeIndicators() {
    // M15 Indicators
    haOpen_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 2, 0);
    haClose_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 3, 0);
    haPrevOpen_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 2, 1);
    haPrevClose_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 3, 1);
    macdBase_M15 = iMACD(NULL, PERIOD_M15, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    macdPrevBase_M15 = iMACD(NULL, PERIOD_M15, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    close_M15 = iClose(NULL, PERIOD_M15, 0);
    open_M15 = iOpen(NULL, PERIOD_M15, 0);

    // H1 Indicators
    haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
    adxMain_H1 = iADX(NULL, PERIOD_H1, 8, PRICE_CLOSE, MODE_MAIN,  0);

    // H4 Indicators
    haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1);
    haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1);

    atr_D1 = iCustom(NULL, PERIOD_D1, "ATR", 2, 0, 1);
    trueRange_D1 = atr_D1 / 5;
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
        "\n",
        "\n    Master Trend: ", haPrevClose_H4 > haPrevOpen_H4 ? "UP" : "DOWN",
        "\n    Primary Trend: ", haPrevClose_H1 > haPrevOpen_H1 ? "UP" : "DOWN",
        "\n    EMA(20): ", Bid > ema20_H1 ? "UP" : "DOWN",
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

bool isValidForLongPosition() {
    return
        (haPrevClose_H1 - haPrevOpen_H1) / Point > validHeikenshiBar
        // && haPrevClose_H4 > haPrevOpen_H4
        && adxMain_H1 >= adxMainTrigger
        && haPrevClose_H1 > haPrevOpen_H1
        // && haClose_H1 > haOpen_H1
        && haPrevClose_M15 > haPrevOpen_M15
        && haClose_M15 > haOpen_M15
        // && macdPrevBase_M15 > 0
        && macdPrevBase_M15 < macdBase_M15
        && close_M15 > open_M15;
}

bool isValidForShortPosition() {
    return
        (haPrevOpen_H1 - haPrevClose_H1) / Point > validHeikenshiBar
        // && haPrevClose_H4 < haPrevOpen_H4
        && adxMain_H1 >= adxMainTrigger
        && haPrevClose_H1 < haPrevOpen_H1
        // && haClose_H1 < haOpen_H1
        && haPrevClose_M15 < haPrevOpen_M15
        && haClose_M15 < haOpen_M15
        // && macdPrevBase_M15 < 0
        && macdPrevBase_M15 < macdBase_M15
        && close_M15 < open_M15;
}

void openPosition() {
    if (OrdersTotal() > 0 || lastCloseTime == iTime(NULL, PERIOD_H1, 0)) {
        return;
    }

    if (balanceToDefend > AccountBalance()) {
        tradeLots = previousTradeLots * hedgeMultiplier;
    } else {
        tradeLots = baseTradeLots;
        balanceToDefend = AccountBalance();
    }

    if (isValidForLongPosition()) {
        ticketNumber = OrderSend(NULL, OP_BUY, tradeLots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        previousTradeLots = tradeLots;
    }

    if (isValidForShortPosition()) {
        ticketNumber = OrderSend(NULL, OP_SELL, tradeLots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
        previousTradeLots = tradeLots;
    }
}

void closePosition() {
    if (OrdersTotal() == 0) {
        return;
    }

    OrderSelect(0, SELECT_BY_POS);
    if (OrderType() == OP_BUY
        && !isValidForLongPosition()
        && MathAbs(OrderOpenPrice() - Bid) >= trueRange_D1) {
        OrderClose(ticketNumber, OrderLots(), Bid, 3, Red);
        lastCloseTime = iTime(NULL, PERIOD_H1, 0);
    }

    if (OrderType() == OP_SELL
        && !isValidForShortPosition()
        && MathAbs(OrderOpenPrice() - Ask) >= trueRange_D1) {
        OrderClose(ticketNumber, OrderLots(), Ask, 3, Red);
        lastCloseTime = iTime(NULL, PERIOD_H1, 0);
    }
}

void tailStop() {
    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

        if (OrderType() == OP_BUY) {
            if (Bid - OrderOpenPrice() > trailingStop * MarketInfo(NULL, MODE_POINT)) {
                if (OrderStopLoss() < Bid - trailingStop * MarketInfo(NULL, MODE_POINT)
                    || (OrderStopLoss() == 0)) {

                    OrderModify(OrderTicket(), OrderOpenPrice(), Bid - trailingStop * MarketInfo(NULL, MODE_POINT), OrderTakeProfit(), Red);
                }
            }
        } else if (OrderType() == OP_SELL) {
            if (OrderOpenPrice() - Ask > trailingStop * MarketInfo(NULL, MODE_POINT)) {
                if ((OrderStopLoss() > Ask + trailingStop * MarketInfo(NULL, MODE_POINT))
                     || (OrderStopLoss() == 0)) {

                    OrderModify(OrderTicket(), OrderOpenPrice(), Ask + trailingStop * MarketInfo(NULL, MODE_POINT), OrderTakeProfit(), Red);
                }
            }
        }
    }
}
