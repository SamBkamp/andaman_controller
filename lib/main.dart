import 'device.dart';
import 'new_device_popup.dart';
import 'package:flutter/material.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final registry = DeviceRegistry();
  await registry.load();
  runApp(MainApp(registry: registry));
}

//root widget
class MainApp extends StatelessWidget {
  final DeviceRegistry registry;

  const MainApp({
    super.key,
    required this.registry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MenuWidget(registry: registry),
    );
  }
}



class generic_button_creator extends StatelessWidget {
  final String label;
  final VoidCallback on_pressed;

  const generic_button_creator({
      super.key,
      required this.label,
      required this.on_pressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: on_pressed,
      label: Text(label),
    );
  }

}


class MenuWidget extends StatefulWidget {
  final DeviceRegistry registry;

  const MenuWidget({
      super.key,
      required this.registry,
  });

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}


//main menu
class _MenuWidgetState extends State<MenuWidget> {

  //turns that class into a function - glue code
  void newDevicePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return NewDevicePopup(
          registry: widget.registry,
        );
      },
    );
  }

  SliverAppBar menu_bar(){
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      title: Text('Your Devices'),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                generic_button_creator(
                  label: "+",
                  on_pressed: () => newDevicePopup(context),
                ),
              ],
            ),
          ),
        ),//center end
      ),//flexible space bar end
      expandedHeight: 150,
    );    
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          menu_bar(),
          SliverList.builder(
            itemBuilder: (context, index) => ListTile(
              title: Text(widget.registry.device_by_index(index).name),
              subtitle: Text(widget.registry.device_by_index(index).uuid),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  widget.registry.delete(widget.registry.device_by_index(index));
                }              
              ),
            ),
            itemCount: widget.registry.total_devices(),
          ),
        ],
      ),
    );

  }

  @override
  void initState() {
    super.initState();
    widget.registry.addListener(_registry_changed);
  }

  void _registry_changed() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.registry.removeListener(_registry_changed);
    super.dispose();
  }


}
