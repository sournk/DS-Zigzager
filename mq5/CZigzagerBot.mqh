//+------------------------------------------------------------------+
//|                                                 CZigzagerBot.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Arrays\ArrayDouble.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\TradingManager\CDKPositionInfo.mqh"
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLBE.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLStep.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLPriceChannel.mqh"
#include "Include\DKStdLib\NewBarDetector\DKNewBarDetector.mqh"

#include "CZigzagerPattern.mqh"

enum ENUM_TYPE_LOT {
  TYPE_LOT_FIXED          = 0, // Фиксированный
  TYPE_LOT_DYNAMIC        = 1  // Динамичный от убытка
};

enum ENUM_TIMEFRAME_CUSTOM {
  TIMEFRAME_CUSTOM_M5     = 5,     // M5
  TIMEFRAME_CUSTOM_M15    = 15,    // M15
  TIMEFRAME_CUSTOM_M30    = 30,    // M30
  TIMEFRAME_CUSTOM_H1     = 60,    // H1
  TIMEFRAME_CUSTOM_H4     = 4*60,  // H4
  TIMEFRAME_CUSTOM_D1     = 24*60  // D1
};

ENUM_TIMEFRAMES EnumTimeframeCustomToDefault(const ENUM_TIMEFRAME_CUSTOM _tf_custom) {
  if (_tf_custom == TIMEFRAME_CUSTOM_M5)  return PERIOD_M5;
  if (_tf_custom == TIMEFRAME_CUSTOM_M15) return PERIOD_M15;
  if (_tf_custom == TIMEFRAME_CUSTOM_M30) return PERIOD_M30;
  if (_tf_custom == TIMEFRAME_CUSTOM_H1)  return PERIOD_H1;
  if (_tf_custom == TIMEFRAME_CUSTOM_H4)  return PERIOD_H4;
  if (_tf_custom == TIMEFRAME_CUSTOM_D1)  return PERIOD_D1;
  
  return PERIOD_M5;
}

enum ENUM_INDICATORS_LIST {
  INDICATORS_LIST_PSAR     = 0, // Parabolic SAR
  INDICATORS_LIST_MA       = 1  // Moving Average
};

enum ENUM_TP_TYPE {
  TP_TYPE_FIXED            = 0, // Фиксированный TP
  TP_TYPE_FIBO             = 1  // TP по Fibo
};

enum ENUM_RESTORED_SL {
  RESTORED_SL_START        = 0, // На изначальном уровне
  RESTORED_SL_IND_LEVEL    = 1  // На текущем значении индикатора 
};

enum ENUM_TSL_TYPE {
  TSL_TYPE_NONE            = 0, // Никакой (отключен)
  TSL_TYPE_STEP            = 2, // Трейлинг ступенчатый
  TSL_TYPE_PRICE_CHANNEL   = 3, // Трейлинг по ценовому каналу
  TSL_TYPE_IND             = 4  // Трейлинг по индикаторам (MA и Fractals)
};

class CZigzagerBot {
protected:
  DKNewBarDetector         NewBarDetector;
  CZigzagerPattern         ZigZagPattern;
public:
  CDKSymbolInfo            Sym;
  ENUM_TIMEFRAMES          Per;
  DKLogger                 Logger;
  CDKTrade                 Trade;
  int                      ZigZagHandle;
  int                      MAHandle;
  int                      PSARHandle;
  
  // input     group                    "2. ОСНОВНЫЕ НАСТРОЙКИ"
  ulong                    gMagic;
  string                   gComment;
  ENUM_TRADE_DIR           SetTypePos;
  ENUM_TYPE_LOT            Type_lot;
  double                   Lot;
  double                   Money_loss;
  
  // input     group                    "3а. НАЙСТРОЙКИ ZIGZAG"
  ENUM_TIMEFRAME_CUSTOM    gTimeFrameZZ;
  uint                     gBarsBack;
  uint                     ExtDepth;
  uint                     ExtDeviation;
  uint                     ExtBackstep;
  
