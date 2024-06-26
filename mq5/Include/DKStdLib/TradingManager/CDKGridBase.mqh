//+------------------------------------------------------------------+
//|                                                     CDKGrids.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "..\Common\DKStdLib.mqh"
#include "..\Logger\DKLogger.mqh"

#include <Arrays\ArrayLong.mqh>
#include <Trade\Trade.mqh>

#include "CDKPositionInfo.mqh"

//+------------------------------------------------------------------+
//| Grid State Struct
//+------------------------------------------------------------------+
struct DKGridState {
  uint                Size;                                             // Grid open position count
  double              Volume;                                           // Grid volume
  double              Sum;                                              // Grid sum
  double              SumFull;                                          // Grid sum with swap and commision
  double              Profit;                                           // Grid profit
  double              Commission;                                       // Grid commision
  double              Swap;                                             // Grid swap
  double              PriceAverage;                                     // Grid price average
  double              PriceBreakEven;                                   // Grid break-even price of a grid
};

//+------------------------------------------------------------------+
//| Base Grid Class uses:
//| 1. Grid size contol by CheckEntry method
//| 2. Load open pos by Magic and Symbol
//| 3. Add pos by Ticket
//| 4. Get cumulative state
//| 5. OpenNext pos
//| 6. Set SL/TP for all grid pos
//| 7. Set SL/TP from avgerage or breakeven price
//| 8. Get any pos of grid
//| 9. SetLogger can make logs with different levels
//+------------------------------------------------------------------+
class CDKGridBase : public CObject {
 protected:
  CDKSymbolInfo            m_symbol;
  CTrade                   m_trade;

  uint                     m_max_pos_count;
  ulong                    m_magic;  
  string                   m_comment_prefix;
  string                   m_id;  
  
  CArrayLong               m_positions;
  
  DKLogger*                m_logger;
 public:
  void                Init(const string aSymbol,                                       // Constructor pseudo 
                           const uint aMaxPositionCount,
                           const string aCommentPrefix,
                           const ulong aMagic,
                           CTrade& Trade);                                             // Preconfigurated CTrade  
  
  void                SetLogger(DKLogger* aLogger);                                    // Set logger                           
  
  bool                Get(const uint aIndex, CDKPositionInfo& aPosition);              // Return grid position by index
  bool                GetLast(CDKPositionInfo& aPosition);                             // Return last position
  uint                Size();                                                          // Return position count of the grid

  bool                Add(const ulong aTicket);                                        // Add position to the grid by ticket
  uint                OpenPosCount();                                                  // Returns count of open pos with Same Magic and Symbol
  uint                AddMarketPositions();                                            // Adds to grid all open positions
  uint                Load();                                                          // Load all open positions by Magic
  uint                Delete(const uint aIndex);                                       // Add position to the grid. Return new size of grid
  void                Clear();                                                         // Clear all grid's positions

  DKGridState         GetState();                                                      // Returns current state of grid

  bool                CheckEntry();                                                    // Checks is it possible to open next grid position (max grid size check)
  ulong               OpenNext(const string aSymbol,                                   // New pos symbol
                               const ENUM_POSITION_TYPE aDirection,                    // New pos direction
                               const double aLots,                                     // New pos lots
                               const double aPrice,                                    // Open price
                               const double aSL,                                       // New pos SL
                               const double aTP,                                       // New pos TP
                               const string aComment);                                 // New pos comment
  bool                SetSLTP(double aSL, double aTP);                                 // Update take profit and stop loss for all orders of the gird                               
  
  bool                SetTPFromAveragePrice(const double aSLDistance, 
                                            const double aTPDistance);                 // Set take profit for all orders of the gird to AP+aDistance
  bool                SetTPFromAveragePricePoint(const int aSLDistancePoint, 
                                                 const int aTPDistancePoint);          // Set take profit for all orders of the gird to AP+aDistance in point

  bool                SetTPFromBreakEven(const double aSLDistance, 
                                         const double aTPDistance);                    // Set take profit for all orders of the gird to BE+aDistance
  bool                SetTPFromBreakEvenPoint(const int aSLDistancePoint, 
                                              const int aTPDistancePoint);             // Set take profit for all orders of the gird to BE+aDistance in point
  
  uint                CloseAll();
  
  string              GetPosComment(const string aPrefix, const uint aNumber);         // Returns pos comment
  string              GetIDFromComment(const string aComment);                         // Parse aComment and return grid id  
  
  string              GetID();                                                         // Returns grid ID
  string              GetDescription();                                                // Get description string
  
  void                Log(string aMessageTest, LogLevel aMessageLevel = LogLevel(INFO));
};

//+------------------------------------------------------------------+
//| Log operations
//+------------------------------------------------------------------+
void CDKGridBase::Log(string aMessageTest, LogLevel aMessageLevel = LogLevel(INFO)) {
  if (m_logger != NULL) m_logger.Log(aMessageTest, aMessageLevel);
}

