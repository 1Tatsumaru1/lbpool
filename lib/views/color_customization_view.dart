import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ColorCustomizationView extends StatefulWidget {
  const ColorCustomizationView({super.key});

  @override
  State<ColorCustomizationView> createState() => _ColorCustomizationViewState();
}

class _ColorCustomizationViewState extends State<ColorCustomizationView> {
  static const Color _defaultColor = Color.fromARGB(255, 3, 100, 255);
  Color _selectedColor = _defaultColor;
  late ColorScheme _colorScheme;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _colorScheme = ColorScheme.fromSeed(seedColor: _selectedColor);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _selectedColor = await _loadColor();
      setState(() {
        _colorScheme = ColorScheme.fromSeed(seedColor: _selectedColor);
      });
    });
  }

  Future<Color> _loadColor() async {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? savedColorValue = await secureStorage.read(key: 'customColorSeed');
    if (savedColorValue == null) {
      return const Color.fromARGB(255, 3, 100, 255);
    }
    return Color(int.parse(savedColorValue));
  }

  Future<void> _saveColor(BuildContext context) async {
    await _secureStorage.write(key: 'customColorSeed', value: _selectedColor.toARGB32().toString());
    if (context.mounted) Navigator.of(context).pop();
  }

  void _openColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color newColor) {
                setState(() {
                  _selectedColor = newColor;
                  _colorScheme = ColorScheme.fromSeed(seedColor: _selectedColor);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.inversePrimary)
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _resetToDefault() {
    setState(() {
      _selectedColor = _defaultColor;
      _colorScheme = ColorScheme.fromSeed(seedColor: _selectedColor);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customization'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          // 1st level : Top screen buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                // Restore default
                ElevatedButton.icon(
                  onPressed: _selectedColor == _defaultColor ? null : _resetToDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor == _defaultColor ? Colors.grey[50] : Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: _selectedColor == _defaultColor ? Colors.white : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  label: const Text("Default color"),
                  icon: const Icon(Icons.arrow_circle_left),
                ),

                ElevatedButton.icon(
                  onPressed: () { _openColorPicker(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  label: const Text("Palette"),
                  icon: const Icon(Icons.palette),
                ),
              ],
            ),
          ),

          // 2nd level : Simulation
          const SizedBox(height: 20,),
          const Text('Sample display'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _colorScheme.inversePrimary),
                borderRadius: const BorderRadius.all(Radius.circular(15))
              ),
              child: Column(
                children: [
                  Container(
                    color: _colorScheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back),
                        const SizedBox(width: 20,),
                        Text('Sample screen', style: TextStyle(fontSize: 20, color: _colorScheme.onSecondaryContainer),)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: _colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.place),
                        title: const Text('Element'),
                        subtitle: const Text('Details'),
                        textColor: _colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: null,
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(_colorScheme.primaryContainer),
                            foregroundColor: WidgetStatePropertyAll(_colorScheme.onPrimaryContainer),
                            elevation: const WidgetStatePropertyAll(4)
                          ),
                          label: const Text('Action'),
                          icon: const Icon(Icons.check),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const Text(
            'Color change will be effective on the next app restart',
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),

      // 3rd level : Validation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _saveColor(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        label: const Text('Submit'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}