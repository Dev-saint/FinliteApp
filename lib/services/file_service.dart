import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';

class FileService {
  static Directory? _attachmentsDir;

  /// Получить/создать папку для вложений рядом с БД
  static Future<Directory> getAttachmentsDir() async {
    if (_attachmentsDir != null) return _attachmentsDir!;
    final dbDir = await getDatabasesPath();
    final attachmentsPath = p.join(dbDir, 'attachments');
    final dir = Directory(attachmentsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _attachmentsDir = dir;
    return dir;
  }

  /// Скопировать файл в папку вложений, вернуть новый путь
  static Future<String> copyToAttachments(File file) async {
    final dir = await getAttachmentsDir();
    final fileName = p.basename(file.path);
    final newPath = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    return (await file.copy(newPath)).path;
  }

  /// Удалить файл по пути
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Сохранить файл в выбранное пользователем место
  static Future<void> saveFileTo(String sourcePath, String destPath) async {
    final src = File(sourcePath);
    await src.copy(destPath);
  }

  /// Проверить, является ли файл изображением
  static bool isImage(String path) {
    final mime = lookupMimeType(path);
    return mime != null && mime.startsWith('image/');
  }

  /// Сохранить файл с выбором пути и имени через стандартный диалог
  static Future<void> saveFileWithDialog(
    String sourcePath,
    String defaultName,
  ) async {
    try {
      // Получаем расширение файла из исходного имени
      final extension = p.extension(defaultName);
      final nameWithoutExt = p.basenameWithoutExtension(defaultName);

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл',
        fileName: defaultName,
        type: FileType.any,
        allowedExtensions: [
          extension.replaceAll('.', ''),
        ], // Убираем точку из расширения
      );

      if (savePath != null) {
        final src = File(sourcePath);
        await src.copy(savePath);
      }
    } catch (e) {
      print('Ошибка при сохранении файла: $e');
      rethrow;
    }
  }
}