//+------------------------------------------------------------------+
//| Init
//+------------------------------------------------------------------+
void CDKGridBase::Init(const string aSymbol,
                       const uint aMaxPositionCount,
                       const string aCommentPrefix,
                       const ulong aMagic,
                       CTrade& aTrade){
  m_magic = aMagic;
  m_max_pos_count = aMaxPositionCount;
  
  m_symbol.Name(aSymbol);
  m_trade = aTrade;
  
  m_comment_prefix = aCommentPrefix;
  m_id = (m_id == "" || Size() <= 0) ? GetUniqueInstanceName("") : m_id;   // ID with no prefix
}

//+------------------------------------------------------------------+
//| Set logger
//+------------------------------------------------------------------+
void CDKGridBase::SetLogger(DKLogger* aLogger){
  m_logger = aLogger;
}

//+------------------------------------------------------------------+
//| Get pos by index
//+------------------------------------------------------------------+
bool CDKGridBase::Get(const uint aIndex, CDKPositionInfo& aPosition) {
  long ticket = m_positions.At(aIndex);
  if(ticket == LONG_MAX) return false;
  
  return aPosition.SelectByTicket(ticket);
}

//+------------------------------------------------------------------+
//| Get last pos
//+------------------------------------------------------------------+
bool CDKGridBase::GetLast(CDKPositionInfo& aPosition) {
  return Get(Size() - 1, aPosition);
}

//+------------------------------------------------------------------+
//| Get grid size
//+------------------------------------------------------------------+
uint CDKGridBase::Size() {
  return m_positions.Total();
}

//+------------------------------------------------------------------+
//| Add pos in grid by Ticket
//+------------------------------------------------------------------+
bool CDKGridBase::Add(const ulong aTicket) {
  CDKPositionInfo pos;
  if (m_positions.Search(aTicket) >= 0) return false; // aTicket is already in list
  
  if (pos.SelectByTicket(aTicket)) {
    m_positions.Add(aTicket);
    Log(StringFormat("Position added to grid: GID=%s | TICKET=%I64u | DIR=%s | SIZE=%d/%d", 
                     m_id, aTicket, pos.TypeDescription(), Size(), m_max_pos_count), DEBUG);
    return true;
  }

  return false;
}

//+------------------------------------------------------------------+
//| Returns number of open pos with same Magic and Symbol
//+------------------------------------------------------------------+
uint CDKGridBase::OpenPosCount() {
  uint posCnt = 0;
  
  CDKPositionInfo pos;
  for(int i = 0; i < PositionsTotal(); i++) {
    if(!pos.SelectByIndex(i)) continue; // Pos not found
    if(pos.Symbol() != m_symbol.Name()) continue; // Wrong Symbol
    if (pos.Magic() != m_magic) continue; // Wrong Magic
    posCnt++;     
  }
   
  return posCnt;
}

//+------------------------------------------------------------------+
//| Load pos by Magic and Symbol
//+------------------------------------------------------------------+
uint CDKGridBase::AddMarketPositions() {
  uint posCnt = 0;
  string old_id = m_id;
  
  CDKPositionInfo pos;
  for(int i = 0; i < PositionsTotal(); i++) {
    if (!pos.SelectByIndex(i)) continue; // Pos not found
    if (pos.Symbol() != m_symbol.Name()) continue; // Wrong Symbol
    if (pos.Magic() != m_magic) continue; // Wrong Magic

    string new_id = GetIDFromComment(pos.Comment());
    if (new_id != m_id)
      m_id = (new_id == "") ? GetUniqueInstanceName("") : new_id;  
    
    if (Add(pos.Ticket())) posCnt++;     
  }  
 
  Log(StringFormat("Positions have loadled: GID=%s->%s | MAGIC=%I64u | CNT=%d | SIZE=%d/%d", 
                   old_id, m_id, m_magic, posCnt, Size(), m_max_pos_count), INFO);
  return posCnt;
}

//+------------------------------------------------------------------+
//| Load pos by Magic and Symbol
//+------------------------------------------------------------------+
uint CDKGridBase::Load() {
  Clear();
  return AddMarketPositions();
}

//+------------------------------------------------------------------+
//| Delete pos from grif by index
//+------------------------------------------------------------------+
uint CDKGridBase::Delete(const uint aIndex) {
  m_positions.Delete(aIndex);
  return Size();
}

//+------------------------------------------------------------------+
//| Clear grid pos
//+------------------------------------------------------------------+
void CDKGridBase::Clear() {
  m_positions.Clear();
}

