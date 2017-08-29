import 'dart:async' show StreamController, StreamSubscription;
import 'package:angular2/angular2.dart';
import 'package:bokain_models/bokain_models.dart' show BookingService, CalendarService, SalonService, UserService, Day, Salon, User;

abstract class DayBase
{
  DayBase(this.bookingService, this.calendarService, this.salonService, this.userService);

  void ngAfterContentInit()
  {
    dayAddedListener?.cancel();
    dayChangedListener?.cancel();
    dayAddedListener = calendarService.onDayAdded.listen(updateDayRemote);
    dayChangedListener = calendarService.onDayChanged.listen(updateDayRemote);
    day = new Day(null, selectedSalon.id, date);
    calendarService.setFilters(date, date);
  }

  void ngOnChanges(Map<String, SimpleChange> changes)
  {
    if (changes.containsKey("selectedState") && changes.length == 1) return;
    day = new Day(null, selectedSalon.id, date);

    calendarService.setFilters(date, date);
  }

  void ngOnDestroy()
  {
    onDateClickController?.close();
    dayAddedListener?.cancel();
    dayChangedListener?.cancel();
  }

  void updateDayRemote(Day d)
  {
    if (d.salonId == selectedSalon.id) day = d;
  }

  DateTime get date => _date;

  final BookingService bookingService;
  final CalendarService calendarService;
  final SalonService salonService;
  final UserService userService;
  DateTime _date;
  StreamSubscription<Day> dayAddedListener;
  StreamSubscription<Day> dayChangedListener;
  final StreamController<DateTime> onDateClickController = new StreamController();
  Day day;
  User selectedUser;
  Salon selectedSalon;
  void set date(DateTime value)
  {
    _date = new DateTime(value.year, value.month, value.day, Day.startHour, Day.startMinute, 0);
  }
}