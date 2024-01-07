# CloudProgramming

Oto dokumentacja dla twojego programu w języku polskim:

# Dokumentacja Programu Śledzenia Cyklu Menstruacyjnego

## Wstęp

Program Śledzenia Cyklu Menstruacyjnego to narzędzie stworzone w ramach projektu edukacyjnego na potrzeby nauki języka programowania Swift. Program ten ma na celu umożliwienie użytkownikowi monitorowania i analizowania swojego cyklu menstruacyjnego.

## Struktury Danych

### Period

`struct Period` reprezentuje okres menstruacyjny i zawiera dwie daty: początkową i końcową.

#### Atrybuty:

- `startDate`: Data rozpoczęcia okresu.
- `endDate`: Data zakończenia okresu.

#### Właściwość Obliczeniowa:

- `cycleLength`: Oblicza długość cyklu menstruacyjnego w dniach.

## Klasa PeriodTracker

`class PeriodTracker` zarządza śledzeniem okresów i operacjami na bazie danych SQLite.

#### Atrybuty:

- `db`: Połączenie z bazą danych SQLite.
- `periods`: Tabela przechowująca informacje o okresach.
- `id`: Kolumna przechowująca identyfikator okresu.
- `startDate`: Kolumna przechowująca datę rozpoczęcia okresu.
- `endDate`: Kolumna przechowująca datę zakończenia okresu.

#### Metody:

- `init()`: Inicjalizuje PeriodTracker i konfiguruje bazę danych SQLite.
- `addPeriod(start: Date, end: Date)`: Dodaje nowy okres do bazy danych.
- `getLastPeriod() -> Period?`: Pobiera informacje o ostatnim okresie.
- `getAverageCycleLength() -> Int`: Oblicza średnią długość cyklu na podstawie danych historycznych.
- `predictNextPeriodDate() -> Date?`: Przewiduje datę rozpoczęcia następnego okresu.
- `predictFertileDates() -> (fertileWindowStart: Date?, fertileWindowEnd: Date?)`: Przewiduje daty płodności w ramach cyklu.

## Operacje na Danych

- `removeLastPeriod()`: Usuwa ostatni zarejestrowany okres z bazy danych.

## Wyświetlanie Historii Okresów

- `printPeriodHistory()`: Wyświetla historię okresów, wraz z długościami cykli i szacowanymi oknami płodności.

## Interakcja z Użytkownikiem

Program komunikuje się z użytkownikiem za pomocą konsoli, pytając o akceptację warunków korzystania oraz umożliwia dodawanie nowych okresów, usuwanie ostatniego okresu, przeglądanie historii oraz przewidywanie daty rozpoczęcia następnego okresu.

## Ostrzeżenia i Zalecenia

- Program nie stanowi porady medycznej ani nie zastępuje opinii profesjonalnego opiekuna zdrowia.
- Użytkownik jest zobowiązany skonsultować się z profesjonalistą medycznym w przypadku jakichkolwiek kwestii zdrowotnych.
- Nie należy opierać decyzji dotyczących zdrowia wyłącznie na informacjach dostarczanych przez program.

## Zakończenie

Dziękujemy za skorzystanie z Programu Śledzenia Cyklu Menstruacyjnego. Mamy nadzieję, że dostarczył on wartościową edukację i pomoc w monitorowaniu cyklu menstruacyjnego.
