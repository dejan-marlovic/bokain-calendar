// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:html' as dom;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:fo_components/fo_components.dart';
import '../../components/increment_component/increment_component.dart';
import '../../components/day_base/day_base.dart';

@Component(
    selector: 'bo-schedule-day',
    styleUrls: const ['../calendar_component.css', 'schedule_day_component.css'],
    templateUrl: 'schedule_day_component.html',
    directives: const [CORE_DIRECTIVES, FoModalComponent, FoSelectComponent, IncrementComponent, materialDirectives],
    providers: const [DayService],
    pipes: const [DatePipe, PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Stateful
)
class ScheduleDayComponent extends DayBase implements OnChanges, OnDestroy
{
  ScheduleDayComponent(BookingService bs, DayService ds, SalonService ss, UserService us, this._customerService, this._mailService, this._phraseService, this._serviceService) : super(bs, ds, ss, us);

  @override
  void ngOnChanges(Map<String, SimpleChange> changes)
  {
    super.ngOnChanges(changes);

    setState(() => null);
    dayService.onChildAdded.listen((_) => setState(() => null));
  }

  void onIncrementMouseDown(Increment increment)
  {
    if (!dayService.loading && (user != null || salon != null))
    {
      if (!increment.userStates.containsKey(user.id))
      {
        increment.userStates[user.id] = new UserState(user.id);
      }
      UserState us = increment.userStates[user.id];
      if (us.bookingId == null) firstHighlighted = lastHighlighted = increment;
    }
  }

  void onIncrementMouseEnter(dom.MouseEvent e, Increment increment)
  {
    if (!dayService.loading && user != null && salon != null && e.buttons == 1)
    {
      setState(()
      {
        /// User is dragging the mouse and the increment is not booked for the
        /// selected user, highlight the increment
        if (!increment.userStates.containsKey(user.id))
        {
          increment.userStates[user.id] = new UserState(user.id);
        }
        if (increment.userStates[user.id].bookingId == null) lastHighlighted = increment;
        else firstHighlighted = lastHighlighted = null;
      });
    }
  }

  Future applyPreset(SchedulePreset preset) async
  {
    selectedPreset = preset;
    for (Increment i in day.increments)
    {
      i.userStates.remove(user.id);
    }

    DateTime dayStart = new DateTime(day.startTime.year, day.startTime.month, day.startTime.day, preset.dayStartHour);
    DateTime dayEnd = new DateTime(day.startTime.year, day.startTime.month, day.startTime.day, preset.dayEndHour);
    DateTime lunchStart = new DateTime(day.startTime.year, day.startTime.month, day.startTime.day, preset.lunchStartHour);
    DateTime lunchEnd = lunchStart.add(const Duration(minutes: 30));

    Iterable<Increment> morning = day.increments.where((i) =>
    (i.startTime.isAtSameMomentAs(dayStart) || i.startTime.isAfter(dayStart)) && i.startTime.isBefore(lunchStart));

    Iterable<Increment> lunch = day.increments.where((i) =>
    (i.startTime.isAtSameMomentAs(lunchStart) || i.startTime.isAfter(lunchStart)) && i.startTime.isBefore(lunchEnd));

    Iterable<Increment> evening = day.increments.where((i) =>
    (i.startTime.isAtSameMomentAs(lunchEnd) || i.startTime.isAfter(lunchEnd)) && i.startTime.isBefore(dayEnd));

    for (Increment i in morning)
    {
      i.userStates[user.id] = new UserState(user.id)..state = "open";
    }

    for (Increment i in lunch)
    {
      i.userStates[user.id] = new UserState(user.id)..state = "break";
    }

    for (Increment i in evening)
    {
      i.userStates[user.id] = new UserState(user.id)..state = "open";
    }

    if (day.id == null) await dayService.push(day);
    else await dayService.set(day);
    selectedPreset = null;
  }

  Future applyHighlightedChanges() async
  {
    if (!dayService.loading && firstHighlighted != null && lastHighlighted != null && user != null && salon != null)
    {
      await setState(() async
      {
        bool add = firstHighlighted.userStates[user.id].state == null;

        day.increments.where(isHighlighted).forEach((inc)
        {
          /**
           * Make sure a [UserState] is there (if none exists, create it)
           */
          if (!inc.userStates.containsKey(user.id)) inc.userStates[user.id] = new UserState(user.id);
          UserState us = inc.userStates[user.id];

          us.state = (add) ? selectedState : null;

          /**
           * If Userstate.state is set to null, remove it altogether
           */
          if (us.state == null) inc.userStates.remove(user.id);
        });

        if (day.id != null) await dayService.set(day);
        else await dayService.push(day);
        firstHighlighted = lastHighlighted = null;
      });
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

  void setAllDaySick()
  {
    if (dayService.loading || user == null || day == null) return;

    setState(()
    {
      Set<String> bookingIds = new Set();

      /// Get open increments, and update them to state: sick. Store any booking ids for further processing
      for (Increment increment in day.increments.where((i) => i.userStates.containsKey(user.id)))
      {
        increment.userStates[user.id].state = "sick";
        if (increment.userStates[user.id].bookingId != null)
        {
          bookingIds.add(increment.userStates[user.id].bookingId);
          increment.userStates[user.id].bookingId = null;
        }
      }

      /// Cancel all covered bookings
      for (String booking_id in bookingIds)
      {
        Booking booking = super.bookingService.get(booking_id);

        // Generate email
        Customer customer = _customerService.get(booking.customerId);
        Service service = _serviceService.get(booking.serviceId);
        User user = userService.get(booking.userId);
        Salon salon = salonService.get(booking.salonId);

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
        _mailService.mail(_phraseService.get('email_cancel_booking_sick', params: params), _phraseService.get('booking_confirmation'), customer.email);
        bookingService.remove(booking_id);
      }

      dayService.set(day);
      alertVisible = false;
    });
  }

  Increment firstHighlighted, lastHighlighted;
  bool alertVisible = false;
  final CustomerService _customerService;
  final MailerService _mailService;
  final PhraseService _phraseService;
  final ServiceService _serviceService;

  final StringSelectionOptions<SchedulePreset> timePresetOptions = new StringSelectionOptions(
  [
    new SchedulePreset(8, 16),
    new SchedulePreset(10, 18),
    new SchedulePreset(12, 20),
    new SchedulePreset(16, 22),
  ]);
  SchedulePreset selectedPreset;

  @Input('selectedState')
  String selectedState = "open";
}

class SchedulePreset extends FoModel
{
  SchedulePreset(this.dayStartHour, this.dayEndHour) : lunchStartHour = dayStartHour + 3, super("$dayStartHour-$dayEndHour");

  final int dayStartHour;
  final int lunchStartHour;
  final int dayEndHour;


}


