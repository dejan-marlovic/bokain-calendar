import 'dart:async';
import 'package:angular/angular.dart';
import 'package:bokain_models/bokain_models.dart';

abstract class DayBase
{
  DayBase(this.bookingService, this.dayService, this.salonService, this.userService);

  void ngOnInit()
  {
    _bufferDay = new Day(null, salon.id, _date);
  }

  void ngOnChanges(Map<String, SimpleChange> changes)
  {
    if (changes.containsKey("date"))
    {
      /**
       * Stream today
       */
      dayService.streamAll(new FirebaseQueryParams(limitTo: 100, searchProperty: "start_time", searchValue: ModelBase.timestampFormat(_date)));
    }
  }

  Day get day
  {
    if (salon == null) return null;

    Iterable<Day> days = dayService.streamedModels.values;
    return days.firstWhere((d) => d.salonId == salon.id && (user == null || d.containsUser(user.id)), orElse: () => _bufferDay);
  }

  void ngOnDestroy()
  {
    onDateClickController?.close();
  }

  DateTime get date => _date;

  final BookingService bookingService;
  final DayService dayService;
  final SalonService salonService;
  final UserService userService;
  final StreamController<DateTime> onDateClickController = new StreamController();
  DateTime _date;

  @Input('user')
  User user;

  @Input('salon')
  Salon salon;

  @Input('date')
  void set date(DateTime value)
  {
    _date = new DateTime(value.year, value.month, value.day, Day.startHour, Day.startMinute, 0);
  }

  Day _bufferDay;

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;
}