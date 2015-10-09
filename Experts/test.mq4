#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

double stopLoss;
double takeProfit;

double previousOpenBarTime;
double previousCloseBarTime;
int longOrderTicket;
int shortOrderTicket;
int tick = 0;
int pipTakeprofit = 200;
int pipStopLoss = -1000;
double lots = 0.03;
string trendDirection = "";

int OnInit()
{

    if (OrdersTotal() > 0) {
        longOrderTicket = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
    }

    return(INIT_SUCCEEDED);
}

void OnTick()
{
    double haPrevOpen = iCustom(NULL, 0, "Heiken Ashi", 2, 1),
        haPrevClose = iCustom(NULL, 0, "Heiken Ashi", 3, 1),
        haPrevLow = iCustom(NULL, 0, "Heiken Ashi", 0, 1),
        haPrevHigh = iCustom(NULL, 0, "Heiken Ashi", 1, 1);

    double haOpen_M1 = iCustom(NULL, PERIOD_M1, "Heiken Ashi", 2, 0),
        haClose_M1 = iCustom(NULL, PERIOD_M1, "Heiken Ashi", 3, 0),
        macdBase_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);

    double haOpen_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 2, 0),
        haClose_M5 = iCustom(NULL, PERIOD_M5, "Heiken Ashi", 3, 0),
        macdBase_M5 = iMACD(NULL, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_M5 = iMACD(NULL, PERIOD_M5, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);

    double haOpen_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 2, 0),
        haClose_M15 = iCustom(NULL, PERIOD_M15, "Heiken Ashi", 3, 0),
        macdBase_M15 = iMACD(NULL, PERIOD_M15, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_M15 = iMACD(NULL, PERIOD_M15, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);

    double haOpen_M30 = iCustom(NULL, PERIOD_M30, "Heiken Ashi", 2, 0),
        haClose_M30 = iCustom(NULL, PERIOD_M30, "Heiken Ashi", 3, 0),
        macdBase_M30 = iMACD(NULL, PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_M30 = iMACD(NULL, PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);

    double haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0),
        haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0),
        haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1),
        haPrevClose_H1  = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1),
        haPrevLow_H1  = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 0, 1),
        haPrevHigh_H1  = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 1, 1);

    double macdBase_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0),
        prevMacd_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1),
        prev2Macd_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 2),
        prevMacdSignalLine_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1),
        ema21_H1 = iMA(NULL, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE, 0);

    double haOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 0),
        haClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 0);

    double haOpen_D1 = iCustom(NULL, PERIOD_D1, "Heiken Ashi", 2, 0),
        haClose_D1 = iCustom(NULL, PERIOD_D1, "Heiken Ashi", 3, 0);

    double candleDifference = MathAbs(Low[0] - High[0]) / Point;

    double prevMacd_M15 = iMACD(NULL, PERIOD_M15, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
    double prevMacd_M30 = iMACD(NULL, PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);

    stopLoss = AccountBalance() - AccountBalance() * 0.1;
    takeProfit = AccountBalance() + AccountBalance() * 0.1;
    tick++;
    trendDirection = haClose_H4 > haOpen_H4 ?
        "Up" : "Down";

    Comment(
        "    Balance: ", NormalizeDouble(AccountBalance(), 5),
        "\n    Equity: ", NormalizeDouble(AccountEquity(), 5),
        "\n    Margin: ", AccountMargin(),
        "\n    Free Margin: ", AccountFreeMargin(),
        "\n    Leverage: ", AccountLeverage(),
        "\n    Take Profit: ", NormalizeDouble(takeProfit, 5),
        "\n    Stop Loss: ", NormalizeDouble(stopLoss, 5),
        "\n    Trend Direction: ", trendDirection
    );

    if (tick <= 40) {
        return;
    } else {
        tick = 0;
    }

    if (shortOrderTicket == NULL || longOrderTicket == NULL) {

        if (previousCloseBarTime != Time[0]
            && haClose_H4 > haOpen_H4
            && longOrderTicket == NULL
            && prevMacd_H1 < macdBase_H1
            && prevMacd_H1 < prevMacdSignalLine_H1
            && macdSignalLine_H1 <= macdBase_H1) {

            longOrderTicket = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        }

        if (previousCloseBarTime != Time[0]
            && haClose_H4 < haOpen_H4
            && shortOrderTicket == NULL
            && prevMacd_H1 > macdBase_H1
            && prevMacd_H1 > prevMacdSignalLine_H1
            && macdSignalLine_H1 >= macdBase_H1) {

            shortOrderTicket = OrderSend(NULL, OP_SELL, lots, Bid, 2, 0, 0, "Sell Test", 0, 0, Green);
        }

    }

    int pips = 0;

    if (longOrderTicket != NULL) {
        OrderSelect(longOrderTicket, SELECT_BY_TICKET, MODE_TRADES);

        if (OrderType() == OP_BUY) {

            pips = (int)((Bid - OrderOpenPrice()) / Point);

            // Prevent loosing more money
            if (pips <= pipStopLoss || trendDirection == "Down") {
                if(!OrderClose(longOrderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                longOrderTicket = NULL;
            }

            // Take the money
            if (AccountEquity() >= takeProfit) {
                if(!OrderClose(longOrderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                longOrderTicket = NULL;
            }

            // Prevent premature take profit.

            // Take profit
            if (pips >= pipTakeprofit) {
                if(!OrderClose(longOrderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                longOrderTicket = NULL;
            }
        }
    }

    if (shortOrderTicket != NULL) {
        OrderSelect(shortOrderTicket, SELECT_BY_TICKET, MODE_TRADES);

        if (OrderType() == OP_SELL) {

            pips = (int)((OrderOpenPrice() - Ask) / Point);

            // Prevent loosing more money
            if (pips <= pipStopLoss || trendDirection == "Up") {
                if(!OrderClose(shortOrderTicket, OrderLots(), Ask, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                shortOrderTicket = NULL;
            }

            // Take the money
            if (AccountEquity() >= takeProfit) {
                if(!OrderClose(shortOrderTicket, OrderLots(), Ask, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                shortOrderTicket = NULL;
            }


            // Take profit
            if (pips >= pipTakeprofit) {
                if(!OrderClose(shortOrderTicket, OrderLots(), Ask, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                shortOrderTicket = NULL;
            }

        }
    }



}
