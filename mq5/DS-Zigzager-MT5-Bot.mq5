//+------------------------------------------------------------------+
//|                                          DS-Zigzager-MT5-Bot.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh";
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"

#include "CZigzagerPattern.mqh"
#include "CZigzagerBot.mqh"

input     group                    "2. ОСНОВНЫЕ НАСТРОЙКИ"
input     ulong                    gMagic                                = 20240527;                            // gMagic: Идентификатор ордеров
input     string                   gComment                              = "DSZZ_XAUUSD";                       // gComment: Дополнительный комментарий к ордерам
input     ENUM_TRADE_DIR           SetTypePos                            = TRADE_DIR_BUYSELL;                   // SetTypePos: Направление торговли
input     ENUM_TYPE_LOT            Type_lot                              = TYPE_LOT_FIXED;                      // Type_lot: Какой тип расчета лота?
input     double                   Lot                                   = 0.01;                                // Lot: Если лот фиксированный, то равен...
input     double                   Money_loss                            = 30.0;                                // Money_loss: Если лот динамичный, то допустимый убыток.... $

input     group                    "3а. НАСТРОЙКИ ZIGZAG"
input     ENUM_TIMEFRAME_CUSTOM    gTimeFrameZZ                          = TIMEFRAME_CUSTOM_H1;                 // gTimeFrameZZ: Рабочий таймфрейм ZigZag
input     uint                     gBarsBack                             = 20;                                  // gBarsBack: Сколько баров в истории нужно для ZigZag
input     uint                     ExtDepth                              = 12;                                  // ExtDepth: Фильтр резких колебаний, бар
          uint                     ExtDeviation                          = 5;                                   // ExtDeviation: ZZ ExtDeviation
input     uint                     ExtBackstep                           = 3;                                   // ExtBackstep: Мин.кол-во баров между экстремумами

input     group                    "3б. НАСТРОЙКИ MA и ParabolicSAR"
input     ENUM_TIMEFRAME_CUSTOM    gTimeFrameInd                         = TIMEFRAME_CUSTOM_M15;                // gTimeFrameInd: Рабочий таймфрейм индикаторов
input     ENUM_INDICATORS_LIST     SetIndicator                          = INDICATORS_LIST_MA;                  // SetIndicator: Выберите дополнительный индикатор
input     uint                     maPeriod                              = 15;                                  // maPeriod: Период Moving Average, если он выбран
input     double                   ParabolicStep                         = 0.02;                                // ParabolicStep: Шаг Parabolic SAR, если он выбран
input     double                   ParabolicMax                          = 0.2;                                 // ParabolicMax: Максимум Parabolic SAR, если он выбран

input     group                    "4. УПРАВЛЕНИЕ ОРДЕРАМИ"
input     bool                     gFlgOrdPendings                       = true;                                // NOT IMPL!!!: gFlgOrdPendings: Разрешить установку отложенных ордеров
input     bool                     gFlgOrdMarket                         = true;                                // NOT IMPL!!!: gFlgOrdMarket: Разрешить установку рыночных ордеров
input     ENUM_TP_TYPE             gTPmode                               = TP_TYPE_FIXED;                       // gTPmode: Использовать Тейкпрофит какого типа?
input     uint                     gTP                                   = 500;                                 // gTP: Если TP фиксированный, то сколько пунктов?
input     double                   gFiboTP                               = 1.5;                                 // gFiboTP: Если TP по Fibo, то на каком уровне?
input     int                      gOpenShift                            = 100;                                 // gOpenShift: На сколько пунктов от Hi | Low выставлять ордер?
input     uint                     gMaxStopLoss                          = 100;                                 // gMaxStopLoss: Максимальный стоп лосс, пункт
input     ENUM_RESTORED_SL         gFlgMASLinMoment                      = RESTORED_SL_START;                   // NOT IMPL!!!: gFlgMASLinMoment: SL восстановленных отложек выставлять где?
input     uint                     gLifeTime                             = 100;                                 // gLifeTime: Время жизни ордера в часах
input     bool                     Close_TPord_on_Time                   = false;                               // Close_TPord_on_Time: Закрывать профитные ордера в конце дня?
input     uint                     Hour_closing                          = 22;                                  // Hour_closing: Если закрывать, то в котором часу?

