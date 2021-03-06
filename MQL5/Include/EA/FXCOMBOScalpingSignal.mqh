//+------------------------------------------------------------------+
//|                                        FXCOMBOScalpingSignal.mqh |
//|                                                         Zephyrrr |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zephyrrr"
#property link      "http://www.mql5.com"
#include <ExpertModel\ExpertModelSignal.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>

#include <Indicators\Oscilators.mqh>
#include <Indicators\TimeSeries.mqh>

#include <ExpertModel\ExpertModel.mqh>

class CFXCOMBOScalpingSignal : public CExpertModelSignal
  {
private:
    CiClose m_iClose;
    CiMA m_iMa;
    CiWPR m_iWPR;
    int TakeProfit;
    int StopLoss;
    int OSC_close;
    int gi_356;
    int TREND_STR;
    int OSC_open;
    int gi_368;
    
    bool GetOpenSignal(int wantSignal);
    bool GetCloseSignal(int wantSignal);
public:
                     CFXCOMBOScalpingSignal();
                    ~CFXCOMBOScalpingSignal();
   virtual bool      ValidationSettings();
   virtual bool      InitIndicators(CIndicators* indicators);
   
   virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseLong(CTableOrder* t, double& price);
   virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseShort(CTableOrder* t, double& price);
  };

void CFXCOMBOScalpingSignal::CFXCOMBOScalpingSignal()
{
}

void CFXCOMBOScalpingSignal::~CFXCOMBOScalpingSignal()
{
}

bool CFXCOMBOScalpingSignal::ValidationSettings()
{
    if(!CExpertSignal::ValidationSettings()) 
        return(false);
        
    if (false)
    {
      printf(__FUNCTION__+": Indicators should not be Null!");
      return(false);
    }
    return(true);
}

bool CFXCOMBOScalpingSignal::InitIndicators(CIndicators* indicators)
{
    if(indicators==NULL) 
        return(false);
    bool ret = true;
    
    ret &= m_iClose.Create(m_symbol.Name(), PERIOD_M15);
    ret &= m_iMa.Create(m_symbol.Name(), PERIOD_M15, 60, 0, MODE_SMMA, PRICE_CLOSE);
    ret &= m_iWPR.Create(m_symbol.Name(), PERIOD_M15, 18);
    // 默认是16
    //m_iWPR.BufferResize(1000);
    
    ret &= indicators.Add(GetPointer(m_iClose));
    ret &= indicators.Add(GetPointer(m_iMa));
    ret &= indicators.Add(GetPointer(m_iWPR));
    
    TakeProfit = 21 * GetPointOffset(m_symbol.Digits());
    StopLoss = 300 * GetPointOffset(m_symbol.Digits());
    
    OSC_close = 13;
    gi_356 = -5 * GetPointOffset(m_symbol.Digits());
    TREND_STR = 20 * GetPointOffset(m_symbol.Digits());
    OSC_open = 10;
    gi_368 = 6;
    
    return ret;
}

bool CFXCOMBOScalpingSignal::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
{
    if (GetOpenSignal(1))
    {
        price = m_symbol.Ask();
        tp = price + TakeProfit * m_symbol.Point();
        sl = price - StopLoss * m_symbol.Point();
        
        Debug("CFXCOMBOScalpingSignal open long with price = " + DoubleToString(price, 4) + " and tp = " + DoubleToString(tp, 4) + " and sl = " + DoubleToString(sl, 4));
        return true;
    }
    
    return false;
}

bool CFXCOMBOScalpingSignal::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
{
    if (GetOpenSignal(-1))
    {
        price = m_symbol.Bid();
        tp = price - TakeProfit * m_symbol.Point();
        sl = price + StopLoss * m_symbol.Point();
        
        Debug("CFXCOMBOScalpingSignal open short with price = " + DoubleToString(price, 4) + " and tp = " + DoubleToString(tp, 4) + " and sl = " + DoubleToString(sl, 4));
        return true;
    }
    
    return false;
}

