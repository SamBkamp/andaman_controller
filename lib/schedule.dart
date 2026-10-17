import 'doser_page.dart';

enum ScheduleType {
  periodic,
  continuous,
  timed
}

class TimedScheduleEntry {
  int hours;
  int minutes;
  double amount;

  TimedScheduleEntry({
      this.hours = 0,
      this.minutes = 0,
      this.amount = 0.0
  });

}

class Schedule {
  ScheduleType type;
  String ml;
  String period;
  List<TimedScheduleEntry> entries = [];

  Schedule(
    this.type,
    this.ml, {
      this.period = "0",
  });

}
