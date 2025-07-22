import 'package:flutter/material.dart';
import 'package:bakinglog/data.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LogPage extends StatefulWidget {
  const LogPage({required this.bakelog, this.isEdit = false, super.key});
  final BakeLog bakelog;
  final bool isEdit;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int count = 0;
  bool isEdit = true;
  TextEditingController textEditingController = TextEditingController();

  // 저장된 사진들의 경로를 저장할 리스트
  List<String> _savedImagePaths = [];

  // 사진을 여러 장 선택하고 바로 저장하는 메서드
  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      // 선택된 사진들을 바로 저장
      await _saveImages(images);
    }
  }

  // 사진을 로컬에 저장하는 메서드
  Future<void> _saveImages(List<XFile> images) async {
    if (images.isEmpty) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = path.join(appDir.path, 'baking_images');
    
    // 디렉토리가 없으면 생성
    await Directory(imagesDir).create(recursive: true);

    List<String> savedPaths = [];
    
    for (int i = 0; i < images.length; i++) {
      final String fileName = '${widget.bakelog.name}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final String filePath = path.join(imagesDir, fileName);
      
      // 파일 복사
      await images[i].saveTo(filePath);
      savedPaths.add(filePath);
    }

    setState(() {
      _savedImagePaths.addAll(savedPaths);
    });

    // BakeLog의 imageUrl에 경로들을 저장 (여러 사진은 쉼표로 구분)
    if (widget.bakelog.imageUrl.isEmpty) {
      widget.bakelog.imageUrl = savedPaths.join(',');
    } else {
      widget.bakelog.imageUrl += ',${savedPaths.join(',')}';
    }
  }

  // 저장된 사진들을 불러오는 메서드
  void _loadSavedImages() {
    if (widget.bakelog.imageUrl.isNotEmpty) {
      _savedImagePaths = widget.bakelog.imageUrl.split(',').where((path) => path.isNotEmpty).toList();
    }
  }

  // 사진을 삭제하는 메서드
  Future<void> _deleteImage(int index) async {
    if (index >= 0 && index < _savedImagePaths.length) {
      final String imagePath = _savedImagePaths[index];
      
      try {
        // 로컬 파일 삭제
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        
        // UI에서 제거
        setState(() {
          _savedImagePaths.removeAt(index);
          widget.bakelog.imageUrl = _savedImagePaths.join(',');
        });
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }

  void _addCount() {
    setState(() {
      count++;
    });
  }

  @override
  void initState() {
    super.initState();
    isEdit = widget.isEdit;
    textEditingController.text = widget.bakelog.name;
    _loadSavedImages();
  }

  void turnEditMode() {
    setState(() {
      isEdit = !isEdit;
      print("turnEditMode $isEdit");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: isEdit ? const Icon(Icons.done) : const Icon(Icons.edit),
            onPressed: () {
              turnEditMode();
            },
          ),
        ],
        title: isEdit
            ? TextField(
                controller: textEditingController,
                onChanged: (value) {
                  widget.bakelog.name = value;
                },
              )
            : Text(widget.bakelog.name.toString()),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Text(widget.bakelog.date.toString()),
            ),
            Text(
              '  Score ${widget.bakelog.score}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const Divider(),
            Text(
              '  Note',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: BakeLogNote(
                bakeLog: widget.bakelog,
                isEdit: isEdit,
              ),
            ),
            const Divider(),
            // 사진 선택 및 표시 UI
            SizedBox(height: 10),
            Row(
              children: [
                if (isEdit) ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.photo_library),
                  label: Text('사진 선택'),
                ),
              ],
            ),
            SizedBox(height: 10),
            // 저장된 사진들 표시
            if (_savedImagePaths.isNotEmpty) ...[
              Text('저장된 사진들:'),
              SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedImagePaths.length,
                  separatorBuilder: (context, index) => SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Image.file(
                          File(_savedImagePaths[index]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        if (isEdit)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                _deleteImage(index);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (_savedImagePaths.isEmpty)
              Text('저장된 사진이 없습니다'),
          ],
        ),
      ),
    );
  }
}

class BakeLogNote extends StatefulWidget {
  BakeLogNote({required this.bakeLog, required this.isEdit})
      : super(key: ObjectKey(bakeLog));

  final BakeLog bakeLog;
  final bool isEdit;

  @override
  _BakeLogNoteState createState() => _BakeLogNoteState();
}

class _BakeLogNoteState extends State<BakeLogNote> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.bakeLog.note;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEdit
        ? Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    width: 2.0)),
            child: TextField(
                controller: textEditingController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  //todo check performance
                  widget.bakeLog.note = value;
                }))
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(0),
            itemCount: 1,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                  alignment: Alignment.centerLeft,
                  //height: 30,
                  child: Text(widget.bakeLog.note));
            },
          );
  }
}
