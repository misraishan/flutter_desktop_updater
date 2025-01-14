import "package:desktop_updater_example/card.dart";
import "package:flutter/material.dart";

class DesktopUpdateWidget extends StatefulWidget {
  const DesktopUpdateWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DesktopUpdateWidget> createState() => _DesktopUpdateWidgetState();
}

class _DesktopUpdateWidgetState extends State<DesktopUpdateWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          const SliverAppBar.medium(
            expandedHeight: 256,
            collapsedHeight: 92,
            pinned: false,
            flexibleSpace: Padding(
              padding: EdgeInsets.only(top: 16),
              child: UpdateCard(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(
                  height: 16,
                ),
                Center(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
