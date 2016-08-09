#property copyright "notmii"
#property link      "https://github.com/notmii/mql-robots/blob/master/test.mq4"
#property version   "1.00"
#property strict

input double PERIOD = 48,
    BUFFER = 0.00100,
    BASE_LOTS = 0.01;

double lots = BASE_LOTS;

// H1 Indicators
double ma48high_H1,
    ma48high_prev_H1,
    ma48low_H1,
    ma48low_prev_H1;

double haOpen_H1,
    haClose_H1,
    haPrevOpen_H1,
    haPrevClose_H1;

double balanceBeforeOpen,
    highestBalance,
    highDiff,
    lowDiff,
    barOpen;

double success = 1,
    fail = 1;

void computeIndicators()
{
    // H1 Indicators
    haOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 0);
    haClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 0);
    haPrevOpen_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 2, 1);
    haPrevClose_H1 = iCustom(NULL, PERIOD_H1, "Heiken Ashi", 3, 1);
    // macdBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 0);
    // macdPrevBase_H1 = iMACD(NULL, PERIOD_H1, 6, 13, 5, PRICE_CLOSE, MODE_MAIN, 1);
    // avgTrueRange_H1 = iCustom(NULL, PERIOD_H1, "ATR", 20, 0, 1);
    // trueRange_H1 = avgTrueRange_H1 / 5;
    // ema20_H1 = iMA(NULL, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);

    ma48high_H1 = iMA(NULL, PERIOD_H1, PERIOD, 0, MODE_SMA, PRICE_HIGH, 0);
    ma48low_H1 = iMA(NULL, PERIOD_H1, PERIOD, 0, MODE_SMA, PRICE_LOW, 0);

    ma48high_prev_H1 = iMA(NULL, PERIOD_H1, PERIOD, 0, MODE_SMA, PRICE_HIGH, 1);
    ma48low_prev_H1 = iMA(NULL, PERIOD_H1, PERIOD, 0, MODE_SMA, PRICE_LOW, 1);

    highDiff = Close[0] - ma48high_H1;
    lowDiff =  ma48low_H1 - Close[0];

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
    double successPercent,
        failPercent,
        total;

    total = success + fail;

    successPercent = success == 0 ?
        0 : success / total;

    failPercent = fail == 0 ?
        0 : fail / total;

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
        "\n    Success: ", successPercent * 100 , "%",
        "\n    Fail: ", failPercent * 100 , "%",
        "\n",
        ""
    );
}

void openTrade()
{
    if (OrdersTotal() > 0 || barOpen == Bars) {
        return;
    }

    if (Close[0] > ma48high_H1 &&
        Low[1] < ma48high_prev_H1 &&
        haClose_H1 > haOpen_H1 &&
        highDiff < BUFFER) {
        Print("Buy position now!");
        highestBalance = highestBalance < AccountBalance() ?
            AccountBalance() : highestBalance;
        barOpen = Bars;
        OrderSend(NULL, OP_BUY, lots, Ask, 3, 0, 0, "Buy", 0, 0, Green);
    }

    if (OrdersTotal() > 0 || barOpen == Bars) {
        return;
    }

    /**
     * Open a short position when the ff. has been matched
     *  - price is below Low SMA
     *  - previous close is higher than Low SMA
     *  - heiken ashi is show a bear candle
     */
    if (Close[0] < ma48low_H1 &&
        High[1] > ma48low_prev_H1 &&
        haClose_H1 < haOpen_H1 &&
        lowDiff < BUFFER) {
        Print("Sell position now!");
        highestBalance = highestBalance < AccountBalance() ?
            AccountBalance() : highestBalance;
        barOpen = Bars;
        OrderSend(NULL, OP_SELL, lots, Bid, 3, 0, 0, "Sell", 0, 0, Green);
    }
}

void computeNextLot() {
    lots = OrderProfit() > 0 ? BASE_LOTS : lots * 2;
    lots = BASE_LOTS;
}

void dataScienceMistakes() {
    if (OrderProfit() <= 0) {
        fail++;
    }

    if (OrderProfit() > 0) {
        success++;
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
        // (Close[0] < ma48high_H1 && OrderProfit() > 0) ||
        if ((haClose_H1 < haOpen_H1 && OrderProfit() > 0) ||
            (Close[0] < ma48low_H1 && Bars != barOpen)) {
            computeNextLot();
            dataScienceMistakes();
            OrderClose(ticket, OrderLots(), Bid, 3, Red);
        }
    }

    if (orderType == OP_SELL) {
        // (Close[0] > ma48low_H1 && OrderProfit() > 0) ||
        if ((haClose_H1 > haOpen_H1 && OrderProfit() > 0) ||
            (Close[0] > ma48high_H1 && Bars != barOpen)) {
            computeNextLot();
            dataScienceMistakes();
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
