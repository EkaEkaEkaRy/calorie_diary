import 'package:calorie_diary/database/db_helper.dart';
import 'package:calorie_diary/pages/barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fuzzy/fuzzy.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime date;
  final Map<String, dynamic>? event;
  final String? initialType;

  const EventFormScreen(
      {super.key, required this.date, this.event, this.initialType});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _dbTypes = [
    'Завтрак',
    'Перекус 1',
    'Обед',
    'Перекус 2',
    'Ужин',
    'Перекус 3',
  ];

  final Map<String, String> _displayNames = {
    'Завтрак': 'Завтрак',
    'Перекус 1': 'Перекус',
    'Обед': 'Обед',
    'Перекус 2': 'Перекус',
    'Ужин': 'Ужин',
    'Перекус 3': 'Перекус',
  };

  late String _selectedType;
  String? _text;
  String _weightInGrams = '';
  String _energyValue = '';
  File? _imageFile;
  int _count = 1;
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _energyController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _textSuggestions = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.event != null
        ? widget.event!['type']
        : (widget.initialType ?? _dbTypes[0]);
    _text = widget.event != null
        ? widget.event!['foodName'] ?? widget.event!['text']
        : '';

    _weightInGrams =
        widget.event != null && widget.event!['weightOrCount'] != null
            ? widget.event!['weightOrCount'].toString()
            : '';

    _energyValue = widget.event != null && widget.event!['energyValue'] != null
        ? widget.event!['energyValue'].toString()
        : '';

    _count = widget.event != null && widget.event!['count'] != null
        ? (widget.event!['count'] as num).toInt()
        : 1;

    _countController.text = '$_count';
    _weightController.text = _weightInGrams;
    _energyController.text = _energyValue;
    _textController.text = _text != null ? _text! : '';

    if (widget.event != null && widget.event!['imagePath'] != null) {
      _imageFile = File(widget.event!['imagePath']);
    }

    _loadTextSuggestions();
  }

  int countCommonWords(String query, String text) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final textWords = text.toLowerCase().split(RegExp(r'\s+'));
    int count = 0;

    for (var qw in queryWords) {
      if (textWords.any((tw) => tw.contains(qw))) {
        count++;
      }
    }
    return count;
  }

  int countAdjacentMatches(String query, String text) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final textWords = text.toLowerCase().split(RegExp(r'\s+'));
    int adjCount = 0;

    for (int i = 0; i < queryWords.length - 1; i++) {
      final pair = '${queryWords[i]} ${queryWords[i + 1]}';
      for (int j = 0; j < textWords.length - 1; j++) {
        final textPair = '${textWords[j]} ${textWords[j + 1]}';
        if (textPair.contains(pair)) {
          adjCount++;
        }
      }
    }
    return adjCount;
  }

  Iterable<Map<String, dynamic>> fuzzySearch(
    List<Map<String, dynamic>> events,
    String query,
  ) {
    if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();

    final texts = events.map((e) => e['name'].toString()).toList();

    final fuse = Fuzzy(
      texts,
      options: FuzzyOptions(
        tokenize: true,
        findAllMatches: true,
        threshold: 0.5,
      ),
    );

    final results = fuse.search(query);

    final scoredResults = results.map((r) {
      final text = r.item;
      final score = r.score;
      final event = events.firstWhere((e) => e['name'].toString() == text);

      final commonWords = countCommonWords(query, text);
      final adjacentMatches = countAdjacentMatches(query, text);

      // Вычисляем итоговый рейтинг с учётом fuzzy score, количества общих слов и длинны соседних совпадений
      // Можно экспериментировать с коэффициентами
      final combinedScore = score - 0.1 * commonWords - 0.2 * adjacentMatches;

      return {'event': event, 'score': combinedScore};
    }).toList();

    // Сортируем по возрастанию оценки — чем меньше, тем лучше совпадение
    scoredResults.sort((a, b) {
      final aScore = a['score'] as double? ?? double.maxFinite;
      final bScore = b['score'] as double? ?? double.maxFinite;
      return aScore.compareTo(bScore);
    });

    return scoredResults
        .map<Map<String, dynamic>>((e) => e['event'] as Map<String, dynamic>);
  }

  Future<void> _loadTextSuggestions([String filter = '']) async {
    final query = filter.trim().toLowerCase();

    // Получаем записи из БД, отфильтрованные по подстроке
    final allEvents =
        await DatabaseHelper.instance.getFindUniqueTexts(textQuery: query);

    setState(() {
      _textSuggestions = allEvents.toList();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800);
      if (pickedFile != null) {
        final savedFile = await _saveFileLocally(File(pickedFile.path));
        setState(() {
          _imageFile = savedFile;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  Future<File> _saveFileLocally(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(file.path);
    final savedPath = p.join(appDir.path, 'images');
    final savedDir = Directory(savedPath);
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }
    final savedFile = await file.copy(p.join(savedPath, fileName));
    return savedFile;
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Выбрать из галереи'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Сделать фото'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  bool containsAnySubstring(String text) {
    final List<String> alcoholicDrinks = [
      'Вино',
      'Пиво',
      'Водка',
      'Шампанское',
      'Ром',
      'Виски',
      'Джин',
      'Текила',
      'Коньяк',
      'Ликёр',
      'Абсент',
      'Портвейн',
      'Бренди',
      'Медовуха',
      'Сидр'
    ];

    return alcoholicDrinks.any((word) => text.contains(word));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final dateString = DateFormat('yyyy-MM-dd').format(widget.date);

    if (widget.event == null) {
      final row = {
        'date': dateString,
        'type': _selectedType,
        'text': _text,
        'food_id': null,
        'weightOrCount':
            _weightInGrams.isNotEmpty ? double.tryParse(_weightInGrams) : null,
        'energyValue':
            _energyValue.isNotEmpty ? double.tryParse(_energyValue) : null,
        'imagePath': _imageFile?.path ??
            (widget.event != null ? widget.event!['imagePath'] : null),
        'count': _count.toDouble(),
      };

      await DatabaseHelper.instance.insertEvent(row);
    } else {
      final row = {
        'date': dateString,
        'type': _selectedType,
        'text': _text,
        'food_id': widget.event!['food_id'],
        'weightOrCount':
            _weightInGrams.isNotEmpty ? double.tryParse(_weightInGrams) : null,
        'energyValue':
            _energyValue.isNotEmpty ? double.tryParse(_energyValue) : null,
        'imagePath': _imageFile?.path ??
            (widget.event != null ? widget.event!['imagePath'] : null),
        'count': _count.toDouble(),
      };

      await DatabaseHelper.instance.updateEvent(row, widget.event!['id']);
    }

    if (_text != null && containsAnySubstring(_text!)) {
      final db = await DatabaseHelper.instance.database;
      final row = {'date': dateString, 'type': 'Алкоголь', 'text': 'True'};
      await db.insert('events', row);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _energyController.dispose();
    _textController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat.yMMMMd('ru_RU').format(widget.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
            widget.event == null ? 'Новое событие' : 'Редактировать событие'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Дата: $dateFormatted', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              DropdownButtonFormField2<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Тип',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  maxHeight: 150,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
                items: _dbTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(_displayNames[type]!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Выберите тип' : null,
              ),
              SizedBox(height: 16),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  _text = textEditingValue.text;
                  _textController.text = textEditingValue.text;
                  return fuzzySearch(_textSuggestions, textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'].toString(),
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  // Инициализируем контроллер начальными данными (если нужно)
                  controller.text = _text ?? '';
                  controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length));
                  controller.addListener(() {
                    _textController.text = controller.text;
                    _textController.selection = controller.selection;
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Текст',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF4CAF50), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      // ИКОНКА СКАНИРОВАНИЯ ШТРИХКОДА В КОНЦЕ ПОЛЯ ВВОДА
                      suffixIcon: IconButton(
                        icon:
                            const Icon(Icons.qr_code, color: Color(0xFF4CAF50)),
                        onPressed: () async {
                          // Открываем созданный ранее экран сканера

                          final Map<String, dynamic>? productMap =
                              await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BarcodeScannerPage(),
                            ),
                          );

                          if (productMap != null) {
                            setState(() {
                              _weightInGrams = productMap['weight'].toString();
                              _energyValue = productMap['calories'].toString();
                              _text = productMap['name'].toString();

                              controller.text = _text ?? '';
                              _weightController.text = _weightInGrams;
                              _energyController.text = _energyValue;
                            });
                          }
                        },
                      ),
                    ),
                    minLines: 1,
                    maxLines: 10,
                    onSaved: (value) => {
                      _text = value?.trim(),
                      controller.text = _text != null ? _text! : ''
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                child: Text(option['name'].toString()),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (selectedEvent) async {
                  setState(() {
                    _weightInGrams = selectedEvent['weight']?.toString() ?? '';
                    _energyValue = selectedEvent['calories']?.toString() ?? '';
                    _text = selectedEvent['name'];

                    _weightController.text = _weightInGrams;
                    _energyController.text = _energyValue;
                  });
                },
              ),

              SizedBox(height: 16),
              /*
              // Поле веса в граммах
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                    labelText: 'Вес (граммы)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF4CAF50))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF4CAF50), width: 2)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) => _weightInGrams = value!.trim(),
              ),
              SizedBox(height: 16),
              */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Поле веса в граммах
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.47,
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                          labelText: 'Вес (граммы)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF4CAF50))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF4CAF50), width: 2)),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14)),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onSaved: (value) => _weightInGrams = value!.trim(),
                    ),
                  ),
                  // Поле для count (количество)
                  // Кнопка уменьшения значения
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Color(0xFF4CAF50)),
                    onPressed: () {
                      setState(() {
                        if (_count > 1) {
                          _count--;
                          _countController.text = '$_count';
                        }
                      });
                    },
                  ),

                  // Поле ввода числа
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.17,
                    child: TextFormField(
                      controller: _countController,
                      decoration: InputDecoration(
                        labelText: 'Кол-во',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF4CAF50)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          _count = parsed;
                          // Обновить контроллер не нужно, т.к. он уже обновлен из ввода
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите количество';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Введите корректное целое число > 0';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        final parsed = int.tryParse(value ?? '');
                        _count = (parsed != null && parsed > 0) ? parsed : 1;
                      },
                    ),
                  ),

                  // Кнопка увеличения значения
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: Color(0xFF4CAF50)),
                    onPressed: () {
                      setState(() {
                        _count++;
                        _countController.text = '$_count';
                      });
                    },
                  ),
                ],
              ),

              SizedBox(height: 16),
              // Энергетическая ценность на 100г
              TextFormField(
                controller: _energyController,
                decoration: InputDecoration(
                    labelText: 'Энергетическая ценность на 100г (ккал)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF4CAF50))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF4CAF50), width: 2)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) => _energyValue = value!.trim(),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showImageSourceActionSheet,
                icon: Icon(
                  Icons.image,
                  color: Colors.white,
                ),
                label: Text(
                    _imageFile == null
                        ? 'Добавить картинку'
                        : 'Изменить картинку',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              SizedBox(height: 16),
              if (_imageFile != null)
                Card(
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Stack(
                    children: [
                      Image.file(
                        _imageFile!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Color(0xFF4CAF50))),
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text('Сохранить',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
