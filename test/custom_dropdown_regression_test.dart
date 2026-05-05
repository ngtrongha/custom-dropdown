import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomDropdown regressions', () {
    testWidgets(
      'searchRequest allows selecting remote result when items is null',
      (tester) async {
        String? selectedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomDropdown<String>.searchRequest(
                items: null,
                futureRequest: (query) async {
                  await Future<void>.delayed(
                    const Duration(milliseconds: 10),
                  );
                  return <String>['Remote item'];
                },
                onChanged: (value) {
                  selectedValue = value;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'remote');
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pumpAndSettle();

        expect(find.text('Remote item'), findsWidgets);
        await tester.tap(find.text('Remote item').first);
        await tester.pumpAndSettle();

        expect(selectedValue, 'Remote item');
      },
    );

    testWidgets(
      'switching controller detaches old controller updates',
      (tester) async {
        final oldController = SingleSelectController<String>('Old');
        final newController = SingleSelectController<String>('New');
        final hostKey = GlobalKey<_ControllerSwapHostState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _ControllerSwapHost(
                key: hostKey,
                oldController: oldController,
                newController: newController,
              ),
            ),
          ),
        );

        expect(find.text('Old'), findsOneWidget);

        hostKey.currentState!.swap();
        await tester.pumpAndSettle();
        expect(find.text('New'), findsOneWidget);

        oldController.value = 'Legacy value';
        await tester.pumpAndSettle();

        expect(find.text('Legacy value'), findsNothing);
        expect(find.text('New'), findsOneWidget);
      },
    );
  });
}

class _ControllerSwapHost extends StatefulWidget {
  const _ControllerSwapHost({
    super.key,
    required this.oldController,
    required this.newController,
  });

  final SingleSelectController<String> oldController;
  final SingleSelectController<String> newController;

  @override
  State<_ControllerSwapHost> createState() => _ControllerSwapHostState();
}

class _ControllerSwapHostState extends State<_ControllerSwapHost> {
  late SingleSelectController<String> activeController;

  @override
  void initState() {
    super.initState();
    activeController = widget.oldController;
  }

  void swap() {
    setState(() {
      activeController = widget.newController;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      items: <AnimationDropDownItem<String>>[
        AnimationDropDownItem<String>(value: 'Old'),
        AnimationDropDownItem<String>(value: 'New'),
      ],
      controller: activeController,
      onChanged: (_) {},
    );
  }
}
