// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular/angular.dart';
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
    directives: const [CORE_DIRECTIVES, IncrementGroupComponent, materialDirectives, TimesComponent],
    pipes: const [DatePipe, PhrasePipe],
    providers: const [DayService],
    changeDetection: ChangeDetectionStrategy.Stateful
)
class BookingViewDayComponent extends DayBase implements OnChanges, OnInit, OnDestroy
{
  BookingViewDayComponent(BookingService bs, DayService ds, SalonService ss, UserService us) : super(bs, ds, ss, us);

  @override
  void ngOnInit()
  {
    _dayAddedListener = dayService.onChildAdded.listen((_) => _groupIncrements());
    _dayUpdatedListener = dayService.onChildUpdated.listen((_) => _groupIncrements());
    _dayRemovedListener = dayService.onChildRemoved.listen((_) => _groupIncrements());

    _groupIncrements();
  }

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

    _dayAddedListener.cancel();
    _dayUpdatedListener.cancel();
    _dayRemovedListener.cancel();
  }

  void onIncrementMouseDown(Increment increment)
  {
    if (!dayService.loading && (user != null || salon != null))
    {
      if (increment.userStates.containsKey(user.id))
      {
        UserState us = increment.userStates[user.id];
        if (us.bookingId != null) onBookingSelectController.add(bookingService.get(increment.userStates[user.id].bookingId));
      }
    }
  }

  void _groupIncrements()
  {
    setState(()
    {
      incrementGroups = new List();
      if (day == null || user == null || salon == null) return;

      incrementGroups.add([day.increments.first]);

      for (int i = 1; i < day.increments.length; i++)
      {
        Increment previous = day.increments[i-1];
        Increment current = day.increments[i];
        UserState us = current.userStates.containsKey(user.id) ? current.userStates[user.id] : null;

        if (us != null && us.state != null && (us.bookingId != null || us.state != 'open') && us == previous.userStates[user.id])
        {
          incrementGroups.last.add(current);
        }
        else incrementGroups.add([current]);
      }
    });
  }

  StreamSubscription<Day> _dayAddedListener;
  StreamSubscription<Day> _dayUpdatedListener;
  StreamSubscription<String> _dayRemovedListener;

  final StreamController<Booking> onBookingSelectController = new StreamController();
  List<List<Increment>> incrementGroups = new List();

  @Output('bookingSelect')
  Stream<Booking> get onBookingSelectOutput => onBookingSelectController.stream;
}


