import 'package:flutter/material.dart';
import 'device.dart';
import 'theme_data.dart';
import 'schedule.dart';

class TimedSchedulePage extends StatefulWidget {
  final DoserDevice device;
  final Theme_data theme;
  final Schedule sched;

  const TimedSchedulePage({
      super.key,
      required this.device,
      required this.theme,
      required this.sched
  });

  @override
  State<TimedSchedulePage> createState() => _TimedSchedulePageState();
}

class _TimedSchedulePageState extends State<TimedSchedulePage> {
  int hours = 0;
  int minutes = 0;
  int MAX_ENTRIES = 16;

  final schedule_dosage_controller = TextEditingController();


  @override
  void initState(){
    super.initState();
  }


  Widget time_picker_column({
      required int value,
      required int max_value,
      required ValueChanged<int> on_changed,
  }) {
    return SizedBox(
      height: 120,
      width: 65,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: value,
        ),
        onSelectedItemChanged: on_changed,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max_value + 1,
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 20),
              ),
            );
          },
        ),
      ),
    );
  }


  void schedule_node_popup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Time and amount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                time_picker_column(
                  value: hours,
                  max_value: 23,
                  on_changed: (value){
                    setState(() => hours = value);
                  },
                ),
                const Text(":"),
                time_picker_column(
                  value: minutes,
                  max_value: 59,
                  on_changed: (value) {
                    setState(() => minutes = value);
                  },
                ),
                SizedBox(width: 20),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: schedule_dosage_controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  )
                ),
                Text("ml"),
              ]
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: (){
                  double? amount = double.tryParse(schedule_dosage_controller.text);
                  if(amount == null || amount < 1) return;

                  setState(() {
                      widget.sched.entries.add(TimedScheduleEntry(
                          hours: hours,
                          minutes: minutes,
                          amount: amount));
                  });
                  Navigator.pop(context);
                },
                child: Text("Add")
              )
            )
          ]
        )
      ),
    );
  }


  Widget schedule_hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          widget.theme.title_text("Schedule"),
          const Spacer(),
          IconButton(
            onPressed: () {
              if(widget.sched.entries.length < MAX_ENTRIES)
              schedule_node_popup();
            },
            icon: const Icon(Icons.add_circle_outline),
            color: widget.sched.entries.length >= MAX_ENTRIES
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget schedule_entry_tile(TimedScheduleEntry entry) {
    return ListTile(
      title: Text(
        '${entry.hours.toString().padLeft(2, '0')}:'
        '${entry.minutes.toString().padLeft(2, '0')}',
      ),
      subtitle: Text('${entry.amount} ml'),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          setState((){
              widget.sched.entries.remove(entry);
          });
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body:ListView(
        children: [
          schedule_hero(context),
          const SizedBox(height: 16),
          for (final entry in widget.sched.entries) schedule_entry_tile(entry)
        ]
      ),
    );
  }

}
