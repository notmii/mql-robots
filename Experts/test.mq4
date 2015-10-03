#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

input double inputPipTolerance = 5;
input double inputStopLoss = 100;
input double inputTakeProfit = 500;
input double lots = 0.03;

double pipTolerance = inputPipTolerance * Point;
double stopLoss = inputStopLoss / Point;
double takeProfit = inputTakeProfit / Point;

double previousOpenBarTime;
int orderTicket;

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
    double haOpen = iCustom(NULL, 0, "Heiken Ashi", 2, 0),
        haClose = iCustom(NULL, 0, "Heiken Ashi", 3, 0),
        openCloseDifference = MathAbs(haOpen - haClose);

    double haPrevOpen = iCustom(NULL, 0, "Heiken Ashi", 2, 1),
        haPrevClose = iCustom(NULL, 0, "Heiken Ashi", 3, 1);

    double emaValue = iMA(NULL, 0, 21, 0, MODE_EMA, PRICE_CLOSE, 0);

    // Try to open a position
    if (OrdersTotal() == 0) {
        // Buy if ff. condition is match
        // - graph changes is significant
        // - current candle bar is a bull candle
        // - previous candle bar is a bear candle
        if (openCloseDifference > pipTolerance &&
            haClose > haOpen &&
            haPrevClose < haPrevOpen &&
            haClose > emaValue) {

            orderTicket = OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        }
    } else {
        if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("Error selecting order", GetLastError());
        }

        if (OrderType() == OP_BUY) {
            if (haClose < haOpen) {
                if(!OrderClose(orderTicket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }
            }
        } else if (OrderType() == OP_SELL) {
        }
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
