# DS-Zigzager
Советник для MetaTrader 5. Торгует от уровней ZigZag-а

##  Настройки
input     group                    "2. ОСНОВНЫЕ НАСТРОЙКИ"
- [x] `gMagic`: Идентификатор ордеров
- [x] `gComment`: Дополнительный комментарий к ордерам
- [x] `SetTypePos`: Направление торговли
- [x] `Type_lot`: Направление торговли
- [x] `Lot`: Если лот фиксированный, то равен...
- [ ] `Money_loss`: Если лот динамичный, то допустимый убыток.... $

input     group                    "3а. НАЙСТРОЙКИ ZIGZAG"
- [x] `gTimeFrameZZ`: Рабочий таймфрейм ZigZag
- [x] `gBarsBack`: Сколько баров в истории нужно для ZigZag
- [x] `ExtDepth`: Фильтр резких колебаний, бар
- [x] `ExtDeviation`: ZZ ExtDeviation
- [x] `ExtBackstep`: Мин.кол-во баров между экстремумами

input     group                    "3б. НАЙСТРОЙКИ MA и ParabolicSAR"
- [x] `gTimeFrameInd`: Рабочий таймфрейм индикаторов
- [x] `SetIndicator`: Выберите дополнительный индикатор
- [x] `maPeriod`: Период Moving Average, если он выбран
- [x] `ParabolicStep`: Шаг Parabolic SAR, если он выбран
- [x] `ParabolicMax`: Максимум Parabolic SAR, если он выбран

input     group                    "4. УПРАВЛЕНИЕ ОРДЕРАМИ"
- [ ] `gFlgOrdPendings`: Разрешить установку отложенных ордеров
- [ ] `gFlgOrdMarket`: Разрешить установку рыночных ордеров
- [x] `gTPmode`: Использовать Тейкпрофит какого типа?
- [x] `gTP`: Если TP фиксированный, то сколько пунктов?
- [x] `gFiboTP`: Если TP по Fibo, то на каком уровне?
- [x] `gOpenShift`: На сколько пунктов от Hi | Low выставлять ордер?
- [x] `gMaxStopLoss`: Максимальный стоп лосс, пункт
- [ ] `gFlgMASLinMoment`: SL восстановленных отложек выставлять где?
- [x] `gLifeTime`: Время жизни ордера в часах
- [ ] `Close_TPord_on_Time`: Закрывать профитные ордера в конце дня?
- [ ] `Hour_closing`: Если закрывать, то в котором часу?

input     group                    "4а. БЕЗУБЫТОК И ТРЕЙЛИНГ
- [ ] `trailingStop`: Какой использовать трейлинг?
- [x] `BBUSize`: Перенос SL в безубыток, если ордер в плюс на...пунктов
- [x] `BBUSizePip`: Уровень безубытка, пункты
- [ ] `TrailingStep`: Если трал ступенчатый, то с шагом...пунктов
- [ ] `iTralBars`: Если трал по цен.каналу, то сколько баров M1 берем?
- [ ] `DistanceSL`: Какой отступ SL от границы канала? (пунктов)

input     group                    "5. ВТОРОСТЕПЕННЫЕ НАСТРОЙКИ"
- [ ] `IsDeletePending`: Удалять отложки в ночную паузу
- [ ] `PauseTimeStart`: Время начала ночной паузы
- [ ] `PauseTimeStop`: Время окончания ночной паузы
- [ ] `gFlgDrawZZ`: Рисовать график ZigZag?
- [ ] `gFlgLinesHL`: Рисовать линии High и Low?
- [ ] `gFlgLevelsHL`: Рисовать уровни сделок?
- [ ] `11`.LL: Log Level
          string                   InpBP                                 = "DSZZ";
          uint                     InpCommentUpdateDelayMs               = 5*1000;                              // Update comment delay


- [ ] Новый ордер после открытия позиции должен открывать не от того же уровня. 