import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Floating App Bar';

    return MaterialApp(
      title: title,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text(title),
              pinned: true,
              flexibleSpace: Placeholder(),
              expandedHeight: 200,
            ),
            SliverList.builder(
              // The builder function returns a ListTile with a title that
              // displays the index of the current item.
              itemBuilder: (context, index) =>
                  ListTile(title: Text('Item #$index')),
              // Builds 50 ListTiles
              itemCount: 50,
            ),
          ],
        ),
      ),
    );
  }
}