input     group                    "4а. БЕЗУБЫТОК И ТРЕЙЛИНГ"
input     ENUM_TSL_TYPE            trailingStop                          = TSL_TYPE_NONE;                       // trailingStop: Какой использовать трейлинг?
input     uint                     BBUSize                               = 125;                                 // BBUSize: Перенос SL в безубыток, если ордер в плюс на...пунктов
input     uint                     BBUSizePip                            = 25;                                  // BBUSizePip: Уровень безубытка, пункты
input     uint                     TrailingStep                          = 500;                                 // TrailingStep: Если трал ступенчатый, то с шагом...пунктов
input     uint                     iTralBars                             = 5;                                   // iTralBars: Если трал по цен.каналу, то сколько баров M1 берем?
input     uint                     DistanceSL                            = 150;                                 // DistanceSL: Какой отступ SL от границы канала? (пунктов)

input     group                    "5. ВТОРОСТЕПЕННЫЕ НАСТРОЙКИ"
input     bool                     IsDeletePending                       = false;                               // IsDeletePending: Удалять отложки в ночную паузу
input     string                   PauseTimeStart                        = "23:30";                             // PauseTimeStart: Время начала ночной паузы
input     string                   PauseTimeStop                         = "01:30";                             // PauseTimeStop: Время окончания ночной паузы
input     bool                     gFlgDrawZZ                            = true;                                // gFlgDrawZZ: Рисовать график ZigZag?
input     bool                     gFlgLinesHL                           = false;                               // NOT IMPL!!!: gFlgLinesHL: Рисовать линии High и Low?
input     bool                     gFlgLevelsHL                          = false;                               // NOT IMPL!!!: gFlgLevelsHL: Рисовать уровни сделок?
sinput    LogLevel                 InpLL                                 = LogLevel(INFO);                      // 11.LL: Log Level
sinput    bool                     InpShowComment                        = true;                                // Show on-chart comment
          string                   InpBP                                 = "DSZZ";
          uint                     InpCommentUpdateDelayMs               = 5*1000;                              // Update comment delay

CDKSymbolInfo                      sym;
CZigzagerBot                       bot;

void InitTrade(CDKTrade& _trade, const long _magic, const ulong _slippage) {
   _trade.SetExpertMagicNumber(_magic);
   _trade.SetMarginMode();
   _trade.SetTypeFillingBySymbol(Symbol());
   _trade.SetDeviationInPoints(_slippage);  
   _trade.SetLogger(bot.Logger);
   _trade.LogLevel(LOG_LEVEL_NO);
}