  //input     group                    "3б. НАЙСТРОЙКИ MA и ParabolicSAR"
  ENUM_TIMEFRAME_CUSTOM    gTimeFrameInd;
  ENUM_INDICATORS_LIST     SetIndicator;
  uint                     maPeriod;
  double                   ParabolicStep;
  double                   ParabolicMax;
  
  // input     group                    "4. УПРАВЛЕНИЕ ОРДЕРАМИ"
  bool                     gFlgOrdPendings;
  bool                     gFlgOrdMarket;
  ENUM_TP_TYPE             gTPmode;
  uint                     gTP;
  double                   gFiboTP;
  int                      gOpenShift;
  uint                     gMaxStopLoss;
  ENUM_RESTORED_SL         gFlgMASLinMoment;
  uint                     gLifeTime;
  bool                     Close_TPord_on_Time;
  uint                     Hour_closing;
  
  //input     group                    "4а. БЕЗУБЫТОК И ТРЕЙЛИНГ"
  ENUM_TSL_TYPE            trailingStop;
  uint                     BBUSize;
  uint                     BBUSizePip;
  uint                     TrailingStep;
  uint                     iTralBars;
  uint                     DistanceSL;
  
  //input     group                    "5. ВТОРОСТЕПЕННЫЕ НАСТРОЙКИ"
  bool                     IsDeletePending;
  string                   PauseTimeStart;
  string                   PauseTimeStop;
  bool                     gFlgDrawZZ;
  bool                     gFlgLinesHL;
  bool                     gFlgLevelsHL;    

  ulong                    OrderBuy;
  CDKBarTagZigZag          OrderBuyTag;
  ulong                    OrderSell;
  CDKBarTagZigZag          OrderSellTag;

  void                     CZigzagerBot::Init();
  void                     CZigzagerBot::ShowComment();
  
  int                      CZigzagerBot::GetDirSign(const ENUM_TRADE_DIR _dir) { return (_dir == TRADE_DIR_BUY) ? +1 : -1; }
  ENUM_TRADE_DIR           CZigzagerBot::GetOppositeDir(const ENUM_TRADE_DIR _dir) { return (_dir == TRADE_DIR_BUY) ? TRADE_DIR_SELL : TRADE_DIR_BUY; }
  
  double                   CZigzagerBot::GetSL(CDKBarTagZigZag& _tag, const double _price);
  double                   CZigzagerBot::GetTP(CDKBarTagZigZag& _tag, const double _price);
  ulong                    CZigzagerBot::OrderOpen(CDKBarTagZigZag& _tag);
  void                     CZigzagerBot::CheckAndCloseIrrelevantOrders();
  void                     CZigzagerBot::CheckAndOpenOrders();
  
  void                     CZigzagerBot::MovePosToBE(const ulong _pos_id);
  void                     CZigzagerBot::UpdateTSLStep(const ulong _pos_id);
  void                     CZigzagerBot::UpdateTSLPriceChannel(const ulong _pos_id);
  CDKTSLBase*              CZigzagerBot::CreateTSL(const ulong _pos_id);
  void                     CZigzagerBot::UpdateTSL(const ulong _pos_id);  
 
  // Event Handlers
  void                     CZigzagerBot::OnTick(void);
  void                     CZigzagerBot::OnTrade(void);
  void                     CZigzagerBot::OnTimer(void);
  
  void                     CZigzagerBot::CZigzagerBot(void);
  void                     CZigzagerBot::~CZigzagerBot(void);
};

