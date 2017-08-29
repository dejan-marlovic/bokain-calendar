import 'package:angular2/angular2.dart';

@Pipe("week")
class WeekPipe implements PipeTransform
{
  WeekPipe();

  int transform(DateTime value)
  {
    DateTime mondayDate = value.add(new Duration(days:-(value.weekday-1)));
    DateTime firstMondayOfYear = new DateTime(value.year);
    while (firstMondayOfYear.weekday != 1) firstMondayOfYear = firstMondayOfYear.add(const Duration(days:1));
    Duration difference = mondayDate.difference(firstMondayOfYear);
    return (difference.inDays ~/ 7).toInt() + 1;
  }
}