//+------------------------------------------------------------------+
//| Returns cumulative state
//+------------------------------------------------------------------+
DKGridState CDKGridBase::GetState() {
  DKGridState state;

  state.Size          = Size();
  state.Volume        = 0;
  state.Sum           = 0;
  state.SumFull       = 0;
  state.Profit        = 0;
  state.Commission    = 0;
  state.Swap          = 0;
  for (uint i = 0; i < Size(); i++) {
    CDKPositionInfo pos;
    if (!Get(i, pos)) continue;
    
    state.Volume          += pos.Volume();
    state.Sum             += pos.Volume() * pos.PriceOpen();
    state.Profit          += pos.Profit();
    state.Commission      += pos.Commission();
    state.Swap            += pos.Swap();
  }

  state.SumFull        = state.Sum - state.Swap - state.Commission; 
  state.PriceAverage   = (state.Volume != 0) ? state.Sum / state.Volume : 0;

  double point = m_symbol.Point();
  double point_value = GetPointValue(m_symbol.Name());
  point_value = m_symbol.TickValue();
  double corr = 0;
  if (state.Volume * point_value != 0) corr = point * ((state.Commission + state.Swap) / (state.Volume * point_value));
  state.PriceBreakEven = 0;
  if (state.Volume != 0) state.PriceBreakEven = (state.Sum - corr * state.Volume) / state.Volume;

  return state;
}

bool CDKGridBase::CheckEntry() {
  bool res = (m_max_pos_count < 0 || Size() < m_max_pos_count);
  Log(StringFormat("CDKGridBase::CheckEntry(SIZE<MAX): RES=%d | GID=%s | SIZE=%d/%d", 
                   res, m_id, Size(), m_max_pos_count), DEBUG);  
  return res;
}