//+------------------------------------------------------------------+
//| Update current grid status
//+------------------------------------------------------------------+
void CZigzagerBot::ShowComment() {
  if (MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return;

  string comment = StringFormat("%s\n",
                                TimeToString(TimeCurrent())
                                );
  
  Comment(comment);
}

//+------------------------------------------------------------------+
//| Init Bot
//+------------------------------------------------------------------+
void CZigzagerBot::Init() {
  OrderBuy = 0;
  OrderSell = 0;
  NewBarDetector.AddTimeFrame(Per);
  ZigZagPattern.Init(Sym.Name(), EnumTimeframeCustomToDefault(gTimeFrameZZ), gBarsBack, ZigZagHandle, Logger.Name);
  ZigZagPattern.SetLogger(Logger);
}

//+------------------------------------------------------------------+
//| Returns price for SL level
//+------------------------------------------------------------------+
double CZigzagerBot::GetSL(CDKBarTagZigZag& _tag, const double _price) {
  double val[];
  if (SetIndicator == INDICATORS_LIST_MA)
    if (!CopyBuffer(MAHandle, 0, 0, 1, val)) return 0.0;
    //if (!CopyBuffer(MAHandle, 0, _tag.GetTime(), 1, val)) return 0.0; // <-- Use this to set SL on Tag.Time indicator value insted TimeCurrent
    
  if (SetIndicator == INDICATORS_LIST_PSAR)    
    if (!CopyBuffer(PSARHandle, 0, 0, 1, val)) return 0.0;
    //if (!CopyBuffer(PSARHandle, 0, _tag.GetTime(), 1, val)) return 0.0; // <-- Use this to set SL on Tag.Time indicator value insted TimeCurrent
  
  // Check Max SL dist
  if (Sym.PriceToPoints(MathAbs(val[0]-_price)) > (int)gMaxStopLoss)
    return _price + (-1*GetDirSign(_tag.GetDir())) * Sym.PointsToPrice(gMaxStopLoss);
    
  return val[0];
}

//+------------------------------------------------------------------+
//| Returns TP price
//+------------------------------------------------------------------+
double CZigzagerBot::GetTP(CDKBarTagZigZag& _tag, const double _price) {
  if (gTPmode == TP_TYPE_FIXED)
    return _price + GetDirSign(_tag.GetDir()) * Sym.PointsToPrice(gTP);
    
  if (gTPmode == TP_TYPE_FIBO) {
    CDKBarTagZigZag tag1;
    if (!ZigZagPattern.GetLastLevel(GetOppositeDir(_tag.GetDir()), tag1, 0.0, 0.0, _tag.GetTime()))
      return 0.0;
      
    double zz_dist = MathAbs(tag1.GetValue() - _tag.GetValue())*gFiboTP;
    return _price + GetDirSign(_tag.GetDir()) * zz_dist;
  }
    
  return 0.0;
}

//+------------------------------------------------------------------+
//| Open one order
//+------------------------------------------------------------------+
ulong CZigzagerBot::OrderOpen(CDKBarTagZigZag& _tag) {
  double lot = NormalizeLotFilterMinMax(Sym.Name(), 0.01);
  double price_open = _tag.GetValue() + GetDirSign(_tag.GetDir()) * Sym.PointsToPrice(gOpenShift);
  double sl = GetSL(_tag, price_open);
  double tp = GetTP(_tag, price_open);
  datetime exp_dt = TimeCurrent() + gLifeTime*60*60;
  string comment = StringFormat("%s|%s|%s", Logger.Name, TimeToString(_tag.GetTime()), gComment);
  if (lot <= 0.0 || sl <= 0.0 || tp <= 0.0) return 0;
  
  ulong res = Trade.OrderOpen(Sym.Name(), (_tag.GetDir() == TRADE_DIR_BUY) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP, 
                              lot, 0, price_open, sl, tp, ORDER_TIME_SPECIFIED, exp_dt, comment);
                              
  Logger.Assert(res, 
                StringFormat("%s/%d: ID=%I64u; LEV=%s", __FUNCTION__, __LINE__, res, _tag.__repr__()), INFO,
                StringFormat("%s/%d: Order open failed: LEV=%s", __FUNCTION__, __LINE__, _tag.__repr__()), ERROR);
                
  return res;
}

//+------------------------------------------------------------------+
//| Close orders if new zigzag extremes appear
//+------------------------------------------------------------------+
void CZigzagerBot::CheckAndCloseIrrelevantOrders() {
  if (!Sym.RefreshRates()) return;
  double price_curr = Sym.Bid(); // ZigZag indicator calced by Bid, so use this price for level detection as for BUY and as for SELL
  if (price_curr <= 0) return;
  
  CDKBarTagZigZag level;
  if (OrderBuy > 0) 
    if (ZigZagPattern.GetLastLevel(TRADE_DIR_BUY, level, price_curr, 0)) 
      if (level.GetTime() > OrderBuyTag.GetTime())
        if (Trade.OrderDelete(OrderBuy))
          OrderBuy = 0;
          
  if (OrderSell > 0) 
    if (ZigZagPattern.GetLastLevel(TRADE_DIR_SELL, level, 0, price_curr)) 
      if (level.GetTime() > OrderSellTag.GetTime())
        if (Trade.OrderDelete(OrderSell))
          OrderSell = 0;        
}

//+------------------------------------------------------------------+
//| Check if there's no order -> open order
//+------------------------------------------------------------------+
void CZigzagerBot::CheckAndOpenOrders() {
  if (!Sym.RefreshRates()) return;
  double price_curr = Sym.Bid(); // ZigZag indicator calced by Bid, so use this price for level detection as for BUY and as for SELL
  if (price_curr <= 0) return;
    
  CDKBarTagZigZag level;
  if ((SetTypePos == TRADE_DIR_BUY || SetTypePos == TRADE_DIR_BUYSELL) && OrderBuy == 0) 
    if (ZigZagPattern.GetLastLevel(TRADE_DIR_BUY, level, price_curr, 0)) {
      OrderBuy = OrderOpen(level);
      if (OrderBuy > 0) OrderBuyTag = level;
    }

  if ((SetTypePos == TRADE_DIR_SELL || SetTypePos == TRADE_DIR_BUYSELL) && OrderSell == 0) 
    if (ZigZagPattern.GetLastLevel(TRADE_DIR_SELL, level, 0, price_curr)) {
      OrderSell = OrderOpen(level);
      if (OrderSell > 0) OrderSellTag = level;
    }
}

//+------------------------------------------------------------------+
//| Serves BE
//+------------------------------------------------------------------+
void CZigzagerBot::MovePosToBE(const ulong _pos_id) {
  if (BBUSize <= 0) return;

  CDKTSLBE pos;
  if (!pos.SelectByTicket(_pos_id)) return; // No pos found

  double sl_old = pos.StopLoss();
  pos.Init(BBUSize, BBUSizePip);
  bool res = pos.Update(Trade, false);
  pos.SelectByTicket(_pos_id);
  double sl_new = pos.StopLoss();
  
  if (!res) 
    Logger.Assert(pos.ResultRetcode() >= ERR_USER_ERROR_FIRST,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), DEBUG,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), ERROR);
  else
    Logger.Info(StringFormat("%s/%d: T=%I64u; RET_CODE=DONE; SL=%f->%f", __FUNCTION__, __LINE__, _pos_id, sl_old, sl_new));
}

