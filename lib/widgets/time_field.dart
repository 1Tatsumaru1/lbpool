import 'dart:convert' show HtmlEscape;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

HtmlEscape sanitizer = const HtmlEscape();


class TimeField extends StatefulWidget {
  const TimeField({super.key, required this.timeController, required this.onSave, required this.onChanged});

  final TextEditingController timeController;
  final FormFieldSetter<String> onSave;
  final VoidCallback onChanged;

  @override
  State<StatefulWidget> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  final TimeOfDay _currentTime = TimeOfDay.now();
  final TextInputFormatter _timeInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'));

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickTime(context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _currentTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Forcer le format 24h
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      setState(() {
        widget.timeController.text = formattedTime;
      });
      widget.onChanged();
    }
  }

  TimeOfDay? tryParseTimeOfDay(String timeString) {
    final RegExp timeRegExp = RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$');
    if (timeRegExp.hasMatch(timeString)) {
      final parts = timeString.split(':');
      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      try {
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () { _pickTime(context); },
          icon: const Icon(Icons.watch_later_outlined)
        ),
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextFormField(
              controller: widget.timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'HH:MM',
                hintStyle: TextStyle(color: Colors.grey)
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.datetime,
              maxLength: 5,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textAlign: TextAlign.center,
              inputFormatters: [
                _timeInputFormatter,
                LengthLimitingTextInputFormatter(5)
              ],
              onChanged: (value) {
                widget.onChanged();
              },
              validator: (value) {
                const String errorSentence = "Format HH:MM attendu";
                if (value == null) return errorSentence;
                value = sanitizer.convert(value.trim());
                final timeValidator = tryParseTimeOfDay(value);
                if (value.isEmpty || value.length != 5 || timeValidator == null) {
                  return errorSentence;
                }
                return null;
              },
              onSaved: (value) => widget.onSave(value),
            ),
          ),
        ),
      ],
    );
  }
}