//+------------------------------------------------------------------+
//| Opens next pos 
//+------------------------------------------------------------------+
ulong CDKGridBase::OpenNext(const string aSymbol,                 // New pos symbol
                            const ENUM_POSITION_TYPE aDirection,  // New pos direction
                            const double aLots,                   // New pos lots
                            const double aPrice,                  // Open price
                            const double aSL,                     // New pos SL
                            const double aTP,                     // New pos TP
                            const string aComment) {              // New pos comment
  // Check that grid has actual size
  if (Size() != OpenPosCount()) Load();                            
                            
  bool openRes;
  if(aDirection == POSITION_TYPE_BUY)  openRes = m_trade.Buy(aLots, aSymbol, aPrice, aSL, aTP, aComment);
  if(aDirection == POSITION_TYPE_SELL) openRes = m_trade.Sell(aLots, aSymbol, aPrice, aSL, aTP, aComment);
 
  if(openRes) {
    ulong openDeal = m_trade.ResultDeal();
    ulong openOrder = m_trade.ResultOrder();
    if (openDeal != 0) {
      Log(StringFormat("Position open: GID=%s | ORDER=%I64u | DEAL=%I64u | DIR=%s | NEW_SIZE=%d/%d", 
                       m_id, openOrder, openDeal, EnumToString(aDirection), Size() + 1, m_max_pos_count), INFO);
      Add(openOrder);
      return openOrder;
    }
    else    
      Log(StringFormat("Position open error: ResultDeal()=0 | GRD=%s | DIR=%s | SIZE=%d/%d", m_id, EnumToString(aDirection), Size(), m_max_pos_count), ERROR);
  }
  else
    Log(StringFormat("Position open error: RETCODE=%d | GID=%s | DIR=%s | SIZE=%d/%d", 
                     m_trade.ResultRetcode(), m_id, EnumToString(aDirection), Size(), m_max_pos_count), ERROR);
  
  return 0;
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos
//+------------------------------------------------------------------+
bool CDKGridBase::SetSLTP(double aSL, double aTP) {
  // Check that grid has actual size
  if (Size() != OpenPosCount()) Load();
  
  aSL = m_symbol.NormalizePrice(aSL);
  aTP = m_symbol.NormalizePrice(aTP);
  
  bool resHasError = false;
  for (uint i = 0; i < Size(); i++) {
    CDKPositionInfo pos;
    if (!Get(i, pos)) continue;
    
    // If aSL is greater/less Bid/Ask => adjust SL to Bid/Ask
    if (!CompareDouble(aSL, 0)) {
      m_symbol.RefreshRates();
      double bid = m_symbol.Bid();
      double ask = m_symbol.Ask(); 
      if (pos.PositionType() == POSITION_TYPE_BUY  && aSL > bid) aSL = bid;
      if (pos.PositionType() == POSITION_TYPE_SELL && aSL < ask) aSL = ask;    
    }
    
    // If SL and TP are the same then skip pos update
    double oldTP = pos.TakeProfit();
    double oldSL = pos.StopLoss();
    if (CompareDouble(oldTP, aTP) && CompareDouble(oldSL, aSL)) continue;
    
    if(m_trade.PositionModify(pos.Ticket(), aSL, aTP)) 
      if(TRADE_RETCODE_DONE == m_trade.ResultRetcode()) {
        Log(StringFormat("TPSL modified: GID=%s | TICKET=%d=%I64u | DIR=%s | SIZE=%d/%d | SL=%f->%f | TP=%f->%f | OP_PRICE=%f | CUR_PRICE=%f", 
                         m_id, i+1, pos.Ticket(), pos.TypeDescription(), Size(), m_max_pos_count, 
                         oldSL, aSL, oldTP, aTP, pos.PriceOpen(), pos.PriceCurrent()), INFO);
        continue;        
      }
    
    resHasError = true;
    Log(StringFormat("Position modify error: RETCODE=%d | GID=%s | TICKET=%d=%I64u | DIR=%s | SIZE=%d/%d | SL=%f->%f | TP=%f->%f | OP_PRICE=%f | CUR_PRICE=%f", 
                     m_trade.ResultRetcode(), m_id, i+1, pos.Ticket(), pos.TypeDescription(), Size(), m_max_pos_count, 
                     oldSL, aSL, oldTP, aTP, pos.PriceOpen(), pos.PriceCurrent()), ERROR);    
  }
    
  return resHasError;
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromAveragePrice(const double aSLDistance, 
                                        const double aTPDistance) {
  DKGridState state = GetState();  
  
  double sl = (!CompareDouble(aSLDistance, 0)) ? state.PriceAverage - aSLDistance : 0;
  return SetSLTP(0, state.PriceAverage + aTPDistance);
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromAveragePricePoint(const int aSLDistancePoint, 
                                             const int aTPDistancePoint) {
  return SetTPFromAveragePrice(m_symbol.PointsToPrice(aSLDistancePoint), m_symbol.PointsToPrice(aTPDistancePoint));
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from breakeven price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromBreakEven(const double aSLDistance, 
                                     const double aTPDistance) {
  DKGridState state = GetState();  
  
  double sl = (!CompareDouble(aSLDistance, 0)) ? state.PriceBreakEven - aSLDistance : 0;
  return SetSLTP(sl, state.PriceBreakEven + aTPDistance);
}
//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromBreakEvenPoint(const int aSLDistancePoint, 
                                          const int aTPDistancePoint) {
  return SetTPFromBreakEven(m_symbol.PointsToPrice(aSLDistancePoint), m_symbol.PointsToPrice(aTPDistancePoint));
}

//+------------------------------------------------------------------+
//| Return comment for from pos by number
//+------------------------------------------------------------------+
string CDKGridBase::GetPosComment(const string aPrefix, const uint aNumber) {
  return StringFormat("%s|%s|%d", 
                      aPrefix, 
                      m_id, 
                      aNumber);
}

//+------------------------------------------------------------------+
//| Gets grid ID from pos comment
//+------------------------------------------------------------------+
string CDKGridBase::GetIDFromComment(const string aComment) {
  string arr[];
  if (StringSplit(aComment, StringGetCharacter("|", 0), arr) >= 2)
    return arr[1];
    
  return "";   
}

//+------------------------------------------------------------------+
//| Returns grid id
//+------------------------------------------------------------------+
string CDKGridBase::GetID() {
  return m_id;
}

//+------------------------------------------------------------------+
//| Returns grid summary text
//+------------------------------------------------------------------+
string CDKGridBase::GetDescription() {
  DKGridState state = GetState();
  
  return StringFormat("%s \n" +
                      "SIZE=%d/%d | CUM_LOT=%0.2f \n" +
                      "SUM=%0.2f | SWAP=%0.2f | COMM=%0.2f \n" +
                      "PROFIT=%0.2f/%0.2f \n" + 
                      "PRICE: AVG=%0.5f | BE=%0.5f \n" ,
                      m_id,
                      state.Size, m_max_pos_count, state.Volume, 
                      state.Sum, state.Swap, state.Commission,
                      state.Profit, state.Profit + state.Swap + state.Commission,
                      state.PriceAverage, state.PriceBreakEven);
}

//+------------------------------------------------------------------+
//| Close all pos of the grid
//+------------------------------------------------------------------+
uint CDKGridBase::CloseAll() {
  CDKPositionInfo pos;
  
  uint cnt = 0;
  int i = (int)Size();
  while (i >= 0) {
    if (Get(i, pos))
      if (m_trade.PositionClose(pos.Ticket()))
        if (m_trade.ResultRetcode() == TRADE_RETCODE_DONE) {
          Delete(i);
          cnt++;
          continue;    
        }
    i--;
  }
      
   Log(StringFormat("%s: GID=%s | DELETED=%d | NEW_SIZE=%d/%d", 
                     __FUNCTION__, m_id, cnt, Size(), m_max_pos_count),
       (cnt > 0) ? INFO : DEBUG);
   return cnt;
}