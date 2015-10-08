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
double takeProfit;

double previousOpenBarTime;
double previousCloseBarTime;
int orderTicket;
double highestProfit = 0;
double perc5 = 0;
double openBarTime;
double openMacdBase_H1;
int tick;
int pips;
int checkpoint = 0;

int OnInit()
{

    if (OrdersTotal() > 0) {
        orderTicket = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
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

    Comment(
        "Balance: ", AccountBalance(),
        "\nEquity: ", AccountEquity(),
        "\nMargin: ", AccountMargin(),
        "\nPips: ", pips,
        "\nCheckpoint: ", checkpoint,
        "\nTake Profit: ", takeProfit,
        "\nStop Loss: ", stopLoss
    );

    if (OrdersTotal() == 0) {

        if (prevMacd_H1 < macdBase_H1
            && prevMacd_H1 < prevMacdSignalLine_H1
            && macdSignalLine_H1 < macdBase_H1) {

            orderTicket = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
            openMacdBase_H1 = macdBase_H1;
            openBarTime = Time[0];
            tick = 0;
        }

        // if (previousCloseBarTime != Time[0]
        //     && prevMacd_H1 > macdBase_H1
        //     && haPrevClose_H1 > haPrevOpen_H1
        //     && haClose_H1 > haOpen_H1) {

        //     orderTicket = OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);

        //     openMacdBase_H1 = macdBase_H1;
        //     openBarTime = Time[0];
        // }

    } else {

        if (tick <= 20) {
            return;
        }

        // if (openBarTime == Time[0]) {
        //     return;
        // }

        if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("Error selecting order", GetLastError());
            return;
        }

        // highestProfit = highestProfit < OrderProfit() ?
        //     OrderProfit() : highestProfit;
        // perc5 = highestProfit - highestProfit * 0.05;

        if (OrderType() == OP_BUY) {

            if (AccountEquity() <= stopLoss) {
                if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                previousCloseBarTime = Time[0];
                pips = 0;
                checkpoint = 0;
            }


            pips = (int)((Bid - OrderOpenPrice()) / Point);

            if (pips > checkpoint) {
                checkpoint = pips;
                return;
            }

            if ((pips >= 100 && OrderProfit() > 0) || OrderProfit() >= takeProfit) {
                if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
                previousCloseBarTime = Time[0];
                pips = 0;
                checkpoint = 0;
            }

            // if (AccountEquity() >= takeProfit || AccountEquity() <= stopLoss) {
            //     if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
            //         Print("Error closing order", GetLastError());
            //     }
            //     previousCloseBarTime = Time[0];
            //     return;
            // }

            // If still trending up.
            // if (prevMacd_H1 <= macdBase_H1 && openMacdBase_H1 < macdBase_H1) {

            //     // if (OrderProfit() <= perc5) {
            //     //     if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
            //     //         Print("Error closing order", GetLastError());
            //     //     }
            //     //     previousCloseBarTime = Time[0];
            //     //     return;
            //     // }

            //     return;
            // }

            // if (prevMacd_H1 > macdBase_H1) {
            //     if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
            //         Print("Error closing order", GetLastError());
            //     }
            //     previousCloseBarTime = Time[0];
            // }
        }

        // if (OrderType() == OP_SELL) {

        //     if (OrderProfit() >= takeProfit || OrderProfit() <= stopLoss) {
        //         if(!OrderClose(orderTicket, OrderLots(), Ask, 3, Red)) {
        //             Print("Error closing order", GetLastError());
        //         }
        //         previousCloseBarTime = Time[0];
        //         return;
        //     }

        //     // If still trending down
        //     if (prevMacd_H1 >= macdBase_H1 && openMacdBase_H1 > macdBase_H1) {
        //         if (OrderProfit() <= perc5) {
        //             if(!OrderClose(orderTicket, OrderLots(), Ask, 3, Red)) {
        //                 Print("Error closing order", GetLastError());
        //             }
        //             previousCloseBarTime = Time[0];
        //             return;
        //         }
        //         return;
        //     }

        //     if (prevMacd_H1 < macdBase_H1) {
        //         if(!OrderClose(orderTicket, OrderLots(), Ask, 3, Red)) {
        //             Print("Error closing order", GetLastError());
        //         }
        //         previousCloseBarTime = Time[0];
        //     }
        // }
    }

}