//+------------------------------------------------------------------+
//| Serves TSL object of specific type
//+------------------------------------------------------------------+
CDKTSLBase* CZigzagerBot::CreateTSL(const ulong _pos_id) {
  if (trailingStop == TSL_TYPE_STEP) {
    CDKTSLStep* tsl = new CDKTSLStep();
    if (!tsl.SelectByTicket(_pos_id)) {
      delete tsl;
      return NULL; 
    }    
    tsl.Init(BBUSize+BBUSizePip, TrailingStep);
    return tsl;
  }
  if (trailingStop == TSL_TYPE_PRICE_CHANNEL) {
    CDKTSLPriceChannel* tsl = new CDKTSLPriceChannel();
    if (!tsl.SelectByTicket(_pos_id)) {
      delete tsl;
      return NULL; 
    }        
    tsl.Init(BBUSize, PERIOD_M1, 0, iTralBars, CHANNEL_BORDER_WICK, DistanceSL);
    return tsl;
  }

  return NULL;
}

//+------------------------------------------------------------------+
//| Serves TSL
//+------------------------------------------------------------------+
void CZigzagerBot::UpdateTSL(const ulong _pos_id) {
  if (trailingStop == TSL_TYPE_NONE) return;
  if (BBUSize <= 0) return;

  CDKTSLBase* tsl = CreateTSL(_pos_id);
  if (tsl == NULL) return;
    
  double sl_old = tsl.StopLoss();
  bool res = tsl.Update(Trade, false);
  double sl_new = tsl.LastStopLoss();
  
  if (!res) 
    Logger.Assert(tsl.ResultRetcode() >= ERR_USER_ERROR_FIRST,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
                               _pos_id, tsl.ResultRetcode(), tsl.ResultRetcodeDescription()), DEBUG,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
                               _pos_id, tsl.ResultRetcode(), tsl.ResultRetcodeDescription()), ERROR);
  else
    Logger.Info(StringFormat("%s/%d: T=%I64u; RET_CODE=DONE; SL=%f->%f", __FUNCTION__, __LINE__, _pos_id, sl_old, sl_new));
    
  delete tsl;    
}


