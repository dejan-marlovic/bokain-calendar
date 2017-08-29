// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController;
import 'package:angular2/angular2.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart' show Booking, Salon, Service, ServiceAddon, User;
import 'package:bokain_calendar/src/components/booking_add_day_component/booking_add_day_component.dart';
import 'package:bokain_calendar/src/components/week_base/week_base.dart';

@Component(
    selector: 'bo-booking-add-week',
    styleUrls: const ['../calendar_component.css', '../week_base/week_base.css', 'booking_add_week_component.css'],
    templateUrl: 'booking_add_week_component.html',
    directives: const [materialDirectives, BookingAddDayComponent],
    pipes: const [DatePipe, PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class BookingAddWeekComponent extends WeekBase implements OnDestroy
{
  BookingAddWeekComponent() : super();

  void ngOnDestroy()
  {
    super.ngOnDestroy();
    onTimeSelectController.close();
  }

  @Input('user')
  void set user(User value) { super.selectedUser = value; }

  @Input('salon')
  void set salon(Salon value) { super.selectedSalon = value; }

  @Input('service')
  Service service;

  @Input('serviceAddons')
  List<ServiceAddon> serviceAddons = [];

  @Input('totalDuration')
  Duration totalDuration = new Duration(seconds: 1);

  @Input('date')
  @override
  void set date(DateTime value) { super.date = value; }

  @Input('includeMargins')
  bool includeMargins = true;

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;

  @Output('timeSelect')
  Stream<Booking> get onTimeSelectOutput => onTimeSelectController.stream;

  Booking bufferBooking;
  String selectedRoomId;
  final StreamController<Booking> onTimeSelectController = new StreamController();
}


