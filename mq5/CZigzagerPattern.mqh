//+------------------------------------------------------------------+
//|                                                    CZigzager.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayLong.mqh>
#include "Include\DKStdLib\Common\CDKBarTag.mqh";
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\Drawing\DKChartDraw.mqh"

enum ENUM_TRADE_DIR {
  TRADE_DIR_BUY     = 1, // Только BUY
  TRADE_DIR_SELL    = 2, // Только SELL
  TRADE_DIR_BUYSELL = 3 // BUY + SELL
};

class CDKBarTagZigZag : public CDKBarTag {
protected:
  DKLogger                 Logger;
  
  ENUM_TRADE_DIR           Dir;

public:
  datetime                 TimeDetect;
  double                   TP;
  double                   SL;
  
  void                     SetDir(const ENUM_TRADE_DIR _dir) { Dir = _dir; };
  ENUM_TRADE_DIR           GetDir() { return Dir; };
  
  string                   __repr__() { return StringFormat("%s:%s", (Dir == TRADE_DIR_BUY) ? "H" : "L", TimeToString(GetTime())); };
};

class CZigzagerPattern {
protected:
  string                   Prefix;
  string                   Sym;
  ENUM_TIMEFRAMES          TF;
  int                      Handle;
  int                      Depth;
  
  CArrayObj                ZigZagExtremes;
  CArrayLong               DisabledBarDT;
  
  DKLogger                 Logger;
  
  bool                     CZigzagerPattern::IsBarDTDisabled(const datetime _dt);
public:
  bool                     DrawEnable;
  
  void                     CZigzagerPattern::Init(const string _sym, const ENUM_TIMEFRAMES _tf, const int _depth, const int _handle, const string _prefix);
  void                     CZigzagerPattern::SetLogger(DKLogger& _logger) { Logger = _logger; };
  
  void                     CZigzagerPattern::AddBarToFilter(const datetime _dt);
  
  int                      CZigzagerPattern::UpdateZigZag();
  bool                     CZigzagerPattern::GetLastLevel(const ENUM_TRADE_DIR _dir, 
                                                          CDKBarTagZigZag& _tag, 
                                                          const double _gt=0.0, const double _lt=0.0,
                                                          const datetime _before_dt = 0,
                                                          const bool _apply_filter = false);
  
  void                     CZigzagerPattern::Draw();
  void                     CZigzagerPattern::DrawTagOpen(CDKBarTagZigZag& _tag);
  void                     CZigzagerPattern::DrawTagClose(CDKBarTagZigZag& _tag);
  
  //void                     CZigzagerPattern::CZigzagerPattern(void);
  //void                     CZigzagerPattern::~CZigzagerPattern(void);  
};

bool CZigzagerPattern::IsBarDTDisabled(const datetime _dt) {
  for (int i=0; i<DisabledBarDT.Total(); i++)
    if (DisabledBarDT.At(i) == _dt)
      return true;
      
  return false;
}

void CZigzagerPattern::Init(const string _sym, const ENUM_TIMEFRAMES _tf, const int _depth, const int _handle, const string _prefix) {
  Prefix = _prefix;
  Sym = _sym;
  TF = _tf;
  Depth = _depth;
  Handle = _handle;
  
  ZigZagExtremes.Clear();
  DisabledBarDT.Clear();
  
  DrawEnable = true;
}

void CZigzagerPattern::AddBarToFilter(const datetime _dt) {
  DisabledBarDT.Add(_dt);
}

//+------------------------------------------------------------------+
//| Updated ZigZag BarTags
//+------------------------------------------------------------------+
int CZigzagerPattern::UpdateZigZag() {
  ZigZagExtremes.Clear();
  
  int shift_start = 0;
  bool skip_last_extreme = true;
  double val[];
  CopyBuffer(Handle, 0, shift_start, Depth, val);

  datetime detected_dt = TimeCurrent();
  for (int i=ArraySize(val)-1; i>=0; i--) {
    if (val[i] <= 0.0) continue;
    CDKBarTagZigZag* tag = new CDKBarTagZigZag;
    tag.Init(Sym, TF, ArraySize(val)-1-i+shift_start, val[i]);
    tag.TimeDetect = detected_dt;
    ZigZagExtremes.Add(tag);     
  }
  
  // Delete last extreme if needed
  if (skip_last_extreme && ZigZagExtremes.Total() > 0) ZigZagExtremes.Delete(0);
  
  // Min 2 ZZ extremes needed to figure out HIGH or LOW type of them
  if (ZigZagExtremes.Total() < 2) { ZigZagExtremes.Clear(); return 0; }

  // Determinate types
  CDKBarTagZigZag* tag_prev = ZigZagExtremes.At(0);
  for (int i=0; i<ZigZagExtremes.Total()-1; i++) {
    CDKBarTagZigZag* tag_curr = ZigZagExtremes.At(i); 
    CDKBarTagZigZag* tag_next = ZigZagExtremes.At(i+1); 
    ENUM_TRADE_DIR dir = (tag_curr.GetValue() > tag_next.GetValue() ? TRADE_DIR_BUY : TRADE_DIR_SELL); 
    tag_curr.SetDir(dir);    
    tag_next.SetDir((tag_curr.GetDir() == TRADE_DIR_BUY) ? TRADE_DIR_SELL : TRADE_DIR_BUY);
  } 
  
  
  // Delete tags with same dir in a row
  // Sometimes ZigZag has extremes without dir change
  //
  //        *  <- BUY
  //       / \
  //      * <- SELL WRONG EXTREME
  //     /
  //    * <- SELL WRONG EXTREME  
  // \ /
  //  * <- SELL  
      
  CDKBarTagZigZag* tag = ZigZagExtremes.At(0); 
  ENUM_TRADE_DIR dir = tag.GetDir(); 
  int i = 1;
  while (i<ZigZagExtremes.Total()) {
    CDKBarTagZigZag* tag = ZigZagExtremes.At(i); 
    if (dir == tag.GetDir()) {
      ZigZagExtremes.Delete(i);
      continue;
    }
    
    dir = tag.GetDir(); 
    i++;
  }

  return ZigZagExtremes.Total();
}

