import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';
import 'theme_data.dart';
import 'schedule.dart';

class DoserPage extends StatefulWidget {
  final DoserDevice device;
  final Ble_manager blemanager;
  final Theme_data theme = const Theme_data();

  const DoserPage({
    super.key,
    required this.device,
    required this.blemanager,
  });

  @override
  State<DoserPage> createState() => _DoserPageState();
}


class _DoserPageState extends State<DoserPage> {
  Schedule? dose_sched;
  bool? connected;
  bool direction = false;
  bool TEST_FLAG = true;
  final dose_controller = TextEditingController();
  final seconds_controller = TextEditingController();
  final insta_dose_amount_controller = TextEditingController();
  final actual_calibration_dose_controller = TextEditingController();
  bool save_success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        connect_device();
    });
  }

  @override
  void dispose() {
    dose_controller.dispose();
    seconds_controller.dispose();
    insta_dose_amount_controller.dispose();
    actual_calibration_dose_controller.dispose();
    super.dispose();
  }


  Future<void> connect_device() async {
    final result = await widget.blemanager.connect_to_device(widget.device);
    final newDir = await widget.blemanager.getDirection(widget.device);
    Schedule sched = await widget.blemanager.getSchedule(widget.device);

    if (!mounted || !result) return;

    setState(() {
        connected = result;
        direction = newDir;
        dose_sched = sched;
        dose_controller.text = sched.ml;
        seconds_controller.text = sched.period;
    });
  }


  Widget connection_status() {
    String text = "Disconnected";
    if (connected == null) {
      text = "Connecting...";
    } else if (connected!) {
      text = "Connected";
    }

    return widget.theme.small_text_bold(text);
  }


  void direction_changed(dir){
    setState(() {
        direction = dir;
    });
    widget.blemanager.setDirection(widget.device, dir);
  }


  Widget manual_dosing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: TextField(
            controller: insta_dose_amount_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),
        const Text("ml"),
        SizedBox(width: 50),
        FilledButton(
          onPressed: (){
            widget.blemanager.manual_dose(widget.device, insta_dose_amount_controller.text);
          },
          child: const Text("Dose"),
        ),
      ]
    );


  }

  Widget calibration_dose() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        FilledButton(
          onPressed: (){widget.blemanager.manual_dose(widget.device, "10");},
          child: const Text("10 ml calibration dose"),
        ),
      ]
    );
  }

  Widget actual_calibration_amount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        Text("measured:"),
        SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: TextField(
            controller: actual_calibration_dose_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),
        Text("ml"),
        SizedBox(width: 20),
        FilledButton(
          onPressed: (){widget.blemanager.setAutocal(widget.device, actual_calibration_dose_controller.text);},
          child: const Text("Update Calibration"),
        ),
      ]
    );
  }

  Widget dose_sched_selector() {
    if(dose_sched?.type == ScheduleType.periodic){
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: TextField(
              controller: dose_controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: true,),
            ),
          ),

          const Text("ml every"),

          SizedBox(
            width: 100,
            child: TextField(
              controller: seconds_controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),

          const Text("seconds"),
        ],
      );
    } else{
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: dose_controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: true,),
            ),
          ),
          const Text("ml/min"),
        ]
      );
    }
  }

  Future<void> commit_changes() async {
    if(dose_sched == null) return;

    dose_sched!.ml = dose_controller.text;
    if(dose_sched!.type == ScheduleType.periodic){
      dose_sched!.period = seconds_controller.text;
    }

    await widget.blemanager.setSchedule(widget.device, dose_sched!);


    //flash button green
    setState(() {
        save_success = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
        save_success = false;
    });
  }

  Widget schedule_type_drop() {
    return DropdownButton<ScheduleType>(
      value: (dose_sched == null ? ScheduleType.periodic : dose_sched!.type),
      underline: const SizedBox(),
      items: const [ DropdownMenuItem(
          value: ScheduleType.periodic,
          child: Text("Periodic"),
        ),
        DropdownMenuItem(
          value: ScheduleType.continuous,
          child: Text("Continuous Dosing"),
        ),
      ],
      onChanged: (value) { if (value != null) { setState(() { dose_sched?.type = value; }); } },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard_visible = MediaQuery.of(context).viewInsets.bottom > 0;



    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: ListView(
        keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          device_hero(context),
          const SizedBox(height: 20), //padding
          if((connected != null && connected!) || TEST_FLAG) ...[
            section_header("Settings"),
            setting_row("Direction", Switch(value: direction, onChanged: (value)=>direction_changed(value)), 3, 7),
            setting_row("Schedule", schedule_type_drop(), 3, 7, bottom_padding: 0),
            setting_row(null, dose_sched_selector(), 1, 9, top_padding: 0),
            section_header("Tools"),
            setting_row("Manual Dosing", manual_dosing(), 5, 5),
            setting_row("Calibration", calibration_dose(), 4, 6, bottom_padding: 0),
            setting_row(null, actual_calibration_amount(), 5, 5, top_padding: 0),

          ]
          else if(connected == null) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
          ]
        ],
      ),

      floatingActionButton: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          begin: Theme.of(context).colorScheme.primary,
          end: save_success ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, color, child) {
          final text_color =
          save_success ? Colors.white : Theme.of(context).colorScheme.onPrimary;

          return keyboard_visible
          ? FloatingActionButton(
            onPressed: commit_changes,
            backgroundColor: color,
            child: Icon(Icons.save, color: text_color),
          )
          : FloatingActionButton.extended(
            onPressed: commit_changes,
            backgroundColor: color,
            label: Text(
              "Save changes",
              style: TextStyle(color: text_color),
            ),
            icon: Icon(Icons.save, color: text_color),
          );
        },
      ),
    );
  }


  IconButton edit_name_button() {
    return IconButton(
      onPressed: () {
        // TODO: Open rename dialog
      },
      icon: const Icon(Icons.edit_outlined),
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }

  Expanded info_col() {
    return Expanded(
      flex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.theme.title_text(widget.device.name),
              const SizedBox(width: 2),
              edit_name_button(),
            ],
          ),
          const SizedBox(height: 8),
          widget.theme.small_text(widget.device.uuid),
          const SizedBox(height: 12),
          connection_status(),
        ],
      ),
    );
  }


  Expanded icon_col(){
    return Expanded(
      flex: 4,
      child: Center(
        child: SizedBox(
          width: 90,
          height: 90,
          child: Image.asset(
            'assets/doser_clipaart.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  //this has GOT to be factored down. This language is hell
  Widget device_hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 5,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          icon_col(),
          info_col(),
        ],
      ),
    );
  }

  Widget section_header(String text) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 20,
        bottom: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget setting_row(String? name, Widget? setting, int width1, int width2, {double top_padding = 14, double bottom_padding = 14}){
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: top_padding,
        bottom: bottom_padding,
      ),
      child: Row(
        children: [
          if (name != null)
          Expanded(
            flex: width1,
            child: widget.theme.subtitle_text(name),
          ),
          if (setting != null)
          Expanded(
            flex: width2,
            child: Align(
              alignment: Alignment.centerRight,
              child: setting,
            ),
          ),
        ],
      ),
    );
  }

//  Widget setting_row(String name, Widget setting, int width1, int width2){
//    return Padding(
//      padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 14,),
//      child: Row(
//        children: [
//          Expanded( flex: width1, child: widget.theme.subtitle_text(name),),
//          Expanded(
//            flex: width2,
//            child: Align( alignment: Alignment.centerRight, child: setting,),
//          ),
//        ],
//      ),
//    );
//  }
//
}
