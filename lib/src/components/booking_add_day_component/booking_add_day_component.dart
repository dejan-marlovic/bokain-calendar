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
    providers: const [CalendarService],
    pipes: const [DatePipe, PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class BookingAddDayComponent extends DayBase implements OnChanges, OnDestroy, AfterContentInit
{
  BookingAddDayComponent(BookingService bs, CalendarService cs, SalonService ss, UserService us) : super(bs, cs, ss, us);

  @override ngOnChanges(Map<String, SimpleChange> changes)
  {
    super.ngOnChanges(changes);

    totalDuration = (selectedService == null) ? const Duration(seconds: 1) : new Duration(minutes: selectedService.durationMinutes);
    if (selectedServiceAddons != null)
    {
      for (ServiceAddon addon in selectedServiceAddons)
      {
        totalDuration += addon.duration;
      }
    }
    salonServiceRooms = _getQualifiedRoomsOfSalonAndService(selectedSalon, selectedService).toList(growable: false);
    qualifiedIncrements = [];
  }

  @override
  void ngOnDestroy()
  {
    super.ngOnDestroy();
    onTimeSelectController.close();
  }

  @override
  void updateDayRemote(Day d)
  {
    super.updateDayRemote(d);
    qualifiedIncrements = _calcQualifiedIncrements().toList(growable: false);
  }

  bool isMargin(Increment increment) => (selectedUser == null) ? false : increment.userStates[selectedUser.id].state == "margin";

  void makeBooking(Increment increment)
  {
    if (!calendarService.loading)
    {
      Iterable<String> qualifiedUserIds = (selectedUser == null) ? _getQualifiedUserIdsForIncrement(increment) : [selectedUser.id];
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
      List<User> qualifiedUsers = userService.getModelsAsList(qualifiedUserIds.toList(growable: false));
      qualifiedUsers.sort((user1, user2) => (user2.bookingRank - user1.bookingRank).toInt());
      qualifiedUsers.removeWhere((u) => u.bookingRank < qualifiedUsers.first.bookingRank);

      Random rnd = new Random(new DateTime.now().millisecondsSinceEpoch);
      booking.userId = qualifiedUsers[rnd.nextInt(qualifiedUsers.length)].id;

      booking.roomId = rooms.first;

      increment.userStates[booking.userId].state = "open";
      calendarService.save(day);
      onTimeSelectController.add(booking);
    }
  }

  Iterable<Increment> _calcQualifiedIncrements()
  {
    if (day == null || day.increments.isEmpty || selectedSalon == null) return [];
    try
    {
      return day.increments.where(_available);
    }
    on StateError catch(e)
    {
      print(e);
      return [];
    }
  }

  bool _available(Increment increment)
  {
    if (selectedService == null) return false;
    DateTime startTime = increment.startTime;
    DateTime endTime = increment.startTime.add(totalDuration + selectedService.afterMargin);

    /// Broad phase check
    if (startTime.isBefore(new DateTime.now()) || endTime.isAfter(day.endTime.add(selectedService.afterMargin))) return false;

    Iterable<String> userIds = (selectedUser == null) ? _getQualifiedUserIdsForIncrement(increment) : [selectedUser.id];
    Iterable<String> roomIds = _getQualifiedRoomIdsForIncrement(increment);
    if (userIds.isEmpty || roomIds.isEmpty) return false;

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
        if (userIds.isEmpty || roomIds.isEmpty) return false;                   /// No users left or no rooms left
      }
      previousEndTime = i.endTime;
    }
    return true;
  }

  Iterable<Room> _getQualifiedRoomsOfSalonAndService(Salon salon, Service service)
  {
    if (salon == null || service == null) return [];
    return salonService.getRooms(salon.roomIds).where((room) => room.serviceIds.contains(service.id) && room.status == "active");
  }

  Iterable<String> _getQualifiedRoomIdsForIncrement(Increment increment)
  {
    if (selectedService == null) return [];

    Iterable<Room> qualifiedRooms = salonServiceRooms.where((room) => bookingService.find(increment.startTime, room.id) == null);
    return qualifiedRooms.map((r) => r.id);
  }

  Iterable<String> _getQualifiedUserIdsForIncrement(Increment increment)
  {
    if (selectedService == null) return [];

    /// No user selected, return all qualified
    if (selectedUser == null)
    {
      return increment.userStates.keys.where((id) =>
          selectedService.userIds.contains(id) &&
          (increment.userStates[id].bookingId == null && increment.userStates[id].state == "open") ||
          (includeMargins && increment.userStates[id].state == "margin"));
    }
    else
    {
      if (!increment.userStates.containsKey(selectedUser.id)) return [];
      UserState us = increment.userStates[selectedUser.id];
      return ((us.bookingId == null && us.state == "open") || (includeMargins && us.state == "margin")) ? [selectedUser.id] : [];
    }
  }

  String selectedRoomId;
  final StreamController<Booking> onTimeSelectController = new StreamController();
  List<Increment> qualifiedIncrements = new List();
  Duration totalDuration = new Duration(seconds: 1);
  List<Room> salonServiceRooms = [];

  @Input('date')
  @override
  void set date(DateTime value) { super.date = value; }
  
  @Input('salon')
  void set salon(Salon value) { super.selectedSalon = value; }

  @Input('service')
  Service selectedService;

  @Input('serviceAddons')
  List<ServiceAddon> selectedServiceAddons;

  @Input('user')
  void set user(User value) { super.selectedUser = value; }

  @Input('includeMargins')
  bool includeMargins = true;

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;

  @Output('timeSelect')
  Stream<Booking> get onTimeSelect => onTimeSelectController.stream;
}


