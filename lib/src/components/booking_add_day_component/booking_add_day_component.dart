// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController;
import 'dart:math';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:bokain_calendar/src/components/increment_component/increment_component.dart';
import 'package:bokain_calendar/src/components/booking_time_component/booking_time_component.dart';
import 'package:bokain_calendar/src/components/day_base/day_base.dart';

@Component(
    selector: 'bo-booking-add-day',
    styleUrls: const ['../calendar_component.css', 'booking_add_day_component.css'],
    templateUrl: 'booking_add_day_component.html',
    directives: const [BookingTimeComponent, CORE_DIRECTIVES, IncrementComponent, materialDirectives],
    providers: const [DayService],
    pipes: const [DatePipe, PhrasePipe]
)
class BookingAddDayComponent extends DayBase implements OnInit, OnChanges, OnDestroy
{
  BookingAddDayComponent(BookingService bs, DayService ds, SalonService ss, UserService us) : super(bs, ds, ss, us);

  @override ngOnChanges(Map<String, SimpleChange> changes)
  {
    super.ngOnChanges(changes);
    if (changes.containsKey("salon") || changes.containsKey("service") || changes.containsKey("serviceAddons"))
    {
      totalDuration = (service == null) ? const Duration(seconds: 1) : new Duration(minutes: service.durationMinutes);
      if (serviceAddons != null)
      {
        for (ServiceAddon addon in serviceAddons)
        {
          totalDuration += addon.duration;
        }
      }
      if (service != null && salon != null)
      {
        /**
         * Figure out which rooms are qualified for the selected salon and service
         */
        salonServiceRooms = salonService.getRooms(salon.roomIds).where((room) => room.serviceIds.contains(service.id) && room.status == "active").toList(growable: false);
      }
    }
  }

  @override
  void ngOnDestroy()
  {
    super.ngOnDestroy();
    onTimeSelectController.close();
  }

  bool isMargin(Increment increment) => (user == null) ? false : increment.userStates[user.id].state == "margin";

  void makeBooking(Increment increment)
  {
    if (!dayService.loading)
    {
      Iterable<String> qualifiedUserIds = (user == null) ? _getQualifiedUserIdsForIncrement(increment) : [user.id];
      Iterable<String> rooms = _getQualifiedRoomIdsForIncrement(increment);
      if (qualifiedUserIds.isEmpty || rooms.isEmpty) return;

      Booking booking = new Booking();
      booking.startTime = increment.startTime;
      booking.endTime = booking.startTime.add(totalDuration);
      booking.dayId = day.id;

      /**
       * Filter so that higher ranked users always gets bookings if available. Then select a random user out of the qualified ones
       * of the highest rank (if a user has been selected by the customer, there will only be one user in the list)
       */
      List<User> qualifiedUsers = userService.getMany(qualifiedUserIds.toList(growable: false)).values.toList();
      qualifiedUsers.sort((user1, user2) => (user2.bookingRank - user1.bookingRank).toInt());
      qualifiedUsers.removeWhere((u) => u.bookingRank < qualifiedUsers.first.bookingRank);

      Random rnd = new Random(new DateTime.now().millisecondsSinceEpoch);
      booking.userId = qualifiedUsers[rnd.nextInt(qualifiedUsers.length)].id;

      booking.roomId = rooms.first;

      increment.userStates[booking.userId].state = "open";
      dayService.set(day.id, day);
      onTimeSelectController.add(booking);
    }
  }

  Iterable<Increment> get qualifiedIncrements
  {
    if (day == null || salon == null || service == null) return [];
    return day.increments.where(_available);
  }

  bool _available(Increment increment)
  {
    DateTime startTime = increment.startTime;
    DateTime endTime = increment.startTime.add(totalDuration + service.afterMargin);

    /// Broad phase check
    if (startTime.isBefore(new DateTime.now()))
    {
      //print("This time is in the past: $startTime");
      return false;
    }
    if (endTime.isAfter(day.endTime.add(service.afterMargin)))
    {
      //print("No time left today: $endTime");
      return false;
    }

    Iterable<String> userIds = (user == null) ? _getQualifiedUserIdsForIncrement(increment) : [user.id];
    Iterable<String> roomIds = _getQualifiedRoomIdsForIncrement(increment);
    if (userIds.isEmpty)
    {
      //print("No users are qualified for increment $startTime");
      return false;
    }
    if (roomIds.isEmpty)
    {
      //print("No rooms are qualified for increment $startTime");
      return false;
    }

    DateTime previousEndTime;

    /// Make sure all increments covered by the service's duration is available
    ///
    Iterable<Increment> durationCoveredIncrements = day.increments.where((di) =>
      di.startTime.isBefore(endTime) && di.endTime.isAfter(startTime));

    for (Increment i in durationCoveredIncrements)
    {
      if (previousEndTime != null && !i.startTime.isAtSameMomentAs(previousEndTime)) return false;       /// Time is not continuous
      else
      {
        userIds = _getQualifiedUserIdsForIncrement(i).where(userIds.contains);
        roomIds = _getQualifiedRoomIdsForIncrement(i).where(roomIds.contains);

        if (userIds.isEmpty)
        {
          //print("No users left for increment $startTime");
          return false;
        }
        else if (roomIds.isEmpty)
        {
          //print("No rooms left for increment $startTime");
          return false;
        }
      }
      previousEndTime = i.endTime;
    }

    //print("Available increment found: $startTime");
    return true;
  }

  Iterable<String> _getQualifiedRoomIdsForIncrement(Increment increment)
  {
    Iterable<Room> qualifiedRooms = salonServiceRooms.where((room) => bookingService.findCached(increment.startTime, room.id) == null);
    return qualifiedRooms.map((r) => r.id);
  }

  Iterable<String> _getQualifiedUserIdsForIncrement(Increment increment)
  {
    /// No user selected, return all qualified
    if (user == null)
    {
      return increment.userStates.keys.where((id) =>
          service.userIds.contains(id) &&
          (increment.userStates[id].bookingId == null && increment.userStates[id].state == "open") ||
          (includeMargins && increment.userStates[id].state == "margin"));
    }
    else
    {
      if (!increment.userStates.containsKey(user.id)) return [];
      UserState us = increment.userStates[user.id];
      return ((us.bookingId == null && us.state == "open") || (includeMargins && us.state == "margin")) ? [user.id] : [];
    }
  }

  String selectedRoomId;
  final StreamController<Booking> onTimeSelectController = new StreamController();
  //List<Increment> qualifiedIncrements = new List();
  Duration totalDuration = new Duration(seconds: 1);
  List<Room> salonServiceRooms = [];

  @Input('service')
  Service service;

  @Input('serviceAddons')
  List<ServiceAddon> serviceAddons;

  @Input('includeMargins')
  bool includeMargins = true;

  @Output('timeSelect')
  Stream<Booking> get onTimeSelect => onTimeSelectController.stream;
}


