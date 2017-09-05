// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

//import 'dart:async' show Stream;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
//import 'package:bokain_models/bokain_models.dart';
import 'package:bokain_calendar/src/components/increment_component/increment_component.dart';
import 'package:bokain_calendar/src/components/schedule_day_component/schedule_day_component.dart';
import 'package:bokain_calendar/src/components/week_base/week_base.dart';
import 'package:bokain_calendar/src/pipes/week_pipe.dart';

@Component(
    selector: 'bo-schedule-week',
    styleUrls: const ['../calendar_component.css', '../week_base/week_base.css', 'schedule_week_component.css'],
    templateUrl: 'schedule_week_component.html',
    directives: const
    [
      CORE_DIRECTIVES,
      IncrementComponent,
      materialDirectives,
      ScheduleDayComponent,
    ],
    pipes: const [DatePipe, PhrasePipe, WeekPipe],
    changeDetection: ChangeDetectionStrategy.Default
)
class ScheduleWeekComponent extends WeekBase implements OnDestroy
{
  ScheduleWeekComponent() : super();

  @Input('selectedState')
  String selectedState = "open";
}