import 'dart:convert' show HtmlEscape;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

HtmlEscape sanitizer = const HtmlEscape();


class DateField extends StatefulWidget {
  const DateField({super.key, required this.dateController, required this.onSave, required this.onChanged});

  final TextEditingController dateController;
  final FormFieldSetter<String> onSave;
  final VoidCallback onChanged;

  @override
  State<StatefulWidget> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  final DateTime _currentDate = DateTime.now();
  final TextInputFormatter _dateInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      locale: const Locale.fromSubtags(languageCode: 'fr'),
      initialDate: _currentDate,
      firstDate: DateTime.utc(2025),
      lastDate: DateTime.utc(2100),
    );
    if (pickedDate != null) {
      String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      setState(() {
        widget.dateController.text = formattedDate;
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () { _pickDate(context); },
          icon: const Icon(Icons.calendar_month)
        ),
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextFormField(
              controller: widget.dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'DD/MM/YYYY',
                hintStyle: TextStyle(color: Colors.grey)
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.datetime,
              maxLength: 10,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textAlign: TextAlign.center,
              inputFormatters: [
                _dateInputFormatter,
                LengthLimitingTextInputFormatter(10)
              ],
              onChanged: (value) {
                widget.onChanged();
              },
              validator: (value) {
                const String errorSentence = 'Format JJ/MM/AAAA attendu';
                if (value == null) return errorSentence;
                value = sanitizer.convert(value.trim()).replaceAll('&#47;', '/');
                String formattedValue = value.replaceAllMapped(RegExp(r"([0-9]{2})/([0-9]{2})/([0-9]{4})"), (m) => '${m[3]}-${m[2]}-${m[1]}');
                final dateValidator = DateTime.tryParse(formattedValue);
                if (value.isEmpty || value.length != 10 || dateValidator == null || dateValidator.year < 1900 || dateValidator.year > 2100) {
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