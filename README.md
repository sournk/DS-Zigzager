# DS-Zigzager
Советник для MetaTrader 5. Торгует от уровней ZigZag-а

##  Настройки
input     group                    "2. ОСНОВНЫЕ НАСТРОЙКИ"
- [x] `gMagic`: Идентификатор ордеров
- [x] `gComment`: Дополнительный комментарий к ордерам
- [x] `SetTypePos`: Направление торговли
- [x] `Type_lot`: Направление торговли
- [x] `Lot`: Если лот фиксированный, то равен...
- [x] `Money_loss`: Если лот динамичный, то допустимый убыток.... $

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
- [x] `Close_TPord_on_Time`: Закрывать профитные ордера в конце дня?
- [x] `Hour_closing`: Если закрывать, то в котором часу?

input     group                    "4а. БЕЗУБЫТОК И ТРЕЙЛИНГ
- [x] `trailingStop`: Какой использовать трейлинг?
    - [x] `Трейлинг ступенчатый`. Активация при `BBUSize`+`BBUSizePip`. Дистанция - `BBUSizePip`.
    - [x] `Трейлинг по ценовому каналу`. Активация при `BBUSize`. Трейлинг по HIGH/LOW ценового канала из `iTralBars` свеч M1 + `DistanceSL`.
    - [x] `Трейлинг по индикаторам (MA и Fractals)`. Активация сразу при открытии сделки. Трейлинг по значению MA + `DistanceSL`. ==Индикатор Fractals не используется в боте MT4, поэтому для MT5 тоже не реализован==
- [x] `BBUSize`: Перенос SL в безубыток, если ордер в плюс на...пунктов
- [x] `BBUSizePip`: Уровень безубытка, пункты
- [x] `TrailingStep`: Если трал ступенчатый, то с шагом...пунктов
- [x] `iTralBars`: Если трал по цен.каналу, то сколько баров M1 берем?
- [x] `DistanceSL`: Какой отступ SL от границы канала? (пунктов)

input     group                    "5. ВТОРОСТЕПЕННЫЕ НАСТРОЙКИ"
- [x] `IsDeletePending`: Удалять отложки в ночную паузу
- [x] `PauseTimeStart`: Время начала ночной паузы
- [x] `PauseTimeStop`: Время окончания ночной паузы
- [x] `gFlgDrawZZ`: Рисовать график ZigZag и уровни торговли SL+TP.
- [ ] `gFlgLinesHL`: Рисовать линии High и Low?
- [ ] `gFlgLevelsHL`: Рисовать уровни сделок?
- [x] `11`.LL: Log Level
          string                   InpBP                                 = "DSZZ";
          uint                     InpCommentUpdateDelayMs               = 5*1000;                              // Update comment delay


- [x] После открытия позиции от уровня он должен стать невалидный для открытия других позиций от него.
- [ ] Восстановить ордера из рынка