#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

input double inputPipTolerance = 20;
input double inputStopLoss = 100;
input double inputTakeProfit = 500;
input double lots = 0.03;

double pipTolerance = inputPipTolerance * Point;
double stopLoss;
double takeProfit = inputTakeProfit / Point;

double previousOpenBarTime;
double previousCloseBarTime;
int orderTicket;
double openMacdBase_H1;
double highestProfit = 0;
double perc5 = 0;

int OnInit()
{

    if (OrdersTotal() > 0) {
        orderTicket = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
    }

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    EventKillTimer();
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
        macdBase_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0),
        ema21_H1 = iMA(NULL, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE, 0);

    double haOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 0),
        haClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 0);

    double haOpen_D1 = iCustom(NULL, PERIOD_D1, "Heiken Ashi", 2, 0),
        haClose_D1 = iCustom(NULL, PERIOD_D1, "Heiken Ashi", 3, 0);

    double candleDifference = MathAbs(Low[0] - High[0]) / Point;

    stopLoss = AccountBalance() - AccountBalance() * 0.05;

    Comment(
        AccountBalance(), "\n",
        AccountEquity(), "\n",
        highestProfit, "/", perc5, "\n",
        stopLoss
    );

    // Try to open a position
    if (OrdersTotal() == 0) {

        if (previousCloseBarTime != Time[0]
            && haClose_D1 > haOpen_D1
            && haClose_H4 > haOpen_H4
            && haClose_H1 > haOpen_H1
            && haClose_M30 > haOpen_M30
            && haClose_M15 > haOpen_M15
            && haClose_M5 > haOpen_M5
            && haClose_M1 > haOpen_M1
            && macdBase_M15 > macdSignalLine_M15
            && macdBase_M1 > 0
            && macdBase_M1 > macdSignalLine_M1) {

            orderTicket = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);

            openMacdBase_H1 = macdBase_H1;

        }

        // if (previousCloseBarTime != Time[0] &&
        //     haClose_H4 < haOpen_H4 &&
        //     haClose_H1 < haOpen_H1 &&
        //     haClose_M30 < haOpen_M30 &&
        //     haClose_M15 < haOpen_M15 &&
        //     haClose_M5 < haOpen_M5 &&
        //     haClose_M1 < haOpen_M1 &&
        //     macdBase_M15 < macdSignalLine_M15) {

        //     orderTicket = OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
        // }

    } else {
        if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("Error selecting order", GetLastError());
            return;
        }

        if (OrderType() == OP_BUY) {

            double prevMacd_H1 = iMACD(NULL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
            double prevMacd_M15 = iMACD(NULL, PERIOD_M15, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
            double prevMacd_M30 = iMACD(NULL, PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);

            if (prevMacd_H1 <= macdBase_H1 && openMacdBase_H1 < macdBase_H1) {

                if (highestProfit < OrderProfit()) {
                    highestProfit = OrderProfit();
                    perc5 = highestProfit - (highestProfit * .05);
                }

            }

            if (//(OrderProfit() > 0 && haClose_H1 <= haOpen_H1) ||
                (OrderProfit() > 0 && prevMacd_M15 > macdBase_M15)
                // || (OrderProfit() >= 4 && haClose_M15 <= haOpen_M15)
                // || (OrderProfit() >= 8 && haClose_M5 <= haOpen_M5)
                // || (OrderProfit() >= 10 && haClose_M1 <= haOpen_M1)
                || (OrderProfit() > AccountBalance() - AccountBalance() * 0.10)
                || (openMacdBase_H1 < macdBase_H1 && haClose_H1 < haOpen_H1)
                || AccountEquity() <= stopLoss) {

                if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }

                highestProfit = 0;
                perc5 = 0;
                previousCloseBarTime = Time[0];
            }

            // double factor = 0;

            // factor += OrderProfit() > 0 ?
            //     0.05 : 0;

            // factor += OrderProfit() >= 1 ?
            //     0.1 : 0;

            // factor += OrderProfit() >= 2 ?
            //     0.15 : 0;

            // factor += OrderProfit() >= 7.5 ?
            //     0.25 : 0;

            // factor += OrderProfit() >= 15 ?
            //     0.5 : 0;

            // factor += OrderProfit() >= 22.5 ?
            //     0.75 : 0;

            // factor += OrderProfit() >= 30 ?
            //     1 : 0;

            // factor += OrderProfit() <= -2 ?
            //     0.1 : 0;

            // factor += OrderProfit() <= -5 ?
            //     0.25 : 0;

            // factor += OrderProfit() <= -10 ?
            //     0.5 : 0;

            // factor += OrderProfit() <= -20 ?
            //     1 : 0;

            // factor += haClose_H1 > haOpen_H1 ?
            //     -0.5 : 0.5;

            // factor += haClose_H1 <= haOpen_H1 ?
            //     0.25 : 0;

            // factor += haClose_M15 <= haOpen_M15 ?
            //     0.25 : 0;

            // factor += haClose_M5 <= haOpen_M5 ?
            //     0.25 : 0;

            // factor += haClose_M1 <= haOpen_M1 ?
            //     0.25 : 0;

            // factor += macdBase_H1 > macdSignalLine_H1 ?
            //     0.25 : 0;


            // if (factor >= 1) {
            //     if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
            //         Print("Error closing order", GetLastError());
            //     }

            //     previousCloseBarTime = Time[0];
            // }

        }

        // if (OrderType() == OP_SELL) {
        //     if ((OrderProfit() > 0 && haClose_H1 >= haOpen_H1)
        //         || (OrderProfit() >= 4 && haClose_M15 >= haOpen_M15)
        //         || (OrderProfit() >= 8 && haClose_M5 >= haOpen_M5)
        //         || (OrderProfit() >= 10 && haClose_M1 >= haOpen_M1)
        //         || OrderProfit() <= -20) {

        //         if(!OrderClose(orderTicket, OrderLots(), Ask, 3, Red)) {
        //             Print("Error closing order", GetLastError());
        //         }

        //         previousCloseBarTime = Time[0];
        //     }
        // }
    }

}

// void OnTimer()
// {
// }

double OnTester()
{
    double ret=0.0;
    return(ret);
}

void OnChartEvent(
        const int id,
        const long &lparam,
        const double &dparam,
        const string &sparam
        ) {
}


// UTILITY FUNCTIONS

bool isNewBar()
{
    return previousOpenBarTime == NULL || previousOpenBarTime < Time[0];
}
