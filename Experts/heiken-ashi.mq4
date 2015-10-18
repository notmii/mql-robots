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
    trueRange_D1;

double highest,
    highestBuffer,
    lowest,
    lowestBuffer,
    lastClose;

double tradeLots,
    baseTradeLots = 0.01;

double diff,
    lastCloseTime,
    balanceToDefend;
bool hedgeMode = false;

int ticketNumber;

void computeIndicators()
{
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
        ""
    );
}

void hedgePosition() {
    if (OrdersTotal() == 0 || OrdersTotal() == 2) {
        return;
    }

    OrderSelect(OrdersTotal() - 1, SELECT_BY_POS);
    ticketNumber = OrderTicket();

    if (AccountEquity() > balanceToDefend && balanceToDefend != NULL && hedgeMode) {
        Print("Close All");
        for (int index = 0; index < OrdersTotal(); index++) {
            OrderSelect(index, SELECT_BY_POS);
            ticketNumber = OrderTicket();
            double closePrice = OrderType() == OP_BUY ? Bid : Ask;
            OrderClose(ticketNumber, OrderLots(), closePrice, 3, Red);
        }
        return;
    }

    if (OrderProfit() > 0 || hedgeMode) {
        return;
    }

    double trueRangeInPip = ((avgTrueRange_D1 / 2) / Point);
    double hedgeMultiplier = 10;

    switch(OrderType()) {
        case OP_BUY:
            Print("Hedge Buy");
            if (MathAbs(Bid - OrderOpenPrice()) / Point > trueRangeInPip
                && haPrevClose_H1 < haPrevOpen_H1
                && haClose_H1 < haOpen_H1
                && haPrevClose_M15 < haPrevOpen_M15
                && haClose_M15 < haOpen_M15
                && macdPrevBase_M15 < 0
                && macdPrevBase_M15 < macdBase_M15
                && Close[0] < Open[0]) {

                ticketNumber = OrderSend(NULL, OP_SELL, baseTradeLots * hedgeMultiplier, Bid, 3, 0, 0, "Sell to hedge", 0, 0, Green);
                OrderModify(ticketNumber, OrderOpenPrice(), Bid + avgTrueRange_D1 * 3, Bid - trueRange_D1, 0, Red);
                balanceToDefend = AccountBalance();
                hedgeMode = true;
            }
            break;

        case OP_SELL:
            Print("Hedge Sell");
            if (MathAbs(Ask - OrderOpenPrice()) / Point > trueRangeInPip
                && haPrevClose_H1 > haPrevOpen_H1
                && haClose_H1 > haOpen_H1
                && haPrevClose_M15 > haPrevOpen_M15
                && haClose_M15 > haOpen_M15
                && macdPrevBase_M15 > 0
                && macdPrevBase_M15 < macdBase_M15
                && Close[0] > Open[0]) {

                ticketNumber = OrderSend(NULL, OP_BUY, baseTradeLots * hedgeMultiplier, Ask, 3, 0, 0, "Buy to hedge", 0, 0, Green);
                OrderModify(ticketNumber, OrderOpenPrice(), Ask - avgTrueRange_D1 * 3, Ask + trueRange_D1, 0, Red);
                balanceToDefend = AccountBalance();
                hedgeMode = true;
            }
            break;
    }

}

void closePositions() {
    for (int position = 0; position < OrdersTotal(); position++) {
        OrderSelect(position, SELECT_BY_POS);
        ticketNumber = OrderTicket();

        switch (OrderType()) {
            case OP_BUY:
                if (Close[0] < Open[0]
                    && OrderProfit() > 0) {

                    OrderClose(ticketNumber, OrderLots(), Bid, 3, Red);
                    lastCloseTime = Time[0];

                }
                break;

            case OP_SELL:
                if (Close[0] > Open[0]
                    && OrderProfit() > 0) {

                    OrderClose(ticketNumber, OrderLots(), Ask, 3, Red);
                    lastCloseTime = Time[0];

                }
                break;
        }
    }
}

void openPosition() {
    if (OrdersTotal() > 0 || lastCloseTime == Time[0]) {
        return;
    }

    if (haPrevClose_H4 > haPrevOpen_H4
        && haPrevClose_H1 > haPrevOpen_H1
        && haClose_H1 > haOpen_H1
        && haPrevClose_M15 > haPrevOpen_M15
        && haClose_M15 > haOpen_M15
        && macdPrevBase_M15 > 0
        && macdPrevBase_M15 < macdBase_M15
        && Close[0] > Open[0]) {

        ticketNumber = OrderSend(NULL, OP_BUY, baseTradeLots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        OrderModify(ticketNumber, OrderOpenPrice(), Ask - avgTrueRange_D1 * 3, Ask + trueRange_D1, 0, Red);
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
        OrderModify(ticketNumber, OrderOpenPrice(), Bid + avgTrueRange_D1 * 3, Bid - trueRange_D1, 0, Red);
        hedgeMode = false;
    }

}

int OnInit()
{
    computeIndicators();
    displayComment();
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    computeIndicators();
    displayComment();

    // closePositions();
    hedgePosition();
    openPosition();

    displayComment();
}