void InitLogger(DKLogger& _logger) {
  _logger.Name = InpBP;
  _logger.Level = InpLL;
  _logger.Format = "%name%:[%level%] %message%";
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
  MathSrand(GetTickCount());
  
  // Loggers init
  InitLogger(bot.Logger);

  // Проверим режим счета. Нужeн ОБЯЗАТЕЛЬНО ХЕДЖИНГОВЫЙ счет
  CAccountInfo acc;
  if(acc.MarginMode() != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
    bot.Logger.Error("Only hedging mode allowed", true);
    return(INIT_FAILED);
  }

  if(!sym.Name(Symbol())) {
    bot.Logger.Error(StringFormat("Symbol %s is not available", Symbol()), true);
    return(INIT_FAILED);
  }
  
  bot.Sym = sym;
  bot.Per = Period();
  InitTrade(bot.Trade, gMagic, 0);
  
  //input     group                    "2. ОСНОВНЫЕ НАСТРОЙКИ"
  bot.gMagic = gMagic;
  bot.gComment = gComment;
  bot.SetTypePos = SetTypePos;
  bot.Type_lot = Type_lot;
  bot.Lot = Lot;
  bot.Money_loss = Money_loss;
  
  //input     group                    "3а. НАЙСТРОЙКИ ZIGZAG"
  bot.gTimeFrameZZ = gTimeFrameZZ;
  bot.gBarsBack = gBarsBack;
  bot.ExtDepth = ExtDepth;
  bot.ExtDeviation = ExtDeviation;
  bot.ExtBackstep = ExtBackstep;
  
  //input     group                    "3б. НАЙСТРОЙКИ MA и ParabolicSAR"
  bot.gTimeFrameInd = gTimeFrameInd;
  bot.SetIndicator = SetIndicator;
  bot.maPeriod = maPeriod;
  bot.ParabolicStep = ParabolicStep;
  bot.ParabolicMax = ParabolicMax;
  
  //input     group                    "4. УПРАВЛЕНИЕ ОРДЕРАМИ"
  bot.gFlgOrdPendings = gFlgOrdPendings;
  bot.gFlgOrdMarket = gFlgOrdMarket;
  bot.gTPmode = gTPmode;
  bot.gTP = gTP;
  bot.gFiboTP = gFiboTP;
  bot.gOpenShift = gOpenShift;
  bot.gMaxStopLoss = gMaxStopLoss;
  bot.gFlgMASLinMoment = gFlgMASLinMoment;
  bot.gLifeTime = gLifeTime;
  bot.Close_TPord_on_Time = Close_TPord_on_Time;
  bot.Hour_closing = Hour_closing;
  
  //input     group                    "4а. Безубыток и трейлинг"
  bot.trailingStop = trailingStop;
  bot.BBUSize = BBUSize;
  bot.BBUSizePip = BBUSizePip;
  bot.TrailingStep = TrailingStep;
  bot.iTralBars = iTralBars;
  bot.DistanceSL = DistanceSL;
  
  //input     group                    "5. ВТОРОСТЕПЕННЫЕ НАСТРОЙКИ"
  bot.IsDeletePending = IsDeletePending;
  bot.PauseTimeStart = PauseTimeStart;
  bot.PauseTimeStop = PauseTimeStop;
  bot.gFlgDrawZZ = gFlgDrawZZ;
  bot.gFlgLinesHL = gFlgLinesHL;
  bot.gFlgLevelsHL = gFlgLevelsHL;
  bot.InpShowComment = InpShowComment;
  
  bot.ZigZagHandle = iCustom(Symbol(), EnumTimeframeCustomToDefault(bot.gTimeFrameZZ), "Examples\\ZigZag",
                             bot.ExtDepth, bot.ExtDeviation, bot.ExtBackstep);
  bot.MAHandle = iMA(Symbol(), EnumTimeframeCustomToDefault(bot.gTimeFrameInd), bot.maPeriod, 0, MODE_SMA, PRICE_CLOSE);
  bot.PSARHandle = iSAR(Symbol(), EnumTimeframeCustomToDefault(bot.gTimeFrameInd), bot.ParabolicStep, bot.ParabolicMax);
                             
  if (!bot.ZigZagHandle) {
    bot.Logger.Error("ZigZag indicator load error", true);
    return(INIT_FAILED);
  }
  if (!bot.MAHandle) {
    bot.Logger.Error("MA indicator load error", true);
    return(INIT_FAILED);
  }
  if (!bot.PSARHandle) {
    bot.Logger.Error("PSAR indicator load error", true);
    return(INIT_FAILED);
  }  
  
  bot.Init();

  EventSetMillisecondTimer(InpCommentUpdateDelayMs);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//--- destroy timer
   EventKillTimer();
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()  {
  bot.OnTick();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()  {
  bot.OnTimer();
}

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()  {
  bot.OnTrade();
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {

   
  }

