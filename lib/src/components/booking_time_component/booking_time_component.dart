// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Stream, StreamController;
import 'package:angular/angular.dart';
import 'package:bokain_models/bokain_models.dart' show Increment;

@Component(
    selector: 'bo-booking-time',
    styleUrls: const ['../calendar_component.css', 'booking_time_component.css'],
    templateUrl: 'booking_time_component.html',
    directives: const [],
    pipes: const [DatePipe],
    changeDetection: ChangeDetectionStrategy.OnPush
)
class BookingTimeComponent implements OnDestroy
{
  BookingTimeComponent();

  void ngOnDestroy()
  {
    selectController.close();
  }

  @Input('isMargin')
  bool isMargin = false;

  @Input('increment')
  Increment increment;

  @Input('duration')
  Duration duration;

  @Output('select')
  Stream<Increment> get select => selectController.stream;

  final StreamController<Increment> selectController = new StreamController();
}