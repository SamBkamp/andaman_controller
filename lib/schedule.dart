import 'doser_page.dart';

enum ScheduleType {
  periodic,
  daily,
}

class Schedule {
  ScheduleType type;
  String ml;
  String period;

  Schedule(
    this.type,
    this.ml, {
      this.period = "0",
  });

}