bool CFXCOMBOScalpingSignal::CheckCloseLong(CTableOrder* t, double& price)
{
    if (GetCloseSignal(1))
    {
        price = m_symbol.Bid();
        
        Debug("CFXCOMBOScalpingSignal close long with price = " + DoubleToString(price, 4));
        return true;
    }
    return false;
}

bool CFXCOMBOScalpingSignal::CheckCloseShort(CTableOrder* t, double& price)
{
    if (GetCloseSignal(-1))
    {
        price = m_symbol.Ask();
        
        Debug("CFXCOMBOScalpingSignal close short with price = " + DoubleToString(price, 4));
        return true;
    }
    return false;
}

bool CFXCOMBOScalpingSignal::GetOpenSignal(int wantSignal)
{
    CExpertModel* em = (CExpertModel *)m_expert;

    m_iClose.Refresh(-1);
    m_iWPR.Refresh(-1);
    m_iMa.Refresh(-1);
    
    double l_iclose_212 = m_iClose.GetData(1);
    double l_ima_220 = m_iMa.Main(1);
    double l_iwpr_228 = m_iWPR.Main(1);
    
    MqlDateTime now;
    TimeGMT(now);
    int hour = now.hour - GetGMTOffset();
    if (hour < 0) hour += 24;
    
    // 测试的时候时间要+2，实际则不需要，因为已经是GMT
    int gi_360 = 21;    // Hour
    
    if (wantSignal == 1 && em.GetOrderCount(ORDER_TYPE_BUY) < 1)
    {
        if ((l_iclose_212 > l_ima_220 + TREND_STR * m_symbol.Point() && l_iwpr_228 < OSC_open + (-100) && m_symbol.Bid() < l_iclose_212 - gi_356 * m_symbol.Point()) 
            || (l_iwpr_228 < gi_368 + (-100) && m_symbol.Bid() < l_iclose_212 - gi_356 * m_symbol.Point() && hour == gi_360))
        {
            return true;
        }
    }
    else if (wantSignal == -1 && em.GetOrderCount(ORDER_TYPE_SELL) < 1)
    {
        if ((l_iclose_212 < l_ima_220 - TREND_STR * m_symbol.Point() && l_iwpr_228 > (-OSC_open) && m_symbol.Bid() > l_iclose_212 + gi_356 * m_symbol.Point()) 
            || (l_iwpr_228 > (-gi_368) && m_symbol.Bid() > l_iclose_212 + gi_356 * m_symbol.Point() && hour == gi_360)) 
        {
            return true;
        }
    }
    return false;
}

bool CFXCOMBOScalpingSignal::GetCloseSignal(int wantSignal)
{
    // 因为测试的时候时间点选择问题，例如如果选择M15的话，可能时间点是04:29, 04:31，会错过04:30，导致按照正常刷新方式不能刷新数据（CIndicator采用只有当当前时间可以整除指标周期的时候才刷新全部数据，其余时候只刷新当前（RefreshCurrent设置为true的时候））。所以更改CIndicatorBuffer::RefreshCurrent，让其刷新当前和上一数据。
    m_iClose.Refresh(-1);
    m_iWPR.Refresh(-1);
    m_iMa.Refresh(-1);
    
    double l_iclose_212 = m_iClose.GetData(1);
    double l_iwpr_228 = m_iWPR.Main(1);
    

    //if (TimeCurrent() > D'2000.05.26 13:00')
    //{
    //    Print(l_iwpr_228, m_symbol.Bid(), l_iclose_212);
    //}
    
    if (wantSignal == 1 && l_iwpr_228 > (-OSC_close) && m_symbol.Bid() > l_iclose_212 + gi_356 * m_symbol.Point())
    {
        return true;
    }
    else if (wantSignal == -1 && l_iwpr_228 < OSC_close + (-100) && m_symbol.Bid() < l_iclose_212 - gi_356 * m_symbol.Point())
    {
        return true;
    }
    return false;
}
