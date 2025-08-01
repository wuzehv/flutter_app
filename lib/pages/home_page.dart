import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jenkins_app/pages/jenkins_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _addJenkinsConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return JenkinsConfig();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Jenkins App"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.dashboard, color: Colors.white), //自定义图标
              onPressed: () {},
            );
          },
        ),
      ),
      body: SafeArea(
        // child: ListView(
        //   shrinkWrap: true,
        //   padding: const EdgeInsets.all(20.0),
        //   children: <Widget>[
        //     ListTile(
        //       title: Text("accdadfadsf"),
        //       subtitle: Text('adfasdfsdf'),
        //       trailing: const Icon(Icons.chevron_right),
        //       onTap: null,
        //     ),
        //   ],
        // ),
        child: Slidable(
          // Specify a key if the Slidable is dismissible.
          key: const ValueKey(0),

          // The start action pane is the one at the left or the top side.
          startActionPane: ActionPane(
            // A motion is a widget used to control how the pane animates.
            motion: const ScrollMotion(),

            // A pane can dismiss the Slidable.
            dismissible: DismissiblePane(onDismissed: () {}),

            // All actions are defined in the children parameter.
            children: const [
              // A SlidableAction can have an icon and/or a label.
              SlidableAction(
                onPressed: null,
                backgroundColor: Color(0xFFFE4A49),
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
              SlidableAction(
                onPressed: null,
                backgroundColor: Color(0xFF21B7CA),
                foregroundColor: Colors.white,
                icon: Icons.share,
                label: 'Share',
              ),
            ],
          ),

          // The end action pane is the one at the right or the bottom side.
          endActionPane: const ActionPane(
            motion: ScrollMotion(),
            children: [
              SlidableAction(
                // An action can be bigger than the others.
                flex: 2,
                onPressed: null,
                backgroundColor: Color(0xFF7BC043),
                foregroundColor: Colors.white,
                icon: Icons.archive,
                label: 'Archive',
              ),
              SlidableAction(
                onPressed: null,
                backgroundColor: Color(0xFF0392CF),
                foregroundColor: Colors.white,
                icon: Icons.save,
                label: 'Save',
              ),
            ],
          ),

          // The child of the Slidable is what the user sees when the
          // component is not dragged.
          child: const ListTile(title: Text('Slide me')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addJenkinsConfig,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
