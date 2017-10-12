// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController, StreamSubscription;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:bokain_calendar/bokain_calendar.dart';
import '../../pipes/week_pipe.dart';

@Component(
    selector: 'bo-month-calendar',
    styleUrls: const ['../calendar_component.css','month_calendar_component.css'],
    templateUrl: 'month_calendar_component.html',
    directives: const [BookingDetailsComponent, CORE_DIRECTIVES, materialDirectives],
    providers: const [],
    pipes: const [DatePipe, PhrasePipe, WeekPipe]
)
class MonthCalendarComponent implements OnInit, OnDestroy
{
  MonthCalendarComponent(this.bookingService, this._dayService, this._salonService)
  {
    onDayAddedListener = _dayService.onChildAdded.listen((day)
    {
      for (int i = 0; i < 35; i++)
      {
        if (monthDays[i].startTime.isAtSameMomentAs((day as Day).startTime))
        {
          monthDays[i] = day;
          break;
        }
      }
    });
  }

  void ngOnInit()
  {
    setDate(date);
  }

  void ngOnDestroy()
  {
    onChangeMonthController.close();
    onDateClickController.close();
    onDayAddedListener?.cancel();
  }

  void setDate(DateTime dt)
  {
    date = new DateTime(dt.year, dt.month, 1, Day.startHour, Day.startMinute);
    firstDate = new DateTime(dt.year, dt.month, 1, Day.startHour, Day.startMinute);

    while (firstDate.weekday > 1) firstDate = firstDate.add(const Duration(days: -1));

    FirebaseQueryParams params = new FirebaseQueryParams(
        limitTo: 300,
        searchProperty: "start_time",
        searchRangeStart: ModelBase.timestampFormat(firstDate),
        searchRangeEnd: ModelBase.timestampFormat(firstDate.add(const Duration(days: 35)))
    );

    for (int i = 0; i < 35; i++)
    {
      monthDays[i] = new Day(null, salon?.id, firstDate.add(new Duration(days: i)));
    }

    _dayService.cancelStreaming();
    _dayService.streamAll(params);
  }

  void advance(int month_count)
  {
    int prevYear = date.year;
    int prevMonth = date.month;
    while (date.month == prevMonth && date.year == prevYear) date = date.add(new Duration(days: (month_count < 0) ? -1 : 1));

    /// Can only advance one month at a time
    setDate(date);
    onChangeMonthController.add(date);
  }

  /**
   * Day has available times for booking (depending on selected service, user etc)
   */
  bool highlighted(Day day)
  {
    /**
     * The day has no active schedule, there's no way it can be highlighted
     */
    if (!day.isPopulated(salon?.id, user?.id)) return false;

    /**
     * No service specified, return true to indicate that the day has an active schedule
     */
    if (service == null) return true;


    /**
     * A service has been specified, return whether or not the day has available times for the service
     */
    DateTime now = new DateTime.now();
    if (day.endTime.isBefore(now)) return false;

    Iterable<Increment> populatedIncrements = day.increments.where((i) => i.isPopulated);
    return populatedIncrements.firstWhere((inc) => _available(inc, day), orElse: () => null) != null;
  }

  bool _available(Increment increment, Day day)
  {
    Iterable<String> userIds = (user == null) ? _getQualifiedUserIdsForIncrement(increment) : [user.id];
    if (userIds.isEmpty) return false;
    Iterable<String> roomIds = _getQualifiedRoomIdsForIncrement(increment);
    if (roomIds.isEmpty) return false;

    DateTime startTime = increment.startTime;
    DateTime endTime = increment.startTime.add(service.duration + service.afterMargin);

    DateTime previousEndTime;

    /// Make sure all increments covered by the service's duration is available
    Iterable<Increment> durationCoveredIncrements = day.increments.where((di) =>
    di.startTime.isBefore(endTime) && di.endTime.isAfter(startTime));

    for (Increment i in durationCoveredIncrements)
    {
      if (previousEndTime != null && !i.startTime.isAtSameMomentAs(previousEndTime)) return false;       /// Time is not continuous
      else
      {
        userIds = _getQualifiedUserIdsForIncrement(i).where(userIds.contains);
        roomIds = _getQualifiedRoomIdsForIncrement(i).where(roomIds.contains);
        if (userIds.isEmpty || roomIds.isEmpty) return false;                   /// No users left or no rooms left
      }
      previousEndTime = i.endTime;
    }
    return true;
  }

  Iterable<String> _getQualifiedUserIdsForIncrement(Increment increment)
  {
    /// No user selected, return all qualified
    if (user == null)
    {
      return increment.userStates.keys.where((id) =>
      service.userIds.contains(id) && (increment.userStates[id].bookingId == null && increment.userStates[id].state == "open"));
    }
    else
    {
      if (!increment.userStates.containsKey(user.id)) return [];
      UserState us = increment.userStates[user.id];
      return ((us.bookingId == null && us.state == "open")) ? [user.id] : [];
    }
  }

  Iterable<String> _getQualifiedRoomIdsForIncrement(Increment increment)
  {
    Iterable<Room> rooms = _salonService.getRooms(salon.roomIds).where((room) =>
    room.serviceIds.contains(service.id) && room.status == "active" && bookingService.getByTimeAndRoomId(increment.startTime, room.id) == null);
    return rooms.map((r) => r.id);
  }


  final BookingService bookingService;
  final DayService _dayService;
  final SalonService _salonService;
  DateTime firstDate;
  List<Day> monthDays = new List(35);
  final StreamController<DateTime> onDateClickController = new StreamController();
  final StreamController<DateTime> onChangeMonthController = new StreamController();
  StreamSubscription<Day> onDayAddedListener;

  @Input('date')
  DateTime date;

  @Input('salon')
  Salon salon;

  @Input('user')
  User user;

  /**
   * Scheduled days with no available times for booking will not be highlighted if this
   * is set (by default, any day with an active schedule is highlighted)
   */
  @Input('service')
  Service service;

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;

  @Output('changeMonth')
  Stream<DateTime> get changeMonthOutput => onChangeMonthController.stream;
}