//+------------------------------------------------------------------+
//| Return last CBarTag of ZigZag
//|   - _dir can be used to filter type of ZZ extreme: HIGH or LOW
//|   - _gt and _lt can be used to filter ZigZag values
//+------------------------------------------------------------------+
bool CZigzagerPattern::GetLastLevel(const ENUM_TRADE_DIR _dir, 
                                    CDKBarTagZigZag& _tag, 
                                    const double _gt=0.0, const double _lt=0.0,
                                    const datetime _before_dt = 0,
                                    const bool _apply_filter = false) {
  for (int i=0; i<ZigZagExtremes.Total(); i++) {
    CDKBarTagZigZag* tag = ZigZagExtremes.At(i);
    if (_before_dt > 0 && tag.GetTime() >= _before_dt) continue;
    if (_dir != TRADE_DIR_BUYSELL && tag.GetDir() != _dir) continue;
    if (_gt > 0.0 && tag.GetValue() < _gt) continue;
    if (_lt > 0.0 && tag.GetValue() > _lt) continue;
    if (_apply_filter) 
     if (IsBarDTDisabled(tag.GetTime()))
        continue;
    
    _tag = tag;
    return true;
  }
  
  return false;  
}

//+------------------------------------------------------------------+
//| Draw ZigZag
//+------------------------------------------------------------------+
void CZigzagerPattern::Draw() {
  if (!DrawEnable) return;
  
  ObjectsDeleteAll(0, StringFormat("%s:ZZRIB:", Prefix));
  for (int i=0; i<ZigZagExtremes.Total()-1; i++) {
    CDKBarTagZigZag* tag0 = ZigZagExtremes.At(i);
    CDKBarTagZigZag* tag1 = ZigZagExtremes.At(i+1);
    TrendLineCreate(0,      // chart's ID
                    StringFormat("%s:ZZ_RIB:%s", Prefix, TimeToString(tag0.GetTime())), // line name
                    StringFormat("%s:ZZ_RIB:%s", Prefix, TimeToString(tag0.GetTime())), // descr name
                    0,    // subwindow index
                    tag0.GetTime(),         // first point time
                    tag0.GetValue(),        // first point price
                    tag1.GetTime(),         // second point time
                    tag1.GetValue(),        // second point price
                    clrGray,      // line color
                    STYLE_SOLID, // line style
                    1,         // line width
                    true,      // in the background
                    false,  // highlight to move
                    false,  // line's continuation to the left
                    false, // line's continuation to the right
                    false,     // hidden in the object list
                    0);
  }
}

void CZigzagerPattern::DrawTagOpen(CDKBarTagZigZag& _tag) {
  if (!DrawEnable) return;
  
  // Arrow at level price
  datetime dt = TimeCurrent();
  color col = (_tag.GetDir() == TRADE_DIR_BUY) ? clrGreen : clrRed;
  string obj_suffix = (_tag.GetDir() == TRADE_DIR_BUY) ? "BUY" : "SELL";
  TextCreate(0,               // ID графика 
             StringFormat("%s|%s|OPEN|%s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(dt)), // name
             0,             // номер подокна 
             _tag.TimeDetect,            // время точки привязки
             _tag.GetValue(),           // цена точки привязки
             "è",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             col,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью 

  TextCreate(0,               // ID графика 
             StringFormat("%s|%s|SL|%s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(dt)), // name
             0,             // номер подокна 
             _tag.TimeDetect,            // время точки привязки
             _tag.SL,           // цена точки привязки
             "û",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             col,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью 
  
  TextCreate(0,               // ID графика 
             StringFormat("%s|%s|TP|%s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(dt)), // name
             0,             // номер подокна 
             _tag.TimeDetect,            // время точки привязки
             _tag.TP,           // цена точки привязки
             "¬",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             col,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью                      
}

void CZigzagerPattern::DrawTagClose(CDKBarTagZigZag& _tag) {
  if (!DrawEnable) return;
  
  // Arrow at level price
  datetime close = TimeCurrent();
  color col = (_tag.GetDir() == TRADE_DIR_BUY) ? clrGreen : clrRed;
  string obj_suffix = (_tag.GetDir() == TRADE_DIR_BUY) ? "BUY" : "SELL";
  TextCreate(0,               // ID графика 
             StringFormat("%s|%s|CLOSE|s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(close)), // name
             0,             // номер подокна 
             close,            // время точки привязки
             _tag.GetValue(),           // цена точки привязки
             "ç",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             col,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью 

  TrendLineCreate(0,  
                  StringFormat("%s|%s|LEVEL|%s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(close)),
                  StringFormat("%s|%s|LEVEL|%s|%s", Prefix, obj_suffix, TimeToString(_tag.GetTime()), TimeToString(close)),
                  0,
                  close, _tag.GetValue(),
                  _tag.TimeDetect, _tag.GetValue(),
                  col, 
                  STYLE_DASHDOT,
                  1,
                  false,
                  false,
                  false,
                  false,
                  false,
                  0);
}