// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;
import 'package:angular2/angular2.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';

@Component(
    selector: 'bo-day-stepper',
    styleUrls: const ['day_stepper_component.css'],
    templateUrl: 'day_stepper_component.html',
    directives: const [materialDirectives],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class DayStepperComponent implements OnDestroy
{
  DayStepperComponent(this.phraseService);

  void ngOnDestroy()
  {
    _onDateChangeController.close();
  }

  Future advance(int day_count) async
  {
    date = date.add(new Duration(days: day_count));
  }

  void _updateSurroundingDates()
  {
    surroundingDates.clear();
    DateTime first = date.add(const Duration(days: -6));
    DateTime last = date.add(const Duration(days: 7));
    DateTime iDate = first;

    while (iDate.isBefore(last))
    {
      surroundingDates.add(iDate);
      iDate = iDate.add(const Duration(days: 1));
    }
  }

  DateTime get date => _date;

  void set date(DateTime value)
  {
    _date = value;
    _updateSurroundingDates();

    _onDateChangeController.add(_date);
  }

  DateTime _date = new DateTime.now();
  List<DateTime> surroundingDates = new List();
  final PhraseService phraseService;
  final StreamController<DateTime> _onDateChangeController = new StreamController();

  @Output('dateChange')
  Stream<DateTime> get onDateChangeOutput => _onDateChangeController.stream;

  @Input('date')
  void set dateExternal(DateTime value)
  {
    _date = value;
    _updateSurroundingDates();
  }
}