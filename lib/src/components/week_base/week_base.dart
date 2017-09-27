import 'dart:async';
import 'package:angular/angular.dart';
import 'package:bokain_models/bokain_models.dart' show Salon, User;

abstract class WeekBase
{
  WeekBase();

  void ngOnDestroy()
  {
    onDateClickController.close();
  }

  final StreamController<DateTime> onDateClickController = new StreamController();
  List<DateTime> weekDates = new List(7);

  @Input('user')
  User user;

  @Input('salon')
  Salon salon;

  @Input('date')
  void set date(DateTime value)
  {
    DateTime iDate = new DateTime(value.year, value.month, value.day, 12);
    // Monday
    iDate = new DateTime(iDate.year, iDate.month, iDate.day - (iDate.weekday - 1), 12);

    for (int i = 0; i < 7; i++)
    {
      weekDates[i] = iDate;
      iDate = iDate.add(const Duration(days: 1));
    }
  }

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;
}
