// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:bokain_models/bokain_models.dart' show Day;
import 'package:angular2/angular2.dart';

@Component(
    selector: 'bo-times',
    styleUrls: const ['../calendar_component.css', 'times_component.css'],
    templateUrl: 'times_component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
)
class TimesComponent
{
  TimesComponent();

  bool isBeforeNow(DateTime dt) => dt.isBefore(new DateTime.now());

  final Day day = new Day(null, null, new DateTime.now());
}


