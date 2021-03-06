// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:intl/intl.dart' show DateFormat;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart' show MaterialIconComponent;
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';
import '../../components/increment_component/increment_component.dart';

@Component(
    selector: 'bo-increment-group',
    styleUrls: const ['../calendar_component.css', 'increment_group_component.css'],
    templateUrl: 'increment_group_component.html',
    directives: const [CORE_DIRECTIVES, IncrementComponent, MaterialIconComponent],
)
class IncrementGroupComponent extends ComponentState implements OnInit, OnDestroy
{
  IncrementGroupComponent(this.bookingService, this.serviceService, this.customerService, this._phraseService)
  {
    timer = new Timer.periodic(const Duration(minutes:1), (t) => now = new DateTime.now());
  }

  void ngOnInit()
  {
    if (increments.isEmpty) return;
    Increment i = increments.first;
    UserState us = i.userStates.containsKey(userId) ? i.userStates[userId] : null;

    if (us != null)
    {
      bookingService.fetch(us.bookingId).then((b)
      {
        setState(()
        {
          booking = b;
          if (booking != null)
          {
            customer = customerService.get(booking.customerId);
            service = serviceService.get(booking.serviceId);
          }
        });
      });

      calendarState = us.state;
    }
  }

  void ngOnDestroy()
  {
    onBookingClickController.close();
    timer.cancel();
  }

  String outputRow(int i)
  {
    switch (i)
    {
      case 0:
        return hm.format(increments.first.startTime) + " - " + hm.format(increments.last.endTime);
        break;

      case 1:
        return (service == null) ? _phraseService.get(calendarState) : service.name;
        break;

      case 2:
        return (customer == null) ? "" : "${customer.firstname} ${customer.lastname}";
        break;

      default:
        return "";
        break;
    }
  }

  String getColor(Increment i) => (i.startTime.isBefore(now)) ? "rgba(0,0,0,0.2)" : "transparent";

  String get backgroundColor
  {
    if (service != null) return service.color;

    switch (calendarState)
    {
      case "break":
        return "rgba(1,167,157,1)";
        break;

      case "open":
        return "rgba(1,167,157,0.6)";
        break;

      case "sick":
        return "palevioletred";
        break;

      default:
        return "#eee";
        break;
    }
  }

  String get color => (calendarState == null) ? "#888" : "white";

  bool get star => (booking != null);
  bool get plus => (booking != null);

  final BookingService bookingService;
  final ServiceService serviceService;
  final CustomerService customerService;
  final PhraseService _phraseService;
  final StreamController<Booking> onBookingClickController = new StreamController();
  Timer timer;

  Booking booking;
  Customer customer;
  Service service;
  String calendarState;

  @Input('increments')
  List<Increment> increments = new List();

  @Input('userId')
  String userId;

  @Output('click')
  Stream<Booking> get onBookingClickOutput => onBookingClickController.stream;

  DateFormat hm = new DateFormat.Hm();
  DateTime now = new DateTime.now();

}