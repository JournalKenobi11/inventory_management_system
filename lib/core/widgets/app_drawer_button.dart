import 'package:flutter/material.dart';

/// A standard Material hamburger button (☰) that opens the existing sidebar Drawer.
class AppDrawerButton extends StatelessWidget {
  const AppDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        ScaffoldState? target;
        context.visitAncestorElements((element) {
          if (element is StatefulElement && element.state is ScaffoldState) {
            final scaffold = element.state as ScaffoldState;
            if (scaffold.hasDrawer) {
              target = scaffold;
              return false;
            }
          }
          return true;
        });

        if (target != null) {
          target!.openDrawer();
        } else {
          Scaffold.maybeOf(context)?.openDrawer();
        }
      },
    );
  }
}

/// Returns an [AppDrawerButton] if the current route cannot be popped,
/// or `null` if the route can be popped (allowing the [AppBar] to automatically
/// display the standard back button).
Widget? appDrawerLeading(BuildContext context) {
  if (ModalRoute.of(context)?.canPop ?? false) {
    return null;
  }
  return const AppDrawerButton();
}
