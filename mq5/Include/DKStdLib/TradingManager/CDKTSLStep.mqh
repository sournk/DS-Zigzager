//+------------------------------------------------------------------+
//|                                                   CDKTSLStep.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "CDKTrade.mqh"
#include "CDKTSLBase.mqh"

class CDKTSLStep : public CDKTSLBase {
  int                       ActivationStep;
public:
  void                      CDKTSLStep::CDKTSLBase();
  void                      CDKTSLStep::Init(const int _activation_step_point, const int _sl_distance);
  bool                      CDKTSLStep::Update(CDKTrade& _trade, const bool _update_tp);
};

void CDKTSLStep::CDKTSLBase() {
  Init(500, 0);
}

void CDKTSLStep::Init(const int _activation_step_point, const int _sl_distance) {
  ActivationStep = _activation_step_point;
  CDKTSLBase::Init(0, _sl_distance);
}

bool CDKTSLStep::Update(CDKTrade& _trade, const bool _update_tp) {
  double sl_old = StopLoss();
  double price_activation = 0;
  if (IsPriceGEOpen(AddToPrice(sl_old, ActivationStep)))
    price_activation = AddToPrice(sl_old, ActivationStep+GetDistancePoint());
  else
    price_activation = AddToPrice(PriceOpen(), ActivationStep);
  CDKTSLBase::SetActivation(price_activation);
  
  double sl_new = AddToPrice(PriceToClose(), -1*GetDistance());
  
  return CDKTSLBase::UpdateSL(_trade, sl_new, _update_tp);
}