// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:bokain_models/bokain_models.dart' show Booking, BookingService, Salon, User;
import 'package:fo_components/fo_components.dart';
import 'package:bokain_calendar/src/components/booking_details_component/booking_details_component.dart';
import 'package:bokain_calendar/src/components/booking_view_day_component/booking_view_day_component.dart';
import 'package:bokain_calendar/src/components/booking_view_week_component/booking_view_week_component.dart';
import 'package:bokain_calendar/src/components/day_stepper_component/day_stepper_component.dart';
import 'package:bokain_calendar/src/components/month_calendar_component/month_calendar_component.dart';
import 'package:bokain_calendar/src/components/schedule_day_component/schedule_day_component.dart';
import 'package:bokain_calendar/src/components/schedule_week_component/schedule_week_component.dart';
import 'package:bokain_calendar/src/components/week_stepper_component/week_stepper_component.dart';

@Component(
    selector: 'bo-booking-view',
    styleUrls: const ['booking_view_component.css'],
    templateUrl: 'booking_view_component.html',
    directives: const
    [
      BookingDetailsComponent,
      BookingViewDayComponent,
      BookingViewWeekComponent,
      CORE_DIRECTIVES,
      DayStepperComponent,
      FoModalComponent,
      materialDirectives,
      MonthCalendarComponent,
      ScheduleDayComponent,
      ScheduleWeekComponent,
      WeekStepperComponent
    ],
    pipes: const [PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class BookingViewComponent implements OnDestroy
{
  BookingViewComponent(this.bookingService);

  void ngOnDestroy()
  {
    _onActiveTabIndexChangeController.close();
    _onRebookController.close();
    _onDateChangeController.close();
  }

  void openWeekTab(DateTime dt)
  {
    activeTabIndex = 1;
    _date = dt;
  }

  openDayTab(DateTime dt)
  {
    activeTabIndex = 0;
    _date = dt;
  }

  int get activeTabIndex => _activeTabIndex;

  DateTime get date => _date;

  void set activeTabIndex(int value)
  {
    _activeTabIndex = value;
    _onActiveTabIndexChangeController.add(_activeTabIndex);
  }

  void set date(DateTime date)
  {
    _date = date;
    _onDateChangeController.add(date);
  }

  bool showBookingDetailsModal = false;
  Booking selectedBooking;
  int _activeTabIndex = 0;
  final BookingService bookingService;
  final StreamController<int> _onActiveTabIndexChangeController = new StreamController();
  final StreamController<Booking> _onRebookController = new StreamController();
  final StreamController<DateTime> _onDateChangeController = new StreamController();
  DateTime _date;

  @Input('activeTabIndex')
  void set activeTabIndexExternal(int value) { _activeTabIndex = value; }

  @Input('date')
  void set dateExt(DateTime value)
  {
    _date = value;
  }

  @Input('user')
  User user;

  @Input('salon')
  Salon salon;

  @Input('scheduleMode')
  bool scheduleMode = false;

  @Input('scheduleState')
  String scheduleState = "open";

  @Output('activeTabIndexChange')
  Stream<int> get onActiveTabIndexChangeOutput => _onActiveTabIndexChangeController.stream;

  @Output('dateChange')
  Stream<DateTime> get onDateRangeChangeOutput => _onDateChangeController.stream;

  @Output('rebook')
  Stream<Booking> get onRebookOutput => _onRebookController.stream;
}