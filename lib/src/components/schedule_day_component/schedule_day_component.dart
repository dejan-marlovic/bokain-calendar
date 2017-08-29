// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream;
import 'dart:html' as dom;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_calendar/src/components/increment_component/increment_component.dart';
import 'package:bokain_calendar/src/components/day_base/day_base.dart';

@Component(
    selector: 'bo-schedule-day',
    styleUrls: const ['../calendar_component.css', 'schedule_day_component.css'],
    templateUrl: 'schedule_day_component.html',
    directives: const [CORE_DIRECTIVES, FoModalComponent, IncrementComponent, materialDirectives],
    providers: const [CalendarService],
    pipes: const [DatePipe, PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class ScheduleDayComponent extends DayBase implements OnChanges, OnDestroy, AfterContentInit
{
  ScheduleDayComponent(BookingService bs, CalendarService cs, SalonService ss, UserService us, this._customerService, this._mailService, this._phraseService, this._serviceService) : super(bs, cs, ss, us);

  void onIncrementMouseDown(Increment increment)
  {
    if (!calendarService.loading && (selectedUser != null || selectedSalon != null))
    {
      if (!increment.userStates.containsKey(selectedUser.id))
      {
        increment.userStates[selectedUser.id] = new UserState(selectedUser.id);
      }
      UserState us = increment.userStates[selectedUser.id];
      if (us.bookingId == null) firstHighlighted = lastHighlighted = increment;
    }
  }

  void onIncrementMouseEnter(dom.MouseEvent e, Increment increment)
  {
    if (!calendarService.loading && selectedUser != null && selectedSalon != null && e.buttons == 1)
    {
      /// User is dragging the mouse and the increment is not booked for the
      /// selected user, highlight the increment
      if (!increment.userStates.containsKey(selectedUser.id))
      {
        increment.userStates[selectedUser.id] = new UserState(selectedUser.id);
      }
      if (increment.userStates[selectedUser.id].bookingId == null) lastHighlighted = increment;
      else firstHighlighted = lastHighlighted = null;
    }
  }

  Future applyHighlightedChanges() async
  {
    if (!calendarService.loading && firstHighlighted != null && lastHighlighted != null && selectedUser != null && selectedSalon != null)
    {
      bool add = firstHighlighted.userStates[selectedUser.id].state == null;

      day.increments.where(isHighlighted).forEach((inc)
      {
        /**
         * Make sure a [UserState] is there (if none exists, create it)
         */
        if (!inc.userStates.containsKey(selectedUser.id)) inc.userStates[selectedUser.id] = new UserState(selectedUser.id);
        UserState us = inc.userStates[selectedUser.id];

        us.state = (add) ? selectedState : null;

        /**
         * If Userstate.state is set to null, remove it altogether
         */
        if (us.state == null) inc.userStates.remove(selectedUser.id);
      });
      calendarService.save(day).then((_) => firstHighlighted = lastHighlighted = null);
    }
  }

  bool isHighlighted(Increment i)
  {
    if (firstHighlighted == null || lastHighlighted == null) return false;

    if (firstHighlighted.startTime.isBefore(lastHighlighted.startTime))
    {
      return (i.startTime.isAfter(firstHighlighted.startTime) || i.startTime.isAtSameMomentAs(firstHighlighted.startTime)) &&
          (i.endTime.isBefore(lastHighlighted.endTime) || i.endTime.isAtSameMomentAs(lastHighlighted.endTime));
    }
    else
    {
      return (i.startTime.isAfter(lastHighlighted.startTime) || i.startTime.isAtSameMomentAs(lastHighlighted.startTime)) &&
          (i.endTime.isBefore(firstHighlighted.endTime) || i.endTime.isAtSameMomentAs(firstHighlighted.endTime));
    }
  }

  Future setAllDaySick() async
  {
    if (calendarService.loading || selectedUser == null || day == null) return;

    Set<String> bookingIds = new Set();

    /// Get open increments, and update them to state: sick. Store any booking ids for further processing
    for (Increment increment in day.increments.where((i) => i.userStates.containsKey(selectedUser.id)))
    {
      increment.userStates[selectedUser.id].state = "sick";
      if (increment.userStates[selectedUser.id].bookingId != null)
      {
        bookingIds.add(increment.userStates[selectedUser.id].bookingId);
        increment.userStates[selectedUser.id].bookingId = null;
      }
    }

    /// Cancel all covered bookings
    for (String booking_id in bookingIds)
    {
      Booking booking = super.bookingService.getModel(booking_id);

      // Generate email
      Customer customer = _customerService.getModel(booking.customerId);
      Service service = _serviceService.getModel(booking.serviceId);
      User user = userService.getModel(booking.userId);
      Salon salon = salonService.getModel(booking.salonId);

      Map<String, String> params = new Map();
      params["service_name"] = service.name;
      params["customer_firstname"] = customer.firstname;
      params["user_name"] = "${user.firstname} ${user.lastname}";
      params["salon_name"] = salon.name;
      params["salon_address"] = "${salon.street}, ${salon.postalCode}, ${salon.city}";
      params["salon_phone"] = salon.phone;
      params["date"] = _mailService.formatDatePronounced(booking.startTime);
      params["start_time"] = _mailService.formatHM(booking.startTime);
      params["end_time"] = _mailService.formatHM(booking.endTime);
      await _mailService.mail(_phraseService.get('email_cancel_booking_sick', params: params), _phraseService.get('booking_confirmation'), customer.email);
      await bookingService.remove(booking_id);
    }

    await calendarService.save(day);
    alertVisible = false;
  }

  Increment firstHighlighted, lastHighlighted;
  bool alertVisible = false;
  final CustomerService _customerService;
  final MailerService _mailService;
  final PhraseService _phraseService;
  final ServiceService _serviceService;

  @Input('selectedState')
  String selectedState = "open";

  @Input('user')
  void set user(User value) { selectedUser = value; }

  @Input('salon')
  void set salon(Salon value) { selectedSalon = value; }

  @Input('date')
  void set date(DateTime value) { super.date = value; }

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;
}


