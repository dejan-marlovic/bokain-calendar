// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController;

import 'package:angular2/angular2.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:bokain_calendar/src/components/increment_group_component/increment_group_component.dart';
import 'package:bokain_calendar/src/components/times_component/times_component.dart';
import 'package:bokain_calendar/src/components/day_base/day_base.dart';

@Component(
    selector: 'bo-booking-view-day',
    styleUrls: const ['../calendar_component.css', 'booking_view_day_component.css'],
    templateUrl: 'booking_view_day_component.html',
    directives: const [materialDirectives, IncrementGroupComponent, TimesComponent],
    providers: const [CalendarService],
    pipes: const [PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class BookingViewDayComponent extends DayBase implements OnChanges, OnDestroy, AfterContentInit
{
  BookingViewDayComponent(BookingService bs, CalendarService cs, SalonService ss, UserService us) : super(bs, cs, ss, us);

  @override
  ngOnChanges(Map<String, SimpleChange> changes)
  {
    super.ngOnChanges(changes);
    _groupIncrements();
  }

  @override
  void ngOnDestroy()
  {
    super.ngOnDestroy();
    onBookingSelectController.close();
  }

  void onIncrementMouseDown(Increment increment)
  {
    if (!calendarService.loading && (selectedUser != null || selectedSalon != null))
    {
      if (increment.userStates.containsKey(selectedUser.id))
      {
        UserState us = increment.userStates[selectedUser.id];
        if (us.bookingId != null)
        {
          onBookingSelectController.add(bookingService.getModel(increment.userStates[selectedUser.id].bookingId));
        }
      }
    }
  }

  @override
  void updateDayRemote(Day d)
  {
    super.updateDayRemote(d);
    _groupIncrements();
  }

  void _groupIncrements()
  {
    incrementGroups.clear();
    if (day == null || selectedUser == null) return;

    incrementGroups.add(new List()..add(day.increments.first));

    for (int i = 1; i < day.increments.length; i++)
    {
      Increment previous = day.increments[i-1];
      Increment current = day.increments[i];

      UserState us = current.userStates.containsKey(selectedUser.id) ? current.userStates[selectedUser.id] : null;

      if (us != null && us.state != null && (us.bookingId != null || us.state != 'open') && us == previous.userStates[selectedUser.id])
      {
        incrementGroups.last.add(current);
      }
      else incrementGroups.add(new List()..add(current));
    }
  }

  final StreamController<Booking> onBookingSelectController = new StreamController();
  final List<List<Increment>> incrementGroups = new List();

  @Input('user')
  void set user(User value) { super.selectedUser = value; }

  @Input('salon')
  void set salon(Salon value) { super.selectedSalon = value; }

  @Input('date')
  @override
  void set date(DateTime value) { super.date = value; }

  @Output('bookingSelect')
  Stream<Booking> get onBookingSelectOutput => onBookingSelectController.stream;

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;
}


