#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

double baseLots = 0.01,
    lots = baseLots;

// H1 Indicators
double ma48high_H1,
    ma48high_prev_H1,
    ma48low_H1,
    ma48low_prev_H1;

double balanceBeforeOpen,
    highestBalance;

void computeIndicators()
{
    // H1 Indicators
    // haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    // haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    // haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    // haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    // macdBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    // macdPrevBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    // avgTrueRange_H1 = iCustom(NULL, PERIOD_H1, "ATR", 20, 0, 1);
    // trueRange_H1 = avgTrueRange_H1 / 5;
    // ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);

    ma48high_H1 = iMA(NULL, PERIOD_H1, 48, 0, MODE_EMA, PRICE_HIGH, 0);
    ma48low_H1 = iMA(NULL, PERIOD_H1, 48, 0, MODE_EMA, PRICE_LOW, 0);

    ma48high_prev_H1 = iMA(NULL, PERIOD_H1, 48, 0, MODE_EMA, PRICE_HIGH, 1);
    ma48low_prev_H1 = iMA(NULL, PERIOD_H1, 48, 0, MODE_EMA, PRICE_LOW, 1);

    // H4 Indicators
    // haPrevOpen_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 2, 1);
    // haPrevClose_H4 = iCustom(NULL, PERIOD_H4, "Heiken Ashi", 3, 1);
    // avgTrueRange_H4 = iCustom(NULL, PERIOD_H4, "ATR", 20, 0, 1);
    // trueRange_H4 = avgTrueRange_H4 / 5;

    // avgTrueRange_D1 = iCustom(NULL, PERIOD_D1, "ATR", 20, 0, 1);
    // trueRange_D1 = avgTrueRange_D1 / 5;
}

void displayValues()
{
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
        "\n    Lots: ", lots,
        "\n    H.Balance: ", highestBalance,
        "\n",
        ""
    );
}

void openTrade()
{
    if (OrdersTotal() > 0) {
        return;
    }

    if (Close[0] > ma48high_H1 &&
        Close[1] > ma48high_prev_H1) {
        Print("Buy position now!");
        // SendNotification("Buy position now!");
        // PlaySound("expert.wav");
        highestBalance = highestBalance < AccountBalance() ?
            AccountBalance() : highestBalance;
        OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy", 0, 0, Green);
    }

    if (OrdersTotal() > 0) {
        return;
    }

    if (Close[0] < ma48low_H1 &&
        Close[1] < ma48low_prev_H1) {
        Print("Sell position now!");
        // SendNotification("Sell position now!");
        // PlaySound("expert.wav");
        highestBalance = highestBalance < AccountBalance() ?
            AccountBalance() : highestBalance;
        OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell", 0, 0, Green);
    }
}

void computeNextLot()
{
    if (OrderProfit() > 0 && highestBalance < AccountEquity()) {
        lots = baseLots;
    }

    if (OrderProfit() < 0) {
        lots *= 2;
    }
}

void closeTrade()
{
    if (OrdersTotal() <= 0) {
        return;
    }

    if (!OrderSelect(0, SELECT_BY_POS)) {
        return;
    }

    int orderType = OrderType(),
        ticket = OrderTicket();

    if (orderType == OP_BUY) {
        if ((Close[0] < ma48high_H1 && OrderProfit() > 0) ||
            Close[0] < ma48low_H1) {
            computeNextLot();
            OrderClose(ticket, OrderLots(), Bid, 3, Red);
        }
    }

    if (orderType == OP_SELL) {
        if ((Close[0] > ma48low_H1 && OrderProfit() > 0) ||
            Close[0] > ma48high_H1) {
            computeNextLot();
            OrderClose(ticket, OrderLots(), Ask, 3, Red);
        }
    }
}

int OnInit()
{
    computeIndicators();
    highestBalance = AccountBalance();
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    computeIndicators();
    displayValues();
    openTrade();
    closeTrade();
}
