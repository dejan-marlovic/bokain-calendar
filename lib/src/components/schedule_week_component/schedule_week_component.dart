// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream;
import 'package:angular2/angular2.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';
import 'package:bokain_calendar/src/components/increment_component/increment_component.dart';
import 'package:bokain_calendar/src/components/schedule_day_component/schedule_day_component.dart';
import 'package:bokain_calendar/src/components/week_base/week_base.dart';

@Component(
    selector: 'bo-schedule-week',
    styleUrls: const ['../calendar_component.css', '../week_base/week_base.css', 'schedule_week_component.css'],
    templateUrl: 'schedule_week_component.html',
    directives: const
    [
      materialDirectives,
      IncrementComponent,
      ScheduleDayComponent,
    ],
    pipes: const [PhrasePipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class ScheduleWeekComponent extends WeekBase implements OnDestroy
{
  ScheduleWeekComponent() : super();

  @Input('date')
  @override
  void set date(DateTime value) { super.date = value; }

  @Input('user')
  void set user(User value) { selectedUser = value; }

  @Input('salon')
  void set salon(Salon value) { selectedSalon = value; }

  @Input('selectedState')
  String selectedState = "open";

  @Output('dateClick')
  Stream<DateTime> get onDateClickOutput => onDateClickController.stream;
}