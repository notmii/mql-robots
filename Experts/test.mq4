#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

int tick = 0;
int pipTakeprofit = 30;
int pipStopLoss = -1000;
double lastFailingTrade;
double lots = 0.03;
string masterDirection = "";
string trendDirection = "";
int orderTotal;
bool hedgingMode = false;
bool allowToOpen = false;
bool allowToBuy = false;
bool allowToSell = false;
double lastBarClose;
double firstTradeBalance;

double openPrice;

int OnInit()
{
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    double haOpen_M1 = iCustom(NULL, PERIOD_M1, "Heiken Ashi", 2, 0),
        haClose_M1 = iCustom(NULL, PERIOD_M1, "Heiken Ashi", 3, 0),
        macdBase_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0),
        macdSignalLine_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0),
        macdPrevBase_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1),
        macdPrevSignalLine_M1 = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);

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
        ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);

    double haOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 0),
        haClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 0),
        haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1),
        haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1),
        avgTrueRange_H4 = iCustom(NULL, PERIOD_H4, "ATR", 20, 0, 1);

    double trueRange = (int)((avgTrueRange_H4 / 5) / Point);

    masterDirection = haPrevClose_H4 > haPrevOpen_H4 ?
        "Up" : "Down";

    trendDirection = haPrevClose_H1 > haPrevOpen_H1 ?
        "Up" : "Down";

    allowToOpen = OrdersTotal() >= 0 && OrdersTotal() < 5;
    allowToBuy = allowToOpen;
    allowToSell = allowToOpen;
    firstTradeBalance = OrdersTotal() == 1 ? AccountBalance() : firstTradeBalance;
    int pipDiff;

    if (allowToOpen && OrdersTotal() > 0) {
        OrderSelect(OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES);
        pipDiff= (int)((Bid - OrderOpenPrice()) / Point);
        allowToOpen = pipDiff > avgTrueRange_H4;
        allowToBuy = OrderType() == OP_SELL && pipDiff > trueRange;
        allowToSell = OrderType() == OP_BUY && pipDiff < (trueRange * -1);
    }

    Comment(
        "    Balance: ", NormalizeDouble(AccountBalance(), 5),
        "\n    Equity: ", NormalizeDouble(AccountEquity(), 5),
        "\n    Margin: ", AccountMargin(),
        "\n    Free Margin: ", NormalizeDouble(AccountFreeMargin(), 5),
        "\n    Leverage: ", AccountLeverage(),
        "\n    Master Direction: ", masterDirection,
        "\n    Trend Direction: ", trendDirection,
        "\n    ATR: ", (int)(avgTrueRange_H4 / Point), "    ", trueRange,
        "\n    Allowed To Open: ", allowToOpen,
        "\n    Total Order: ", OrdersTotal(),
        "\n    Open Price: ", openPrice,
        "\n    Pip Difference: ", pipDiff,
        "\n    First Trade Balance: ", firstTradeBalance,
        ""
    );

    if (allowToOpen) {

        /**
         * Long trade:
         * Step #1: When previous Heiken Ashi candle of H4 is green
         * Step #2: When current price is above EMA 20 of H1 and Heiken Ashi candle is green.
         * Step #3: .......
         */
        if (allowToBuy
            && (OrdersTotal() == 0 ? haPrevClose_H4 > haPrevOpen_H4 && Bid > ema20_H1: true)
            && haPrevClose_H1 > haPrevOpen_H1
            && haClose_M1 > haOpen_M1
            && macdPrevBase_M1 < macdPrevSignalLine_M1
            && macdPrevSignalLine_M1 < macdBase_M1) {

            OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy Test", 0, 0, Green);
        }

        if (allowToSell
            && (OrdersTotal() == 0 ? haPrevClose_H4 < haPrevOpen_H4 && Bid < ema20_H1: true)
            && haPrevClose_H1 < haPrevOpen_H1
            && haClose_M1 < haOpen_M1
            && macdPrevBase_M1 > macdPrevSignalLine_M1
            && macdPrevSignalLine_M1 > macdBase_M1) {

            OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell Test", 0, 0, Green);
        }

        hedgingMode = OrdersTotal() > 1;
    }

    bool closeAllTrade = AccountEquity() > firstTradeBalance && OrdersTotal() > 1;

    for(int i = OrdersTotal() - 1; i >= 0; i--) {

        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        int ticket = OrderTicket();
        openPrice = OrderOpenPrice();
        int pips = (int)((Bid - OrderOpenPrice()) / Point);

        if (OrderType() == OP_BUY) {
            // Take the money
            if ((haClose_M1 < haOpen_M1 && OrderProfit() > 0)
                || closeAllTrade) {

                if(!OrderClose(ticket, OrderLots(), Bid, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }

                lastBarClose = Time[0];
            }
        } else if (OrderType() == OP_SELL) {
            // Take the money
            if ((haClose_M1 > haOpen_M1 && OrderProfit() > 0)
                || closeAllTrade) {

                if(!OrderClose(ticket, OrderLots(), Ask, 3, Red)) {
                    Print("Error closing order", GetLastError());
                }

                lastBarClose = Time[0];
            }
        }

    }
}
