//+------------------------------------------------------------------+
//|                                                    CZigzager.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Arrays\ArrayObj.mqh>
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
  
  DKLogger                 Logger;
public:
  void                     CZigzagerPattern::Init(const string _sym, const ENUM_TIMEFRAMES _tf, const int _depth, const int _handle, const string _prefix);
  void                     CZigzagerPattern::SetLogger(DKLogger& _logger) { Logger = _logger; };
  
  int                      CZigzagerPattern::UpdateZigZag();
  bool                     CZigzagerPattern::GetLastLevel(const ENUM_TRADE_DIR _dir, 
                                                          CDKBarTagZigZag& _tag, 
                                                          const double _gt=0.0, const double _lt=0.0,
                                                          const datetime _before_dt = 0);
  
  void                     CZigzagerPattern::Draw();
  
  //void                     CZigzagerPattern::CZigzagerPattern(void);
  //void                     CZigzagerPattern::~CZigzagerPattern(void);  
};

void CZigzagerPattern::Init(const string _sym, const ENUM_TIMEFRAMES _tf, const int _depth, const int _handle, const string _prefix) {
  Prefix = _prefix;
  Sym = _sym;
  TF = _tf;
  Depth = _depth;
  Handle = _handle;
  
  ZigZagExtremes.Clear();
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

  for (int i=ArraySize(val)-1; i>=0; i--) {
    if (val[i] <= 0.0) continue;
    CDKBarTagZigZag* tag = new CDKBarTagZigZag;
    tag.Init(Sym, TF, ArraySize(val)-1-i+shift_start, val[i]);
    ZigZagExtremes.Add(tag); 
  }
  
  // Delete last extreme if needed
  if (skip_last_extreme && ZigZagExtremes.Total() > 0) ZigZagExtremes.Delete(0);
  
  // Min 2 ZZ extremes needed to figure out HIGH or LOW type of them
  if (ZigZagExtremes.Total() < 2) { ZigZagExtremes.Clear(); return 0; }

  // Determinate tag0 type
  CDKBarTagZigZag* tag0 = ZigZagExtremes.At(0);
  CDKBarTagZigZag* tag1 = ZigZagExtremes.At(1);
  ENUM_TRADE_DIR dir = (tag0.GetValue() > tag1.GetValue() ? TRADE_DIR_BUY : TRADE_DIR_SELL);
  
  for (int i=0; i<ZigZagExtremes.Total(); i++) {
    CDKBarTagZigZag* tag = ZigZagExtremes.At(i);
    tag.SetDir(dir);
    dir = (dir == TRADE_DIR_SELL) ? TRADE_DIR_BUY : TRADE_DIR_SELL; // Switch dir to opposite
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
                                    const datetime _before_dt = 0) {
  for (int i=0; i<ZigZagExtremes.Total(); i++) {
    CDKBarTagZigZag* tag = ZigZagExtremes.At(i);
    if (_before_dt > 0 && tag.GetTime() >= _before_dt) continue;
    if (_dir != TRADE_DIR_BUYSELL && tag.GetDir() != _dir) continue;
    if (_gt > 0.0 && tag.GetValue() < _gt) continue;
    if (_lt > 0.0 && tag.GetValue() > _lt) continue;
    
    _tag = tag;
    return true;
  }
  
  return false;  
}

//+------------------------------------------------------------------+
//| Draw ZigZag
//+------------------------------------------------------------------+
void CZigzagerPattern::Draw() {
  ObjectsDeleteAll(0, StringFormat("%s:ZZRIB:", Prefix));
  for (int i=0; i<ZigZagExtremes.Total()-1; i++) {
    CDKBarTagZigZag* tag0 = ZigZagExtremes.At(i);
    CDKBarTagZigZag* tag1 = ZigZagExtremes.At(i+1);
    TrendLineCreate(0,      // chart's ID
                    StringFormat("%s:ZZRIB:%s", Prefix, TimeToString(tag0.GetTime())), // line name
                    StringFormat("%s:ZZRIB:%s", Prefix, TimeToString(tag0.GetTime())), // descr name
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