//+------------------------------------------------------------------+
//| OnTick Handler
//+------------------------------------------------------------------+
void CZigzagerBot::OnTick(void) {
  // BE
  MovePosToBE(OrderBuy);
  MovePosToBE(OrderSell);
  
  // TSL
  UpdateTSL(OrderBuy);
  UpdateTSL(OrderSell);

  if (!NewBarDetector.CheckNewBarAvaliable(Per)) return;
  Logger.Debug(StringFormat("New bar detected: TF=%s", TimeframeToString(Per)));
  
  ZigZagPattern.UpdateZigZag(); // Get new ZZ values
  CheckAndCloseIrrelevantOrders(); // Delete orders for old ZZ values
  CheckAndOpenOrders(); // Open new orders
  
  ZigZagPattern.Draw();
  ShowComment();
  
//  CDKBarTagZigZag last, high, low;
//  ZigZagPattern.GetLastLevel(TRADE_DIR_BUYSELL, last);
//  ZigZagPattern.GetLastLevel(TRADE_DIR_BUY, high);
//  ZigZagPattern.GetLastLevel(TRADE_DIR_SELL, low);
//  
//  Logger.Debug(StringFormat("Last ZZ: %s", last.__repr__(true)));
//  Logger.Debug(StringFormat("High ZZ: %s", high.__repr__(true)));
//  Logger.Debug(StringFormat("Low ZZ: %s", low.__repr__(true)));
  
}

//+------------------------------------------------------------------+
//| OnTrade Handler
//+------------------------------------------------------------------+
void CZigzagerBot::OnTrade(void) {
  CDKPositionInfo pos;
  COrderInfo order;
  if (OrderBuy && !order.Select(OrderBuy) && !pos.SelectByTicket(OrderBuy)) OrderBuy = 0;
  if (OrderSell && !order.Select(OrderSell) && !pos.SelectByTicket(OrderSell)) OrderSell = 0;
}

//+------------------------------------------------------------------+
//| OnTimer Handler
//+------------------------------------------------------------------+
void CZigzagerBot::OnTimer(void) {
  ShowComment();
}

//+------------------------------------------------------------------+
//| Constructor
//+------------------------------------------------------------------+
void CZigzagerBot::CZigzagerBot(void) {
}

//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
void CZigzagerBot::~CZigzagerBot(void) {
}