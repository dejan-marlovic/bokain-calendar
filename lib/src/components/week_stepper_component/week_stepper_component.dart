// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;
import 'package:angular2/angular2.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_calendar/src/pipes/week_pipe.dart';

@Component(
    selector: 'bo-week-stepper',
    styleUrls: const ['week_stepper_component.css'],
    templateUrl: 'week_stepper_component.html',
    directives: const [materialDirectives],
    pipes: const [PhrasePipe, WeekPipe],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class WeekStepperComponent implements OnDestroy
{
  WeekStepperComponent();

  void ngOnDestroy()
  {
    _onDateChangeController.close();
  }

  Future advanceWeek(int week_count) async
  {
    date = weekDates[0].add(new Duration(days: 7 * week_count));
  }

  void _updateSurroundingDates()
  {
    surroundingDates.clear();
    DateTime first = weekDates.first.add(const Duration(days: -7 * 4));
    DateTime last = weekDates.first.add(const Duration(days: 7 * 4));
    DateTime iDate = first;

    while (iDate.isBefore(last))
    {
      surroundingDates.add(iDate);
      iDate = iDate.add(const Duration(days: 7));
    }
  }

  DateTime get date => weekDates.first;

  void set date(DateTime value)
  {
    for (int i = 0; i < 7; i++)
    {
      weekDates[i] = value.add(new Duration(days: i));
    }
    _updateSurroundingDates();
    _onDateChangeController.add(weekDates.first);
  }

  List<DateTime> surroundingDates = new List();
  List<DateTime> weekDates = new List(7);
  final StreamController<DateTime> _onDateChangeController = new StreamController();

  @Input('date')
  void set dateExternal(DateTime value)
  {
    DateTime iDate = new DateTime(value.year, value.month, value.day, 12);

    // Monday
    iDate = new DateTime(iDate.year, iDate.month, iDate.day - (iDate.weekday - 1), 12);
    for (int i = 0; i < 7; i++)
    {
      weekDates[i] = iDate;
      iDate = iDate.add(const Duration(days: 1));
    }
    _updateSurroundingDates();
  }

  @Output('dateChange')
  Stream<DateTime> get onDateChangeOutput => _onDateChangeController.stream;
}